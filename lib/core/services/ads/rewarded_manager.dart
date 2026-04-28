import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quick_base/core/services/ads_service.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helpers.dart';

class RewardedManager {
  final RemoteConfigService _remoteConfig;
  final AdService _adService;

  RewardedAd? _rewardedAd;
  String? _currentType; // Track current ad type for analytics
  DateTime? _lastRewardedShown;
  int _retryCount = 0;
  final int _maxRetry = 2;

  RewardedManager(this._remoteConfig, this._adService);

  Future<void> loadAd({
    String? type,
    VoidCallback? onComplete,
    required BuildContext context,
    bool? useHighFloor,
  }) async {
    if (!_remoteConfig.adsEnabled) return;
    if (!await AdNetworkHelper.hasNetworkConnection()) return;
    final bool attemptsHighFloor = type == 'reward_quick_generate' &&
        (useHighFloor ?? _remoteConfig.rewardQuickGenerate2FloorEnabled);
    // Kiểm tra enabled cho từng loại
    bool isEnabled;
    bool? forceHighFloor;
    switch (type) {
      case 'reward_save_1':
        isEnabled = _remoteConfig.rewardSave1Enabled;
        break;
      case 'reward_share_1':
        isEnabled = _remoteConfig.rewardShare1Enabled;
        break;
      case 'reward_save_3':
        isEnabled = _remoteConfig.rewardSave3Enabled;
        break;
      case 'reward_share_3':
        isEnabled = _remoteConfig.rewardShare3Enabled;
        break;
      case 'reward_quick_generate':
        final normalEnabled = _remoteConfig.rewardQuickGenerateEnabled;
        final highFloorEnabled = _remoteConfig.rewardQuickGenerate2FloorEnabled;
        isEnabled = normalEnabled || highFloorEnabled;
        if (!normalEnabled && highFloorEnabled) {
          forceHighFloor = true;
        }
        break;
      default:
        isEnabled = _remoteConfig.adsEnabled;
    }
    if (!isEnabled) return;

    // Lấy Ad Unit ID cho từng loại
    String adUnitId;
    switch (type) {
      case 'reward_save_1':
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidRewardSave1
            : _remoteConfig.iosRewardSave1;
        break;
      case 'reward_share_1':
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidRewardShare1
            : _remoteConfig.iosRewardShare1;
        break;
      case 'reward_save_3':
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidRewardSave3
            : _remoteConfig.iosRewardSave3;
        break;
      case 'reward_share_3':
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidRewardShare3
            : _remoteConfig.iosRewardShare3;
        break;
      case 'reward_quick_generate':
        adUnitId = Platform.isAndroid
            ? (attemptsHighFloor
                ? _remoteConfig.androidRewardQuickGenerate2Floor
                : _remoteConfig.androidRewardQuickGenerate)
            : (attemptsHighFloor
                ? _remoteConfig.iosRewardQuickGenerate2Floor
                : _remoteConfig.iosRewardQuickGenerate);
        break;
      default:
        adUnitId = Platform.isAndroid
            ? _remoteConfig.androidRewardSave1
            : _remoteConfig.iosRewardSave1;
    }

    if (context.mounted) {
      await AdUIHelper.showLoadingDialog();
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          try {
            AnalyticsService.shared.logEvent(name: "${type}_load");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
          _rewardedAd = ad;
          _currentType = type; // Save type
          _retryCount = 0;
          // ✅ Thêm onPaidEvent callback để track ad revenue
          _rewardedAd?.onPaidEvent =
              (ad, valueMicros, precision, currencyCode) {
            final revenue = valueMicros / 1000000.0;
            debugPrint(
              '💰 Rewarded Ad revenue: $revenue $currencyCode (Precision: $precision)',
            );
            AnalyticsService.shared.logAdRevenue(
              amount: revenue,
              currency: currencyCode,
              adNetwork: ad.responseInfo?.mediationAdapterClassName,
              adUnitId: ad.adUnitId,
              adPlacement: type,
              adType: 'Rewarded',
            );
          };

          debugPrint('✅ Rewarded $type loaded');

          onComplete?.call();
          if (context.mounted) {
            AdUIHelper.hideLoadingDialog();
          }
        },
        onAdFailedToLoad: (error) async {
          try {
            AnalyticsService.shared.logEvent(name: "${type}_fail");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
          _rewardedAd = null;
          _retryCount++;
          if (type == 'reward_quick_generate' && attemptsHighFloor) {
            debugPrint(
                '🔀 [reward_quick_generate] 2F failed, fallback to normal');
            await loadAd(
              type: type,
              onComplete: onComplete,
              context: context,
              useHighFloor: false,
            );
            return; // Early return để không chạy retry logic bên dưới
          }
          AdRetryHelper.handleRetry(
            retryCount: _retryCount,
            maxRetry: _maxRetry,
            loader: () => loadAd(
              type: type,
              onComplete: onComplete,
              context: context,
            ),
          );
          debugPrint('❌ Rewarded $type failed: ${error.message}');
        },
      ),
    );
  }

  bool canShowAd() {
    if (_rewardedAd == null || !_remoteConfig.adsEnabled) {
      return false;
    }
    final last = _lastRewardedShown;
    const minInterval = Duration(minutes: 1);
    return last == null || DateTime.now().difference(last) > minInterval;
  }

  bool _isShowingAd = false;
  bool get isShowingAd => _isShowingAd;

  Future<void> showAd({
    required VoidCallback onRewarded,
    VoidCallback? onComplete,
  }) async {
    if (!await AdNetworkHelper.hasNetworkConnection()) {
      debugPrint('⚠️ Cannot show Rewarded — no internet');
      onRewarded();
      onComplete?.call();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('⚠️ Rewarded not ready, giving reward directly');
      onRewarded();
      onComplete?.call();
      return;
    }

    _isShowingAd = true;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdClicked: (ad) {
        if (_currentType != null) {
          try {
            AnalyticsService.shared.logEvent(name: "${_currentType}_click");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
        }
        // User clicked ad, set flag
        _adService.setResumedDuringAd(true);
      },
      onAdShowedFullScreenContent: (ad) {
        if (_currentType != null) {
          try {
            AnalyticsService.shared.logEvent(name: "${_currentType}_imp");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
        }
        debugPrint('✅ Rewarded ad showed');
        // Set flag để không show resume ad nếu user tắt màn hình
        _adService.setResumedDuringAd(true);
      },
      onAdDismissedFullScreenContent: (ad) {
        if (_currentType != null) {
          try {
            AnalyticsService.shared.logEvent(name: "${_currentType}_dismiss");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
        }
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        _lastRewardedShown = DateTime.now();
        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        _adService.setResumedDuringAd(false);
        _adService.markAdJustClosed();
        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        if (_currentType != null) {
          try {
            AnalyticsService.shared.logEvent(name: "${_currentType}_fail");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
        }
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        ad.dispose();
        _rewardedAd = null;
        _isShowingAd = false;
        _adService.setResumedDuringAd(false);
        _adService.markAdJustClosed();
        onComplete?.call();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (_rewardedAd != null) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
          await _rewardedAd!.show(
            onUserEarnedReward: (ad, reward) {
              debugPrint('✅ User earned reward');
              onRewarded();
            },
          );
        } else {
          debugPrint("⚠️ Rewarded ad is null, cannot show.");
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
