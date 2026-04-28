import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// Widget Native Ad dùng chung
/// Hỗ trợ factoryId (fullScreenNativeAd, listTileLight, v.v.)
/// Tích hợp Remote Config bật/tắt từng vị trí
/// Có thể tự refresh theo interval
class NativeAdWidget extends StatefulWidget {
  final String uniqueKey; // ví dụ: native_onboarding, native_list, native_home
  final String factoryId; // ví dụ: fullScreenNativeAd, listTileLight
  final Duration? refreshInterval;
  final double? height;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final bool hasBorder;
  final bool? isPreloadedAdLoaded;

  final Color backgroundColor;
  final Color? buttonColor; // Màu button tùy chỉnh (null = dùng màu mặc định)
  final Color? adBackgroundColor;
  final Color? titleColor; // Màu title/headline
  final double? iconSize;
  final double? mediaHeight;
  final void Function(bool isLoading)?
      onLoadingChanged; // Callback khi loading state thay đổi
  final Border? border;
  final BorderRadius? borderRadius;

  const NativeAdWidget({
    super.key,
    required this.uniqueKey,
    required this.factoryId,
    this.refreshInterval,
    this.height = 250,
    this.margin,
    this.backgroundColor = const Color(0xFFF7F7F7),
    this.padding,
    this.hasBorder = false,
    this.buttonColor,
    this.adBackgroundColor,
    this.titleColor,
    this.iconSize,
    this.mediaHeight,
    this.onLoadingChanged,
    this.onAdFailed,
    this.preloadedAd,
    this.isPreloadedAdLoaded,
    this.border,
    this.borderRadius,
  });

  final VoidCallback? onAdFailed;
  final NativeAd? preloadedAd;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with WidgetsBindingObserver {
  final _remoteConfig = RemoteConfigService.shared;
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isEnabled = false;

  int _retryCount = 0;
  final int _maxRetry = 1;

  // 3. Thêm Timer và biến trạng thái
  Timer? _refreshTimer;
  static const _refreshDuration = Duration(seconds: 15);
  bool _isVisible = false;
  bool _isReloading = false; // Biến cờ để tránh tải lại đồng thời
  bool _isAppPaused = false;

  // Cờ kiểm tra xem widget có phải là loại cần refresh sau 15s hay không
  bool get _shouldAutoRefresh =>
      widget.uniqueKey == 'native_image' ||
      widget.uniqueKey == 'native_info' ||
      widget.uniqueKey == 'native_history';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupConfigAndLoad();
    _listenToNetworkChanges();

    // Add listener to re-trigger load if ad is re-enabled or config changes
    ever(_remoteConfig.adsEnabledRx, (_) => _resolveAndLoadIfNeeded());
    ever(_remoteConfig.configRx, (_) => _resolveAndLoadIfNeeded());
  }

  void _resolveAndLoadIfNeeded() {
    final wasEnabled = _isEnabled;
    _resolveEnabledFlag();
    if (!wasEnabled && _isEnabled && _nativeAd == null) {
      _loadNativeAd(widget.uniqueKey);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _isAppPaused = true;
      debugPrint(
          "📱 App paused, stopping native ad refresh [${widget.uniqueKey}]");
      _stopRefreshTimer();
    } else if (state == AppLifecycleState.resumed) {
      _isAppPaused = false;
      debugPrint("📱 App resumed [${widget.uniqueKey}]");
      // Nếu widget đang visible, đã load, là loại auto-refresh và có mạng -> start timer
      if (_isVisible &&
          _isLoaded &&
          _shouldAutoRefresh &&
          NetworkService.to.isConnected.value) {
        _startRefreshTimer();
      }
    }
  }

