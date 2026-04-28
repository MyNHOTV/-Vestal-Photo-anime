import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/connectivity_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Collapsible Banner Ad Widget
/// - Auto-reload every 15 seconds
/// - Collapsible on first load per app session, then stays expanded
/// - Fixed at bottom of screen
/// - Uses VisibilityDetector to pause when not visible
class CollapsibleBannerAdWidget extends StatefulWidget {
  final String placement; // e.g. 'banner_home'
  final bool isCollapsible; // Whether to show collapse button
  final bool? useHighFloor; // If null, use internal logic
  final VoidCallback? onAdFailed;

  const CollapsibleBannerAdWidget({
    super.key,
    required this.placement,
    this.isCollapsible = false, // Default to non-collapsible
    this.useHighFloor,
    this.onAdFailed,
  });

  @override
  State<CollapsibleBannerAdWidget> createState() =>
      _CollapsibleBannerAdWidgetState();
}

class _CollapsibleBannerAdWidgetState extends State<CollapsibleBannerAdWidget> {
  // Static tracker for first load per session (per placement)
  static final Map<String, bool> _hasCollapsedInSession = {};

  final _remoteConfig = RemoteConfigService.shared;
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false; // Track loading state
  bool _isEnabled = false;
  bool _isTryingHighFloor = false; // Track if we are trying high floor
  Timer? _reloadTimer;
  bool _isVisible = false; // Tracked by VisibilityDetector
  int? _screenWidth;
  StreamSubscription<List<ConnectivityResult>>? connectivitySubscription;

  // GetX workers for reactivity
  final List<Worker> _workers = [];

  // Retry mechanism
  int _failCount = 0;
  static const int _maxRetries = 2; // Stop loading after 2 failures

  @override
  void initState() {
    super.initState();
    _checkEnabledAndLoad();
    _listenToNetworkChanges();

    // Listen to Remote Config changes to make it reactive
    _workers.add(
        ever(_remoteConfig.adsEnabledRx, (_) => _resolveAndLoadIfNeeded()));
    _workers
        .add(ever(_remoteConfig.configRx, (_) => _resolveAndLoadIfNeeded()));
  }

  void _resolveAndLoadIfNeeded() {
    final wasEnabled = _isEnabled;
    _isEnabled = _remoteConfig.isBannerEnabled(widget.placement);

    if (!wasEnabled && _isEnabled && _bannerAd == null) {
      debugPrint('🔄 Banner re-enabled via Remote Config, loading...');
      _loadBannerAd();
    } else if (wasEnabled && !_isEnabled) {
      debugPrint('🚫 Banner disabled via Remote Config, disposing...');
      _stopAutoReload();
      _bannerAd?.dispose();
      _bannerAd = null;
      _isLoaded = false;
      if (mounted) setState(() {});
    }
  }

