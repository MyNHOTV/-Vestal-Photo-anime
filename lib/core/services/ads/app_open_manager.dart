import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quick_base/core/services/ads_service.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'ad_helpers.dart';

class AppOpenManager {
  final RemoteConfigService _remoteConfig;
  final AdService _adService;

  AppOpenAd? _appOpenAd;
  int _retryCount = 0;
  final int _maxRetry = 2;

  // Track thời gian lần retry cuối cùng để auto-reset sau một khoảng thời gian
  DateTime? _lastRetryTime;
  static const Duration _retryResetDuration = Duration(minutes: 5);

  // Track trạng thái loading và thông tin để retry khi mạng quay lại
  bool _isLoadingAd = false;
  String? _pendingLoadType;
  BuildContext? _pendingLoadContext;
  VoidCallback? _pendingOnLoaded;
  VoidCallback? _pendingOnFailed;
  bool _pendingShowLoading = false;

  AppOpenManager(this._remoteConfig, this._adService);
  void resetRetryCount() {
    _retryCount = 0;
    _lastRetryTime = null;
    debugPrint('🔄 AppOpen retry count reset');
  }

  // Kiểm tra và auto-reset retryCount nếu đã quá lâu
  void _checkAndResetRetryCountIfNeeded() {
    if (_lastRetryTime != null) {
      final timeSinceLastRetry = DateTime.now().difference(_lastRetryTime!);
      if (timeSinceLastRetry > _retryResetDuration) {
        debugPrint(
            '🔄 Auto-resetting retry count after ${_retryResetDuration.inMinutes} minutes');
        _retryCount = 0;
        _lastRetryTime = null;
      }
    } else if (_retryCount > 0) {
      // Nếu có retryCount nhưng không có lastRetryTime, reset luôn (có thể do app restart)
      debugPrint('🔄 Resetting retry count (no lastRetryTime recorded)');
      _retryCount = 0;
      _lastRetryTime = null;
    }
  }

