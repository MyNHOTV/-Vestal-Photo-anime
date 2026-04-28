import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quick_base/core/services/ads_service.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helpers.dart';

class InterstitialManager {
  final RemoteConfigService _remoteConfig;
  final AdService _adService;

  InterstitialAd? _interstitialAd;
  int _retryCount = 0;
  final int _maxRetry = 2;

  // Track the last time a global interstitial was SHOWN
  static DateTime? _lastInterShowTime;
  // Track clicks for inter_detail
  int _interDetailClickCount = 0;

  InterstitialManager(this._remoteConfig, this._adService);

  Future<void> loadAd({
    String? type,
    required VoidCallback onComplete,
    required BuildContext context,
    bool? useHighFloor,
  }) async {
    if (!await AdNetworkHelper.hasNetworkConnection()) return;

    if (!RemoteConfigService.shared.adsEnabled) {
      onComplete.call();
      debugPrint('⚠️ Ads disabled');
      return;
    }
    final bool attemptsHighFloor = type == 'inter_new' &&
        (useHighFloor ?? _remoteConfig.interNew2FloorEnabled);
    bool isEnabled;
    bool? forceHighFloor;
    switch (type) {
      case 'inter_style':
        isEnabled = _remoteConfig.interStyleEnabled;
        break;
      case 'inter_change':
        isEnabled = _remoteConfig.interChangeEnabled;
        break;
      case 'inter_processing':
        isEnabled = _remoteConfig.interProcessingEnabled;
        break;
      case 'inter_detail':
        isEnabled = _remoteConfig.interDetailEnabled;
        break;
      case 'inter_new':
        final normalEnabled = _remoteConfig.interNewEnabled;
        final highFloorEnabled = _remoteConfig.interNew2FloorEnabled;
        isEnabled = normalEnabled || highFloorEnabled;
        if (!normalEnabled && highFloorEnabled) {
          forceHighFloor = true;
        }
        break;

      default:
        isEnabled = _remoteConfig.adsEnabled;
    }
    if (!isEnabled) {
      onComplete.call();
      debugPrint('⚠️ Ads disabled');
      return;
    }
    // 1. Check conditions
    final now = DateTime.now();
    final intervalSeconds = _remoteConfig.interInterval;
    int difference = intervalSeconds; // Default to allow if first time
    if (_lastInterShowTime != null) {
      difference = now.difference(_lastInterShowTime!).inSeconds;
    }
    final bool isTimeEnough = difference >= intervalSeconds;

    if (type == 'inter_detail') {
      _interDetailClickCount++;
      final threshold = _remoteConfig.interDetailClickThreshold;
      final bool isClicksEnough = _interDetailClickCount >= threshold;

      // Show if EITHER time is enough OR clicks are enough
      if (!isTimeEnough && !isClicksEnough) {
        debugPrint(
            '⏳ inter_detail: Neither time ($difference/${intervalSeconds}s) nor clicks ($_interDetailClickCount/$threshold) met - Skip');
        onComplete.call();
        return;
      }
      // Reset if we are about to show
      _interDetailClickCount = 0;
    } else {
      // For other ads, only check time
      if (!isTimeEnough) {
        debugPrint(
            '⏳ Interstitial too soon ($difference/${intervalSeconds}s) - Skip ad');
        onComplete.call();
        return;
      }
    }
    String adUnitId;
    switch (type) {
      case 'inter_style':
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidInterStyle
            : _remoteConfig.iosInterStyle;
        break;
      case 'inter_change':
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidInterChange
            : _remoteConfig.iosInterChange;
        break;
      case 'inter_processing':
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidInterProcessing
            : _remoteConfig.iosInterProcessing;
        break;
      case 'inter_detail':
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidInterDetail
            : _remoteConfig.iosInterDetail;
        break;
      case 'inter_new':
        adUnitId = Platform.isAndroid
            ? (attemptsHighFloor
                ? _remoteConfig.androidInterNew2Floor
                : _remoteConfig.androidInterNew)
            : (attemptsHighFloor
                ? _remoteConfig.iosInterNew2Floor
                : _remoteConfig.iosInterNew);
        break;
      default:
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidInterNew
            : _remoteConfig.iosInterNew;
    }

    if (context.mounted) {
      await AdUIHelper.showLoadingDialog();
    }

    // Timeout tracking
    bool hasTimedOut = false;
    bool hasCompleted = false;

    // Create timeout future
    final timeoutFuture = Future.delayed(const Duration(seconds: 15), () {
      if (!hasCompleted) {
        hasTimedOut = true;
        debugPrint('⏰ Interstitial load timeout after 15s - Skipping');
        try {
          AnalyticsService.shared.logEvent(name: "${type}_timeout");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }

        // Clean up and complete
        if (context.mounted) {
          AdUIHelper.hideLoadingDialog();
        }
        onComplete.call();
      }
    });

    // Load ad with callback
    final adLoadFuture = InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (hasTimedOut) {
            // Timeout already happened, dispose the ad
            debugPrint('⚠️ Ad loaded after timeout - Disposing');
            ad.dispose();
            return;
          }

          hasCompleted = true;
          try {
            AnalyticsService.shared.logEvent(name: "${type}_load");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
          _interstitialAd = ad;
          _retryCount = 0;

          // ✅ Thêm onPaidEvent callback để track ad revenue
          _interstitialAd?.onPaidEvent =
              (ad, valueMicros, precision, currencyCode) {
            final revenue = valueMicros / 1000000.0;
            debugPrint(
              '💰 Interstitial Ad revenue: $revenue $currencyCode (Precision: $precision)',
            );
            AnalyticsService.shared.logAdRevenue(
              amount: revenue,
              currency: currencyCode,
              adNetwork: ad.responseInfo?.mediationAdapterClassName,
              adUnitId: ad.adUnitId,
              adPlacement: type,
              adType: 'Interstitial',
            );
          };

          onComplete.call();
          if (context.mounted) {
            AdUIHelper.hideLoadingDialog();
          }
          debugPrint('✅ Interstitial loaded');
        },
        onAdFailedToLoad: (error) async {
          if (hasTimedOut) {
            // Timeout already happened, do nothing
            debugPrint('⚠️ Ad failed after timeout - Ignoring');
            return;
          }

          hasCompleted = true;
          try {
            AnalyticsService.shared.logEvent(name: "${type}_fail");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
          _interstitialAd = null;
          _retryCount++;

          if (context.mounted) {
            AdUIHelper.hideLoadingDialog();
          }

          if (type == 'inter_new' && attemptsHighFloor) {
            if (_remoteConfig.interNewEnabled) {
              debugPrint(
                  '🔀 [inter_new] 2F failed, falling back to normal inter_new');

              // Cleanup state trước khi fallback (giống app_open)
              _retryCount = 0; // Reset retry count cho fallback

              if (context.mounted) {
                loadAd(
                  type: type,
                  onComplete: onComplete,
                  context: context,
                  useHighFloor: false, // Force normal ID
                );
              }
              return; // Early return để không chạy retry logic bên dưới
            }
          }

          AdRetryHelper.handleRetry(
            retryCount: _retryCount,
            maxRetry: _maxRetry,
            loader: () =>
                loadAd(type: type, onComplete: onComplete, context: context),
          );

          debugPrint('❌ Interstitial failed: ${error.message}');
        },
      ),
    );