  @override
  void didUpdateWidget(covariant NativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.preloadedAd != null) {
      // If switching to or updating preloaded ad
      if (widget.preloadedAd != _nativeAd ||
          widget.isPreloadedAdLoaded != _isLoaded) {
        setState(() {
          _nativeAd = widget.preloadedAd;
          _isLoaded = widget.isPreloadedAdLoaded ?? false;
        });
        // Also notify listener if needed?
        if (_isLoaded) {
          widget.onLoadingChanged?.call(false);
        }
      }
    }
  }

  void _listenToNetworkChanges() {
    // Listen to NetworkService instead of ConnectivityService
    ever(NetworkService.to.isConnected, (isConnected) {
      if (!mounted) return;

      if (isConnected) {
        debugPrint('🌐 Internet restored, checking native ad...');

        // 1. Nếu ad chưa load hoặc load lỗi, thử load lại
        if ((!_isLoaded || _nativeAd == null) &&
            !_isReloading &&
            widget.preloadedAd == null) {
          debugPrint(
              '🌐 Internet restored, reloading native ad [${widget.uniqueKey}]');
          setState(() {
            _retryCount = 0;
          });
          _loadNativeAd(widget.uniqueKey);
        }
        // 2. Nếu đã load rồi, đang hiển thị, là loại auto refresh, và đang không có timer -> Start timer
        else if (_shouldAutoRefresh && _isVisible && _refreshTimer == null) {
          debugPrint(
              '🌐 Internet restored, restarting refresh timer [${widget.uniqueKey}]');
          _startRefreshTimer();
        }
      } else {
        // Mất mạng -> stop timer
        debugPrint(
            '🌐 Internet lost, stopping refresh timer [${widget.uniqueKey}]');
        _stopRefreshTimer();
      }
    });
  }

  void _startRefreshTimer() {
    // Chỉ khởi động Timer nếu _shouldAutoRefresh là true, ads đã được load và widget đang hiển thị
    // Thêm check: Phải có mạng và App không bị pause
    if (!_shouldAutoRefresh ||
        !_isLoaded ||
        !_isVisible ||
        _refreshTimer != null ||
        !NetworkService.to.isConnected.value ||
        _isAppPaused) {
      return;
    }

    // Hủy Timer cũ nếu có (an toàn)
    _refreshTimer?.cancel();

    _refreshTimer = Timer.periodic(_refreshDuration, (timer) {
      // Check lại điều kiện trong timer tick cho chắc chắn
      if (mounted &&
          _isVisible &&
          !_isReloading &&
          !_isAppPaused &&
          NetworkService.to.isConnected.value &&
          widget.preloadedAd == null) {
        debugPrint(
            "🔁 Auto-refreshing native ad [${widget.uniqueKey}] after 15s...");
        setState(() {
          _retryCount = 0;
        });
        _loadNativeAd(widget.uniqueKey, isAutoRefresh: true);
      } else {
        // Nếu điều kiện không thỏa mãn (ví dụ vừa mất mạng, hoặc vừa ẩn), stop timer
        if (!NetworkService.to.isConnected.value ||
            !_isVisible ||
            _isAppPaused) {
          _stopRefreshTimer();
        }
      }
    });
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRefreshTimer(); // Hủy Timer khi dispose
    _nativeAd?.dispose();
    super.dispose();
  }

  Future<void> _setupConfigAndLoad() async {
    _resolveEnabledFlag();

    if (!_isEnabled) {
      widget.onLoadingChanged?.call(false); // Notify not loading
      return;
    }

    if (widget.preloadedAd != null) {
      setState(() {
        _nativeAd = widget.preloadedAd;
        _isLoaded = widget.isPreloadedAdLoaded ?? false;
      });
      if (_isLoaded) {
        widget.onLoadingChanged?.call(false);
      }
      return;
    }

    await _loadNativeAd(widget.uniqueKey);
  }

  void _resolveEnabledFlag() {
    _isEnabled = _remoteConfig.isNativeEnabled(widget.uniqueKey);
  }

  Future<void> _loadNativeAd(String type, {bool isAutoRefresh = false}) async {
    // 0. Đảm bảo có mạng mới load
    if (!NetworkService.to.isConnected.value) {
      debugPrint("🚫 No internet, skipping load for $type");
      return;
    }

    // Nếu đang trong quá trình tải lại, thoát để tránh tải nhiều lần
    if (_isReloading) return;

    // Chỉ kiểm tra retry count nếu không phải là auto-refresh (retry count chỉ áp dụng cho lỗi tải lần đầu)
    if (!isAutoRefresh && _retryCount >= _maxRetry) {
      debugPrint("❌ Native Ad retry limit reached ($type)");
      if (mounted) {
        setState(() {
          _isLoaded = false;
          _nativeAd?.dispose();
          _nativeAd = null;
        });
      }
      return;
    }

    // Đặt cờ đang tải lại và xả ad cũ
    if (mounted) {
      setState(() {
        _isReloading = true;
        _isLoaded = false;
        _nativeAd?.dispose();
        _nativeAd = null;
      });
    }

    // Tạm dừng Timer trong khi tải lại
    if (isAutoRefresh) {
      _stopRefreshTimer();
    }

    final adUnitId = _remoteConfig.getNativeAdUnitId(type);

    final customOptionsMap = (widget.buttonColor != null ||
            widget.adBackgroundColor != null ||
            widget.titleColor != null ||
            widget.iconSize != null ||
            widget.mediaHeight != null)
        ? {
            if (widget.buttonColor != null)
              'buttonColor': widget.buttonColor!.value, // Pass color as int
            if (widget.adBackgroundColor != null)
              'adBackgroundColor': widget
                  .adBackgroundColor!.value, // Pass ad background color as int
            if (widget.titleColor != null)
              'titleColor': widget.titleColor!.value, // Pass title color as int
            if (widget.iconSize != null)
              'iconSize': widget.iconSize!, // Pass icon size in dp
            if (widget.mediaHeight != null)
              'mediaHeight': widget.mediaHeight!, // Pass media height in dp
          }
        : null;

    // Debug log
    if (customOptionsMap != null) {
      debugPrint('🎨 [NativeAdWidget] customOptions: $customOptionsMap');
      debugPrint(
          '🎨 [NativeAdWidget] buttonColor: ${widget.buttonColor?.value}');
      debugPrint('🎨 [NativeAdWidget] titleColor: ${widget.titleColor?.value}');
      debugPrint('🎨 [NativeAdWidget] factoryId: ${widget.factoryId}');
    }

    final native = NativeAd(
      adUnitId: adUnitId,
      factoryId: widget.factoryId,
      customOptions: customOptionsMap,
      listener: NativeAdListener(
        onPaidEvent: (ad, valueMicros, precision, currencyCode) {
          final revenue = valueMicros / 1000000.0;
          debugPrint(
            '💰 Native Ad revenue: $revenue $currencyCode (Precision: $precision)',
          );
          AnalyticsService.shared.logAdRevenue(
            amount: revenue,
            currency: currencyCode,
            adNetwork: ad.responseInfo?.mediationAdapterClassName,
            adUnitId: ad.adUnitId,
            adPlacement: widget.uniqueKey,
            adType: 'Native',
          );
        },
        onAdLoaded: (ad) {
          // Analytics: Load
          try {
            AnalyticsService.shared.logEvent(name: "${widget.uniqueKey}_load");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }

          if (!mounted) return;
          setState(() {
            _nativeAd = ad as NativeAd;
            _isLoaded = true;
            _isReloading = false; // Tắt cờ tải lại
          });
          widget.onLoadingChanged?.call(false); // Notify loaded
          debugPrint("✅ Native Ad loaded [${widget.uniqueKey}]");
          // Bắt đầu Timer sau khi load thành công
          _startRefreshTimer();
        },
        onAdFailedToLoad: (ad, error) async {
          // Analytics: Fail
          try {
            AnalyticsService.shared.logEvent(name: "${widget.uniqueKey}_fail");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }

          debugPrint("❌ Ad failed [${widget.uniqueKey}] -> ${error.message}");
          ad.dispose();
          _isReloading = false; // Tắt cờ tải lại

          if (!isAutoRefresh) {
            _retryCount++;
          }

          // Notify failure immediately if needed
          widget.onAdFailed?.call();

          // Tải lại sau khi mất mạng chỉ xảy ra nếu không phải là auto-refresh
          if (!isAutoRefresh && _retryCount < _maxRetry) {
            debugPrint("🔁 Retry $_retryCount / $_maxRetry for $type");
            await Future.delayed(const Duration(milliseconds: 3000));
            _loadNativeAd(type);
          } else {
            debugPrint("🚫 Max retry reached ($type) or auto-refresh failed.");
            if (mounted) {
              setState(() {
                _nativeAd = null;
                _isLoaded = false;
              });
            }
          }
          // Nếu là auto-refresh và thất bại, không cần làm gì thêm, Timer sẽ được kiểm tra lại khi load thành công.
          // Nhưng ở đây, nếu load thất bại, ta nên thử khởi động lại timer nếu là loại ad tự refresh.
          if (_shouldAutoRefresh &&
              _isVisible &&
              NetworkService.to.isConnected.value &&
              !_isAppPaused) {
            debugPrint("🔄 Auto-refresh failed, trying to restart timer...");
            // Chờ một khoảng thời gian ngắn (ví dụ 5s) trước khi thử load lại/khởi động Timer
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted &&
                  _isVisible &&
                  !_isAppPaused &&
                  NetworkService.to.isConnected.value) {
                _startRefreshTimer();
              }
            });
          }
        },
        onAdImpression: (ad) {
          // Analytics: Impression
          try {
            AnalyticsService.shared.logEvent(name: "${widget.uniqueKey}_imp");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
        },
        onAdClicked: (ad) {
          // Analytics: Click
          try {
            AnalyticsService.shared.logEvent(name: "${widget.uniqueKey}_click");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
        },
        onAdClosed: (ad) {
          // Analytics: Dismiss/Closed
          try {
            AnalyticsService.shared
                .logEvent(name: "${widget.uniqueKey}_dismiss");
          } catch (e) {
            debugPrint("⚠️ Analytics error: $e");
          }
        },
      ),
      request: const AdRequest(),
    );

    await native.load();
  }

  // 4. Hàm xử lý sự kiện hiển thị
  void _onVisibilityChanged(VisibilityInfo info) {
    if (!mounted) return;

    final isCurrentlyVisible = info.visibleFraction > 0.1;

    if (isCurrentlyVisible != _isVisible) {
      _isVisible = isCurrentlyVisible;
      debugPrint(
          "👀 Visibility changed for [${widget.uniqueKey}]: $_isVisible");

      if (_shouldAutoRefresh) {
        if (_isVisible) {
          // Bắt đầu Timer khi widget hiển thị và ad đã load
          if (_isLoaded) {
            _startRefreshTimer();
          }
        } else {
          // Dừng Timer khi widget không hiển thị
          _stopRefreshTimer();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEnabled) return const SizedBox.shrink();

    // 5. Wrap AdWidget bằng VisibilityDetector
    return VisibilityDetector(
      key: Key(widget.uniqueKey),
      onVisibilityChanged: _onVisibilityChanged,
      child: _buildAdContent(),
    );
  }

  Widget _buildAdContent() {
    // Luôn ẩn ad nếu không thực sự có internet để tránh lỗi "Web page not available"
    return Obx(() {
      if (!NetworkService.to.isConnected.value) {
        return const SizedBox.shrink();
      }

      if (!_isLoaded && _retryCount >= _maxRetry) {
        return const SizedBox.shrink();
      }

      if (!_isLoaded || _nativeAd == null) {
        return Container(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            border: widget.border, // Sử dụng border tùy chỉnh nếu có
            borderRadius:
                widget.borderRadius, // Sử dụng borderRadius tùy chỉnh nếu có
          ),
          height: widget.height,
          alignment: Alignment.center,
          margin: widget.margin,
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

      return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          // Nếu có border tùy chỉnh thì dùng, nếu không thì dùng logic cũ với hasBorder
          border: widget.border ??
              (widget.hasBorder == true
                  ? const Border(
                      top: BorderSide(color: Color(0xFFDDDDDD), width: 1))
                  : null),
          borderRadius:
              widget.borderRadius, // Sử dụng borderRadius tùy chỉnh nếu có
        ),
        margin: widget.margin,
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        height: widget.height,
        child: AdWidget(
          key: ValueKey('ad_widget_${_nativeAd.hashCode}'),
          ad: _nativeAd!,
        ),
      );
    });
  }
}