  Future<void> loadAd(
    String type, {
    required BuildContext context,
    VoidCallback? onLoaded,
    VoidCallback? onFailed,
    bool showLoading = true,
    bool isRetry = false, // Flag để biết đây có phải là retry không
    bool?
        useHighFloor, // Override 2F logic (true = force 2F, false = force normal)
    bool skipDialogShow = false, // Skip showing dialog (for waterfall fallback)
  }) async {
    // Kiểm tra và auto-reset retryCount nếu cần
    _checkAndResetRetryCountIfNeeded();

    // Nếu không phải retry và retryCount > 0, reset về 0 để cho cơ hội mới
    if (!isRetry && _retryCount > 0) {
      debugPrint(
          '🔄 [AppOpen-$type] New load attempt, resetting retry count from $_retryCount to 0');
      _retryCount = 0;
      _lastRetryTime = null;
    }

    debugPrint(
        '🔄 [AppOpen-$type] loadAd called - retryCount: $_retryCount, isRetry: $isRetry');

    final isEnabled = _remoteConfig.isAppOpenEnabled(type);

    // Determine if we should attempt High Floor
    // Only if not explicitly retrying (unless forced) and 2F is enabled
    final bool highFloorEnabled = _remoteConfig.isAppOpenHighFloorEnabled(type);

    // If useHighFloor is provided, honor it.
    // Otherwise, try High Floor if enabled and this is a fresh start (not a retry of the same ID)
    final bool attemptsHighFloor =
        useHighFloor ?? (highFloorEnabled && !isRetry);

    if (!isEnabled) {
      debugPrint('🚫 [AppOpen-$type] Ads disabled by config');
      onFailed?.call();
      return;
    }

    if (_appOpenAd != null) {
      debugPrint('✅ [AppOpen-$type] Ad already loaded, skipping load');
      onLoaded?.call();
      return;
    }

    if (_isLoadingAd && _pendingLoadType == type) {
      debugPrint('⏳ [AppOpen-$type] Ad is already loading, skipping load');
      return;
    }

    final hasNetwork = await AdNetworkHelper.hasNetworkConnection();
    debugPrint('🌐 [AppOpen-$type] Network check: $hasNetwork');
    if (!hasNetwork) {
      debugPrint(
          '🚫 [AppOpen-$type] No network connection - saving for retry when network restored');
      // Lưu lại thông tin để retry khi mạng quay lại
      _isLoadingAd = true;
      _pendingLoadType = type;
      _pendingLoadContext = context;
      _pendingOnLoaded = onLoaded;
      _pendingOnFailed = onFailed;
      _pendingShowLoading = showLoading;
      onFailed?.call();
      return;
    }

    if (_retryCount >= _maxRetry) {
      debugPrint(
          "🚫 Skip loading AppOpen — reached max retry ($_retryCount/$_maxRetry)");
      onFailed?.call();
      return;
    }

    // New Logic: If we are about to load Normal Floor (either because HF is disabled or we are falling back)
    // We must ensure that the Normal Floor flag is actually enabled.
    if (!attemptsHighFloor) {
      final bool normalEnabled = _remoteConfig.isAppOpenNormalEnabled(type);

      if (!normalEnabled) {
        debugPrint(
            '🚫 [AppOpen-$type] Normal Floor is DISABLED. Aborting load.');
        onFailed?.call();
        return;
      }
    }

    String adUnitId = attemptsHighFloor
        ? _remoteConfig.getAppOpenHighFloorAdUnitId(type)
        : _remoteConfig.getAppOpenAdUnitId(type);

    // Validate adUnitId
    if (adUnitId.isEmpty || adUnitId.trim().isEmpty) {
      debugPrint('❌ [AppOpen-$type] AdUnitId is empty or invalid');
      _isLoadingAd = false;
      _pendingLoadType = null;
      _pendingLoadContext = null;
      _pendingOnLoaded = null;
      _pendingOnFailed = null;
      onFailed?.call();
      return;
    }

    debugPrint('📱 [AppOpen-$type] Using adUnitId: $adUnitId');
    debugPrint(
        '🚀 [AppOpen-$type] ${attemptsHighFloor ? "ATTEMPTING HIGH FLOOR (2F)" : "ATTEMPTING NORMAL FLOOR"}');

    if (showLoading && type != 'splash' && context.mounted && !skipDialogShow) {
      await AdUIHelper.showLoadingDialog();
    }

    // Set flag khi bắt đầu load
    _isLoadingAd = true;
    _pendingLoadType = type;
    _pendingLoadContext = context;
    _pendingOnLoaded = onLoaded;
    _pendingOnFailed = onFailed;
    _pendingShowLoading = showLoading;

    debugPrint('🔄 [AppOpen-$type] Starting AppOpenAd.load()...');
    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          try {
            AnalyticsService.shared.logEvent(name: "app_open_${type}_load");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }

          // Reset flags khi load thành công
          _isLoadingAd = false;
          _pendingLoadType = null;
          _pendingLoadContext = null;
          _pendingOnLoaded = null;
          _pendingOnFailed = null;

          _appOpenAd = ad;
          _retryCount = 0;
          // ✅ Thêm onPaidEvent callback để track ad revenue
          _appOpenAd?.onPaidEvent = (ad, valueMicros, precision, currencyCode) {
            final revenue = valueMicros / 1000000.0;
            debugPrint(
              '💰 AppOpen Ad revenue: $revenue $currencyCode (Precision: $precision)',
            );
            AnalyticsService.shared.logAdRevenue(
              amount: revenue,
              currency: currencyCode,
              adNetwork: ad.responseInfo?.mediationAdapterClassName,
              adUnitId: ad.adUnitId,
              adPlacement: type,
              adType: 'AppOpen',
            );
          };
          debugPrint(
              '✅ [AppOpen-$type] Loaded successfully (${attemptsHighFloor ? "HIGH FLOOR 2F" : "NORMAL FLOOR"})');
          debugPrint('   ResponseInfo: ${ad.responseInfo}');
          onLoaded?.call();
          if (showLoading && type != 'splash' && context.mounted) {
            AdUIHelper.hideLoadingDialog();
          }
        },
        onAdFailedToLoad: (err) async {
          try {
            AnalyticsService.shared.logEvent(name: "app_open_${type}_fail");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }

          debugPrint('❌ [AppOpen-$type] Load failed:');
          debugPrint('   Message: ${err.message}');
          debugPrint('   Code: ${err.code}');
          debugPrint('   Domain: ${err.domain}');
          debugPrint('   ResponseInfo: ${err.responseInfo}');
          _appOpenAd = null;

          // Kiểm tra xem có phải do mất mạng không
          final hasNetwork = await AdNetworkHelper.hasNetworkConnection();
          if (!hasNetwork) {
            debugPrint(
                '🌐 [AppOpen-$type] Network lost during load, will retry when network restored');
            // Giữ lại thông tin để retry khi mạng quay lại
            // Không tăng retry count vì đây là do mất mạng
            // Không gọi onFailed ngay, đợi mạng quay lại
            return;
          }

          // FALLBACK LOGIC FOR 2 FLOOR
          if (attemptsHighFloor) {
            debugPrint(
                '🔀 [AppOpen-$type] 🛑 HIGH FLOOR 2F FAILED. Checking Normal Floor availability...');

            final bool canFallback = _remoteConfig.isAppOpenNormalEnabled(type);

            if (!canFallback) {
              debugPrint(
                  '🚫 [AppOpen-$type] Normal Floor is DISABLED. Skipping waterfall.');
              // No fallback possible, call onFailed and return
              _isLoadingAd = false;
              _pendingLoadType = null;
              if (showLoading && type != 'splash' && context.mounted) {
                AdUIHelper.hideLoadingDialog();
              }
              onFailed?.call();
              return;
            } else {
              debugPrint(
                  '⤵️ [AppOpen-$type] Starting Waterfall Fallback to Normal Floor...');

              // Cleanup current state to allow new load
              _isLoadingAd = false;
              _pendingLoadType = null;
              _pendingLoadContext = null;
              _pendingOnLoaded = null;
              _pendingOnFailed = null;

              if (context.mounted) {
                loadAd(
                  type,
                  context: context,
                  onLoaded: onLoaded,
                  onFailed: onFailed,
                  showLoading: showLoading,
                  isRetry: false, // Treat as fresh load for normal ID
                  useHighFloor: false, // Force normal ID
                  skipDialogShow:
                      true, // Dialog is already up if showLoading was true
                );
              }
              return;
            }
          }

          // Nếu không phải do mất mạng, xử lý như bình thường
          _retryCount++;
          _lastRetryTime = DateTime.now(); // Lưu thời gian retry

          debugPrint(
              "🔁 [AppOpen-$type] Retry attempt $_retryCount/$_maxRetry");
          debugPrint(
              "   Error details: Code=${err.code}, Message=${err.message}");

          // Kiểm tra các lỗi không nên retry (lỗi cấu hình)
          // Code 3 = INVALID_AD_UNIT_ID - Ad unit không đúng format
          // Code 0 = INTERNAL_ERROR hoặc các lỗi khác
          final shouldSkipRetry = err.code == 3 || // Invalid ad unit format
              err.code == 0 || // Internal error
              err.message.toLowerCase().contains('invalid ad unit') ||
              err.message.toLowerCase().contains('doesn\'t match format') ||
              err.message.toLowerCase().contains('ad unit doesn\'t match');

          if (shouldSkipRetry) {
            debugPrint(
                "🚫 [AppOpen-$type] Configuration error detected (Code: ${err.code})");
            debugPrint(
                "   ⚠️ This is a configuration issue, not a network/load issue.");
            debugPrint("   ⚠️ Please check your ad unit ID in Remote Config:");
            if (type == 'resume') {
              debugPrint("   - Android: ${_remoteConfig.androidAppOpenResume}");
              debugPrint("   - iOS: ${_remoteConfig.iosAppOpenResume}");
            } else {
              debugPrint("   - Android: ${_remoteConfig.androidAppOpen}");
              debugPrint("   - iOS: ${_remoteConfig.iosAppOpen}");
            }
            debugPrint("   ⚠️ Skipping retry to avoid unnecessary attempts.");

            _isLoadingAd = false;
            _pendingLoadType = null;
            _pendingLoadContext = null;
            _pendingOnLoaded = null;
            _pendingOnFailed = null;
            if (showLoading && type != 'splash' && context.mounted) {
              AdUIHelper.hideLoadingDialog();
            }
            onFailed?.call();
            return;
          }

          if (_retryCount <= _maxRetry) {
            debugPrint(
                "🔁 Retry AppOpen $type ($_retryCount/$_maxRetry) after 3s delay");
            await Future.delayed(const Duration(milliseconds: 3000));
            if (context.mounted) {
              return loadAd(
                type,
                context: context,
                onLoaded: onLoaded,
                onFailed: onFailed,
                showLoading: showLoading,
                isRetry: true, // Đánh dấu đây là retry
              );
            }
          }

          // Reset flags khi đã retry hết hoặc không thể retry
          _isLoadingAd = false;
          _pendingLoadType = null;
          _pendingLoadContext = null;
          _pendingOnLoaded = null;
          _pendingOnFailed = null;

          if (showLoading && type != 'splash' && context.mounted) {
            AdUIHelper.hideLoadingDialog();
          }
          debugPrint(
              "🚫 [AppOpen-$type] Max retry reached ($_retryCount/$_maxRetry) — skip load");
          onFailed?.call();
        },
      ),
    );
  }

  bool _isShowingAd = false;
  bool get isShowingAd => _isShowingAd;

  Future<void> showAd(String type, {VoidCallback? onComplete}) async {
    // *** LOGIC MỚI: KIỂM TRA CỜ resumedDuringAd ***
    if (_adService.resumedDuringAd) {
      debugPrint(
        "🚫 Bỏ qua AppOpen vì app vừa resume trong khi có quảng cáo khác.",
      );
      onComplete?.call();
      return;
    }

    if (_isShowingAd) {
      debugPrint("⚠️ AppOpen is already showing, skip.");
      return;
    }

    if (!_remoteConfig.adsEnabled) {
      onComplete?.call();
      return;
    }

    // Kiểm tra thêm cho resume ads
    if (type == 'resume' && !_remoteConfig.appOpenResumeEnabled) {
      onComplete?.call();
      return;
    }

    if (!await AdNetworkHelper.hasNetworkConnection()) {
      onComplete?.call();
      return;
    }

    if (_appOpenAd == null) {
      debugPrint('⚠️ AppOpen not ready');

      if (_retryCount >= _maxRetry) {
        debugPrint("🚫 Skip showing AppOpen — max retry reached");
        onComplete?.call();
        return;
      }

      debugPrint("🔁 Try reload AppOpen ($type)");
      onComplete?.call();
      return;
    }

    _isShowingAd = true;

    // Hiển thị overlay màu trắng trước khi show ad
    AdUIHelper.showWhiteOverlay();

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        try {
          AnalyticsService.shared.logEvent(name: "app_open_${type}_imp");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }
      },
      onAdClicked: (ad) {
        try {
          AnalyticsService.shared.logEvent(name: "app_open_${type}_click");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        try {
          AnalyticsService.shared.logEvent(name: "app_open_${type}_dismiss");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        // Ẩn overlay màu trắng khi ad đóng
        AdUIHelper.hideWhiteOverlay();

        ad.dispose();
        _appOpenAd = null;
        _isShowingAd = false;

        // Mark ad just closed to prevent consecutive ads
        _adService.markAdJustClosed();
        _adService.setResumedDuringAd(false);

        onComplete?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        try {
          AnalyticsService.shared.logEvent(name: "app_open_${type}_fail");
        } catch (e) {
          debugPrint("⚠️ Analytics error: $e");
        }
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

        // Ẩn overlay nếu ad không hiển thị được
        AdUIHelper.hideWhiteOverlay();
        ad.dispose();
        _appOpenAd = null;
        _isShowingAd = false;

        // Mark ad just closed to prevent consecutive ads
        _adService.markAdJustClosed();
        _adService.setResumedDuringAd(false);

        onComplete?.call();
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (_appOpenAd != null) {
          SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

          await _appOpenAd!.show();
        } else {
          debugPrint("⚠️ AppOpen ad is null, cannot show.");
          // Dừng timer và ẩn overlay nếu ad null
          AdUIHelper.hideWhiteOverlay();
          _isShowingAd = false;
          onComplete?.call();
        }
      } catch (e) {
        debugPrint("⚠️ Error showing ad: $e");
        // Dừng timer và ẩn overlay nếu có lỗi
        AdUIHelper.hideWhiteOverlay();
        _isShowingAd = false;
        onComplete?.call();
      }
    });
  }

  // Getter để check xem ad có đang pending retry không
  bool get isPendingRetry => _isLoadingAd && _pendingLoadType != null;

  // Method để retry load khi mạng quay lại
  Future<void> retryLoadIfPending() async {
    if (_isLoadingAd &&
        _pendingLoadType != null &&
        _pendingLoadContext != null) {
      final hasNetwork = await AdNetworkHelper.hasNetworkConnection();
      if (hasNetwork) {
        debugPrint(
            '🔄 [AppOpen] Network restored, retrying load for type: $_pendingLoadType');

        // Lưu lại thông tin trước khi reset
        final type = _pendingLoadType!;
        final context = _pendingLoadContext!;
        final onLoaded = _pendingOnLoaded;
        final onFailed = _pendingOnFailed;
        final showLoading = _pendingShowLoading;

        // Reset flags trước khi retry
        _isLoadingAd = false;
        _pendingLoadType = null;
        _pendingLoadContext = null;
        _pendingOnLoaded = null;
        _pendingOnFailed = null;
        _pendingShowLoading = false;

        // Reset retry count để có thể retry lại
        _retryCount = 0;
        _lastRetryTime = null;

        // Retry load (không phải retry từ failed, mà là retry khi network restored)
        if (context.mounted) {
          await loadAd(
            type,
            context: context,
            onLoaded: onLoaded,
            onFailed: onFailed,
            showLoading: showLoading,
            isRetry: false, // Network restored retry được coi như load mới
          );
        }
      }
    }
  }
}