  void _listenToNetworkChanges() {
    connectivitySubscription =
        ConnectivityService.shared.connectivityStatus.listen((results) {
      if (ConnectivityService.shared.isConnected && mounted) {
        debugPrint('🌐 Network restored, checking banner ad...');
        // If ad is not loaded or failed, try reloading
        if (!_isLoaded) {
          debugPrint('🔄 Reloading banner ad due to network restore');
          // Reset fail count to give it a chance to load
          setState(() {
            _failCount = 0;
          });
          _loadBannerAd();
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get screen width for adaptive banner
    final mediaQuery = MediaQuery.of(context);
    _screenWidth = mediaQuery.size.width.truncate();
  }

  /// Check if this banner has collapsed in current app session
  bool get _hasCollapsedThisSession {
    return _hasCollapsedInSession[widget.placement] ?? false;
  }

  /// Mark this banner as collapsed in current session
  void _markAsCollapsedThisSession() {
    _hasCollapsedInSession[widget.placement] = true;
    debugPrint('💾 Marked ${widget.placement} as collapsed in this session');
  }

  /// Check if should use collapsible for this load
  bool get _shouldUseCollapsible {
    // Only use collapsible if:
    // 1. Widget is configured as collapsible
    // 2. AND hasn't collapsed yet in this session
    return widget.isCollapsible && !_hasCollapsedThisSession;
  }

  Future<void> _checkEnabledAndLoad() async {
    // Check if banner is enabled from remote config
    _isEnabled = _remoteConfig.isBannerEnabled(widget.placement);

    if (!_isEnabled) {
      return;
    }

    // For banner_splash, try to load immediately with Get.width if available
    if (widget.placement == 'banner_splash') {
      if (_screenWidth == null && Get.context != null) {
        _screenWidth = Get.width.truncate();
      }
      _loadBannerAd();
      return;
    }

    // Wait for screen width to be available
    await Future.delayed(const Duration(milliseconds: 100));
    await _loadBannerAd();
  }

  Future<void> _loadBannerAd() async {
    if (_screenWidth == null) {
      // Emergency fallback for splash
      if (widget.placement == 'banner_splash' && Get.context != null) {
        _screenWidth = Get.width.truncate();
      }

      if (_screenWidth == null) {
        debugPrint('⚠️ Screen width not available yet, skipping banner load');
        return;
      }
    }

    // Check if max retries exceeded
    if (_failCount >= _maxRetries) {
      debugPrint(
          '❌ Max retries ($_maxRetries) exceeded for ${widget.placement}, stopping banner loads');
      return;
    }

    // Set loading state
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    // Dispose existing ad
    _bannerAd?.dispose();
    _bannerAd = null;

    // Determine if we should start with High Floor (only on fresh attempt)
    if (_failCount == 0) {
      if (widget.useHighFloor != null) {
        _isTryingHighFloor = widget.useHighFloor!;
      } else if (widget.placement == 'banner_splash') {
        _isTryingHighFloor = _remoteConfig.bannerSplash2FloorEnabled;
      } else {
        _isTryingHighFloor = false;
      }
    }

    // Logic quan trọng: Nếu chuẩn bị load Normal Floor (do HF tắt hoặc đã thử HF thất bại)
    // thì phải chắc chắn tầng Normal Floor cũng đang bật.
    if (!_isTryingHighFloor) {
      bool isNormalEnabled = true;
      if (widget.placement == 'banner_splash') {
        isNormalEnabled = _remoteConfig.bannerSplashEnabled;
      }

      if (!isNormalEnabled) {
        debugPrint(
            '🚫 [Banner-${widget.placement}] Normal Floor is DISABLED. Aborting load.');
        if (mounted) {
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
            _isLoading = false;
            // Tăng failCount để dừng các lần thử lại vô ích
            _failCount++;
          });
        }
        return;
      }
    }

    // Get ad unit ID
    String adUnitId = _getAdUnitId();

    // If High Floor ID is invalid/empty, fallback immediately if Normal is enabled
    if (_isTryingHighFloor && (adUnitId.isEmpty)) {
      _isTryingHighFloor = false;
      // Re-check normal enablement if falling back
      bool isNormalEnabled = true;
      if (widget.placement == 'banner_splash') {
        isNormalEnabled = _remoteConfig.bannerSplashEnabled;
      }
      if (!isNormalEnabled) {
        debugPrint(
            '🚫 [Banner-${widget.placement}] HF empty & Normal DISABLED.');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _failCount++;
          });
        }
        return;
      }
      adUnitId = _getAdUnitId();
    }

    debugPrint(
        '🎯 Loading Collapsible Banner Ad [$adUnitId] (Attempt: ${_failCount + 1}/$_maxRetries)');
    debugPrint(
        '🚀 [Banner-${widget.placement}] ${_isTryingHighFloor ? "ATTEMPTING HIGH FLOOR (2F)" : "ATTEMPTING NORMAL FLOOR"}');
    debugPrint('📐 Screen width: $_screenWidth');

