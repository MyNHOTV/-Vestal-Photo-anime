import 'dart:async';
import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/connectivity_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/storage/local_storage_service.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  bool _hasNavigated = false;
  StreamSubscription<bool>? _networkSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  VideoPlayerController? _videoController;
  late final AnimationController _progressController;
  bool _isVideoInitialized = false;

  Future<void>? _initServicesFuture;
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    AnalyticsService.shared.logEvent(name: 'screen_splash_show');
    if (Get.isRegistered<NetworkService>()) {
      NetworkService.to.setNetworkContext(NetworkContext.splash);
    }

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..forward();

    _initServicesFuture = _initializeServices();
    _initVideo();

    _startSplashFlow();
  }

  Future<void> _initVideo() async {
    debugPrint('🎬 SplashScreen: Initializing video...');
    try {
      _videoController = VideoPlayerController.asset(
        'assets/icons/splash_video.mp4',
      )
        ..setLooping(true)
        ..setVolume(0);

      _videoController!.addListener(_videoListener);

      // Tăng timeout lên 10 giây vì file video khá lớn (8.6MB)
      await _videoController!.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⏰ SplashScreen: Video initialization timeout');
          throw TimeoutException('Video initialization timeout');
        },
      );

      debugPrint('✅ SplashScreen: Video initialized successfully');

      if (!mounted) {
        debugPrint('⚠️ SplashScreen: Widget unmounted after video init');
        _videoController?.removeListener(_videoListener);
        _videoController?.dispose();
        _videoController = null;
        return;
      }

      if (_videoController!.value.hasError) {
        debugPrint(
            '❌ SplashScreen: Video error after init: ${_videoController!.value.errorDescription}');
        _videoController?.removeListener(_videoListener);
        _videoController?.dispose();
        _videoController = null;
        _isVideoInitialized = false;
        if (mounted) setState(() {});
        return;
      }

      _isVideoInitialized = true;
      if (mounted) {
        setState(() {});
        _videoController!.play();
        debugPrint('▶️ SplashScreen: Video playing');
      }
    } catch (e) {
      debugPrint('❌ SplashScreen: Error initializing video: $e');
      _videoController?.removeListener(_videoListener);
      _videoController?.dispose();
      _videoController = null;
      _isVideoInitialized = false;
      if (mounted) setState(() {});
    }
  }

  void _videoListener() {
    if (_videoController == null) return;

    // Kiểm tra lỗi trong quá trình phát
    if (_videoController!.value.hasError) {
      debugPrint(
          'Video playback error: ${_videoController!.value.errorDescription}');
      _isVideoInitialized = false;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _initializeServices() async {
    debugPrint('SplashScreen: _initializeServices starting...');
    await RemoteConfigService.shared.init();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    debugPrint('SplashScreen: _initializeServices completed.');
  }

  Future<void> _startSplashFlow() async {
    // Đợi services sẵn sàng với timeout để không bị kẹt
    try {
      if (_initServicesFuture != null) {
        await _initServicesFuture!.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            debugPrint('⏰ SplashScreen: Services initialization timeout');
          },
        );
      }
    } catch (e) {
      debugPrint('⚠️ SplashScreen: Error waiting for services: $e');
    }

    // Đợi thêm một chút để đảm bảo UX
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted || _hasNavigated) return;

    // Timeout tổng cho cả màn splash (ví dụ tối đa 20s phải vào app)
    Timer(const Duration(seconds: 10), () {
      if (mounted && !_hasNavigated) {
        debugPrint('⏰ SplashScreen: Total splash timeout reached - navigating');
        _navigate();
      }
    });

    if (Get.isRegistered<NetworkService>()) {
      if (!NetworkService.to.isConnected.value) {
        debugPrint('🌐 SplashScreen: No internet, navigating...');
        _navigate();
        return;
      }
    } else if (!ConnectivityService.shared.isConnected) {
      debugPrint(
          '🌐 SplashScreen: No connectivity service connection, navigating...');
      _listenForNetworkConnection();
      return;
    }

    _navigate();
  }

  void _navigate() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    debugPrint('🚀 SplashScreen: Navigating to next screen');

    final hasCompletedOnboarding = LocalStorageService.shared.get<bool>(
      'has_completed_onboarding',
      defaultValue: false,
    );

    if (hasCompletedOnboarding == true) {
      Get.offAllNamed(AppRoutes.mainTabar);
    } else {
      Get.offAllNamed(
        AppRoutes.languageSelection,
        arguments: {'isFromOnboarding': true},
      );
    }
  }

  void _listenForNetworkConnection() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        ConnectivityService.shared.connectivityStatus.listen(
      (results) {
        if (ConnectivityService.shared.isConnected &&
            mounted &&
            !_hasNavigated) {
          debugPrint('🌐 SplashScreen: Network restored');
          _connectivitySubscription?.cancel();
          if (Get.isDialogOpen == true) {
            Get.back();
          }
          _navigate();
        }
      },
    );
  }

  @override
  void dispose() {
    _networkSubscription?.cancel();
    _connectivitySubscription?.cancel();
    _progressController.dispose();
    _videoController?.removeListener(_videoListener);
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    super.dispose();
  }

  Widget _buildVideoBackground() {
    // Hiển thị video nếu đã khởi tạo thành công
    if (_videoController != null &&
        _isVideoInitialized &&
        _videoController!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    // Fallback về màn đen nếu video chưa sẵn sàng
    return Container(color: Colors.black);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.colorBlack,
      body: Stack(
        children: [
          Positioned.fill(child: _buildVideoBackground()),
          Center(
            child: Container(
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/image/new_logo.png',
                  width: 160,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
          Positioned(
            left: AppSizes.spacingL,
            right: AppSizes.spacingL,
            bottom: AppSizes.spacingXL,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Text(tr('this_action_may_contain_advertising'),
                      style: kBricolageRegularStyle.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF7259F1))),
                  const SizedBox(
                    height: 20,
                  ),
                  Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(1000),
                        border:
                            Border.all(color: AppColors.color7259F1, width: 2)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return LinearProgressIndicator(
                            value: _progressController.value,
                            minHeight: 7,
                            backgroundColor: Colors.white,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.color7259F1),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