    // Wait for either ad to load or timeout
    await Future.any([adLoadFuture, timeoutFuture]);
  }

  bool _isShowingAd = false;
  bool get isShowingAd => _isShowingAd;

  Future<void> showAd(String type, {VoidCallback? onComplete}) async {
    if (!_remoteConfig.adsEnabled) return;

    if (!await AdNetworkHelper.hasNetworkConnection()) {
      debugPrint('⚠️ Cannot show Interstitial — no internet');
      onComplete?.call();
      return;
    }

    bool isEnabled;
    bool? forceHighFloor;
    switch (type) {
      case 'inter_style':
        isEnabled = _remoteConfig.interStyleEnabled;
        break;
      case 'inter_change':
        isEnabled = _remoteConfig.interChangeEnabled;
        break;
      case 'inter_processing':
        isEnabled = _remoteConfig.interProcessingEnabled;
        break;
      case 'inter_detail':
        isEnabled = _remoteConfig.interDetailEnabled;
        break;
      case 'inter_new':
        final normalEnabled = _remoteConfig.interNewEnabled;
        final highFloorEnabled = _remoteConfig.interNew2FloorEnabled;
        isEnabled = normalEnabled || highFloorEnabled;
        if (!normalEnabled && highFloorEnabled) {
          forceHighFloor = true;
        }
        break;
      default:
        isEnabled = _remoteConfig.adsEnabled;
    }
    if (!isEnabled) {
      onComplete?.call();
      return;
    }

    if (_interstitialAd == null) {
      onComplete?.call();
      return;
    }

    _isShowingAd = true;

    bool isCompleted = false;
    void complete() {
      if (!isCompleted) {
        isCompleted = true;
        onComplete?.call();
      }
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        try {
          AnalyticsService.shared.logEvent(name: "${type}_imp");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }
        debugPrint('✅ Interstitial showed - triggering navigation');
        // Update last show time
        _lastInterShowTime = DateTime.now();
        // Set flag để không show resume ad nếu user tắt màn hình
        _adService.setResumedDuringAd(true);
        complete();
      },
      onAdClicked: (ad) {
        try {
          AnalyticsService.shared.logEvent(name: "${type}_click");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }
        // User clicked ad, set flag
        _adService.setResumedDuringAd(true);
      },
      onAdDismissedFullScreenContent: (ad) async {
        try {
          AnalyticsService.shared.logEvent(name: "${type}_dismiss");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }
        // Restore system UI
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        _adService.setResumedDuringAd(false);
        _adService.markAdJustClosed();
        complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        try {
          AnalyticsService.shared.logEvent(name: "${type}_fail");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }
        // Restore system UI
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        ad.dispose();
        _interstitialAd = null;
        _isShowingAd = false;
        _adService.setResumedDuringAd(false);
        _adService.markAdJustClosed();
        complete();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (_interstitialAd != null) {
          // Hide system UI for immersive experience
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          await _interstitialAd!.show();
        } else {
          debugPrint("⚠️ Interstitial ad is null, cannot show.");
          _isShowingAd = false;
          onComplete?.call();
        }
      } catch (e) {
        debugPrint("⚠️ Error showing ad: $e");
        _isShowingAd = false;
        onComplete?.call();
      }
    });
  }
}