    // Get adaptive banner size
    final AdSize? size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      _screenWidth!,
    );

    if (size == null) {
      debugPrint('❌ Unable to get adaptive banner size');
      return;
    }

    debugPrint('📏 Banner size: ${size.width}x${size.height}');

    // Check if should use collapsible for this load
    final useCollapsible = _shouldUseCollapsible;
    debugPrint(
        '🔧 Use collapsible: $useCollapsible (hasCollapsedThisSession: $_hasCollapsedThisSession)');

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: size,
      request: AdRequest(
        extras: useCollapsible
            ? {
                // Use collapsible for first load in session
                'collapsible': 'bottom',
              }
            : {
                // No collapsible for subsequent loads
              },
      ),
      listener: BannerAdListener(
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          final revenue = valueMicros / 1000000.0;
          debugPrint(
            '💰 Banner Ad revenue: $revenue $currencyCode (Precision: $precision)',
          );
          AnalyticsService.shared.logAdRevenue(
            amount: revenue,
            currency: currencyCode,
            adNetwork: ad.responseInfo?.mediationAdapterClassName,
            adUnitId: ad.adUnitId,
            adPlacement: widget.placement,
            adType: 'Banner',
          );
        },
        onAdLoaded: (ad) {
          try {
            AnalyticsService.shared
                .logEvent(name: "${_getAnalyticsName()}_load");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
          if (!mounted) return;
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
            _isLoading = false; // Stop loading
            _failCount = 0; // Reset fail count on success
          });
          debugPrint(
              '✅ ${useCollapsible ? 'Collapsible ' : ''}Banner Ad loaded - ${_isTryingHighFloor ? "HIGH FLOOR (2F)" : "NORMAL FLOOR"} (Fail count reset)');
        },
        onAdFailedToLoad: (ad, error) {
          try {
            AnalyticsService.shared
                .logEvent(name: "${_getAnalyticsName()}_fail");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
          debugPrint('❌ Banner Ad failed: ${error.message}');
          ad.dispose();

          // Call the callback for waterfall logic
          widget.onAdFailed?.call();

          // Waterfall Logic: Fallback to Normal Floor
          if (_isTryingHighFloor) {
            debugPrint(
                '🔀 [Banner-${widget.placement}] 🛑 HIGH FLOOR 2F FAILED. Checking Normal Floor availability...');

            bool canFallback = true;
            if (widget.placement == 'banner_splash') {
              canFallback = _remoteConfig.bannerSplashEnabled;
            }

            if (!canFallback) {
              debugPrint(
                  '🚫 [Banner-${widget.placement}] Normal Floor is DISABLED. Skipping waterfall.');
            } else {
              debugPrint(
                  '⤵️ [Banner-${widget.placement}] Starting Waterfall Fallback to Normal Floor...');
              if (mounted) {
                setState(() {
                  _isTryingHighFloor = false;
                });
                _loadBannerAd();
              }
              return;
            }
          }

          if (mounted) {
            setState(() {
              _bannerAd = null;
              _isLoaded = false;
              _isLoading = false; // Stop loading
              _failCount++; // Increment fail count
            });

            if (_failCount >= _maxRetries) {
              debugPrint(
                  '🚫 Banner ${widget.placement} reached max retries ($_maxRetries), will not retry');
            } else {
              debugPrint(
                  '⚠️ Banner ${widget.placement} failed (${_failCount}/$_maxRetries attempts)');
            }
          }
        },
        onAdOpened: (ad) {
          debugPrint('🎯 Banner Ad opened/expanded');
        },
        onAdClosed: (ad) {
          try {
            AnalyticsService.shared
                .logEvent(name: "${_getAnalyticsName()}_dismiss");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
          debugPrint('🔒 Banner Ad closed/collapsed');
          // Mark as collapsed in this session so subsequent reloads won't be collapsible
          if (widget.isCollapsible) {
            _markAsCollapsedThisSession();
          }
        },
        onAdClicked: (ad) {
          try {
            AnalyticsService.shared
                .logEvent(name: "${_getAnalyticsName()}_click");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
          debugPrint('👆 Banner Ad clicked');
        },
        onAdImpression: (ad) {
          try {
            AnalyticsService.shared
                .logEvent(name: "${_getAnalyticsName()}_imp");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
        },
      ),
    );

    await bannerAd.load();
  }

  String _getAdUnitId() {
    if (_isTryingHighFloor) {
      return _remoteConfig.getBannerHighFloorAdUnitId(widget.placement);
    }
    return _remoteConfig.getBannerAdUnitId(widget.placement);
  }

  String _getAnalyticsName() {
    return widget.placement.replaceFirst('banner_', 'banner_ad_');
  }

  void _startAutoReload() {
    _stopAutoReload();
    debugPrint('▶️ Starting banner auto-reload timer');
    _reloadTimer = Timer.periodic(const Duration(seconds: 120), (timer) {
      // Only reload if widget is mounted, enabled, and visible
      if (mounted && _isEnabled && _isVisible && !_isLoading) {
        debugPrint('🔄 Auto-reloading banner ad (visible: $_isVisible)');
        _loadBannerAd();
      } else {
        debugPrint('⏭️ Skipping banner reload (visible: $_isVisible)');
      }
    });
  }

  void _stopAutoReload() {
    if (_reloadTimer != null) {
      debugPrint('⏸️ Stopping banner auto-reload timer');
      _reloadTimer?.cancel();
      _reloadTimer = null;
    }
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;
    final isVisible =
        info.visibleFraction > 0.1; // Consider visible if >10% shown

    if (_isVisible != isVisible) {
      debugPrint(
          '👁️ Banner visibility changed: $_isVisible -> $isVisible (${info.visibleFraction.toStringAsFixed(2)})');
      _isVisible = isVisible;

      if (_isVisible && _isEnabled) {
        // Widget became visible, start auto-reload
        _startAutoReload();
      } else {
        // Widget became invisible, stop auto-reload
        _stopAutoReload();
      }
    }
  }

  @override
  void dispose() {
    for (var worker in _workers) {
      worker.dispose();
    }
    connectivitySubscription?.cancel();
    _stopAutoReload();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading placeholder
    if (_isEnabled && _isLoading) {
      return Container(
        color: Colors.grey[300],
        height: 50,
        width: double.infinity,
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),
        ),
      );
    }

    // Hide if not loaded or disabled
    if (!_isEnabled || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    // Show banner ad
    return VisibilityDetector(
      key: Key('banner_ad_${widget.placement}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: Container(
        decoration: const BoxDecoration(
            color: Color(0xFFF7F7F7),
            border:
                Border(top: BorderSide(color: Color(0xFFDDDDDD), width: 1))),
        height: _bannerAd!.size.height.toDouble(),
        width: double.infinity,
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
