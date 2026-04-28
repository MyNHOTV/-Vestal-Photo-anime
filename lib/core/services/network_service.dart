import 'dart:async';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/export_constants.dart';
import '../widgets/app_icon.dart';

enum NetworkContext {
  splash, // Từ splash screen
  languageSelection, // Màn Choose Language
  obd, // Onboarding flow
  inApp, // Từ màn Home (in-app)
}

class NetworkService extends GetxService with WidgetsBindingObserver {
  static NetworkService get to => Get.find<NetworkService>();

  RxBool isConnected = true.obs;
  NetworkContext _currentContext =
      NetworkContext.splash; // Mặc định là splash vì app luôn bắt đầu từ splash
  bool _isInAppBlocked =
      false; // Flag để block các function khi mất mạng trong in-app

  bool _isDialogOpen = false;
  bool _isBuildingOverlay = false;
  int _retryCount = 0;
  static const int _maxRetries = 10;

  final Connectivity _connectivity = Connectivity();

  late final StreamSubscription<List<ConnectivityResult>>
      _connectivitySubscription;

  OverlayEntry? _overlay;

  // Timer để check internet liên tục khi có kết nối mạng nhưng chưa có internet
  Timer? _internetLoopTimer;
  bool _isLoopChecking = false;

  // Setter để set context
  void setNetworkContext(NetworkContext context) {
    _currentContext = context;
    debugPrint('🌐 NetworkService: Context set to $_currentContext');
  }

  // Getter để check xem có bị block không
  bool get isInAppBlocked => _isInAppBlocked;

  // Method để check và show popup nếu mất mạng trong in-app
  Future<bool> checkNetworkForInAppFunction() async {
    if (!isConnected.value) {
      _isInAppBlocked = true;
      _showNoConnectionDialog();
      return false;
    }
    _isInAppBlocked = false;
    return true;
  }

  // Method để check và show popup nếu mất mạng (dùng cho OBD và in-app)
  void checkAndShowNetworkDialog() {
    if (!isConnected.value && !_isDialogOpen) {
      debugPrint(
          '🌐 checkAndShowNetworkDialog - Current context: $_currentContext, isConnected: ${isConnected.value}');

      // Splash: không hiển thị popup
      if (_currentContext == NetworkContext.splash) {
        debugPrint('🌐 Splash: Skipping dialog');
        return;
      }

      // Language Selection: không hiển thị popup
      if (_currentContext == NetworkContext.languageSelection) {
        debugPrint('🌐 Language Selection: Skipping dialog');
        return;
      }

      // Set flag cho in-app nếu đang ở context in-app
      if (_currentContext == NetworkContext.inApp) {
        _isInAppBlocked = true;
      }

      debugPrint(
          '🌐 Showing network error dialog for context: $_currentContext');
      _showNoConnectionDialog();
    }
  }

  bool _hasAppBeenPaused = false;
  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _checkInitialConnection();
    _listenConnectionChanges();

    ever(isConnected, (connected) {
      if (!connected && !_isDialogOpen) {
        // Comment out services that don't exist
        // if (Get.isRegistered<TranslateController>()) {
        //   TranslateController.to.stopAudio();
        // }
        // TtsService.to.stop();
        if (Get.context != null) {
          FocusScope.of(Get.context!).unfocus();
        }

        debugPrint('🌐 Network lost - Current context: $_currentContext');

        // Splash: không hiển thị popup, chỉ skip ad và navigate (xử lý trong SplashScreen)
        if (_currentContext == NetworkContext.splash) {
          debugPrint(
              '🌐 Splash: Network lost, will skip ad and navigate (handled in SplashScreen)');
          return;
        }

        // Language Selection: không hiển thị popup, cho phép user chọn ngôn ngữ
        if (_currentContext == NetworkContext.languageSelection) {
          debugPrint(
              '🌐 Language Selection: Network lost, allowing user to select language');
          return;
        }

        // Set flag cho in-app nếu đang ở context in-app
        if (_currentContext == NetworkContext.inApp) {
          _isInAppBlocked = true;
        }

        debugPrint(
            '🌐 Showing network error dialog for context: $_currentContext');
        _showNoConnectionDialog();
      } else if (connected && _isDialogOpen) {
        hideBlockingOverlay();
        _isDialogOpen = false;
        _isInAppBlocked = false; // Reset flag khi có mạng lại
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _hasAppBeenPaused = true; // Đánh dấu app đã pause
    } else if (state == AppLifecycleState.resumed && _hasAppBeenPaused) {
      // Chỉ check khi thực sự resume từ background (không phải lần đầu khởi động)
      debugPrint("📱 App Resumed from background: Checking network status...");
      _checkInitialConnection();
      _hasAppBeenPaused = false; // Reset để tránh trigger lại không cần thiết
    }
  }

  Future<void> _checkInitialConnection() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.first == ConnectivityResult.none) {
      isConnected.value = false;
      _internetLoopTimer?.cancel();
    } else {
      // Kiểm tra thực sự có internet không
      final hasInternet = await checkOnline();
      isConnected.value = hasInternet;

      if (!hasInternet) {
        // Có mạng nhưng chưa có internet -> dialog vẫn hiện (theo logic của ever)
        // Bắt đầu loop check để auto ẩn dialog khi có internet
        _startInternetLoop();
      }
    }
  }

  void _listenConnectionChanges() {
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    _internetLoopTimer?.cancel();
    _isLoopChecking = false;

    if (result.first == ConnectivityResult.none) {
      isConnected.value = false;
    } else {
      final hasInternet = await checkOnline();
      isConnected.value = hasInternet;

      if (!hasInternet) {
        _startInternetLoop();
      }
    }
  }

  void _startInternetLoop() {
    _internetLoopTimer?.cancel();
    _isLoopChecking = false;

    _internetLoopTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_isLoopChecking) return;
      _isLoopChecking = true;
      try {
        final hasInternet = await checkOnline();
        if (hasInternet) {
          isConnected.value = true;
          timer.cancel(); // Dừng loop khi đã có mạng
        }
      } finally {
        _isLoopChecking = false;
      }
    });
  }

  Future<bool> checkOnline() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 3),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on Exception catch (_) {
      // Fallback strategies here if needed (e.g. 8.8.8.8)
      try {
        final socket = await Socket.connect('8.8.8.8', 53,
            timeout: const Duration(seconds: 3));
        socket.destroy();
        return true;
      } catch (_) {}
      return false;
    }
  }

  void _showNoConnectionDialog() {
    debugPrint(
        '🌐 _showNoConnectionDialog called - _overlay: $_overlay, _isDialogOpen: $_isDialogOpen, context: $_currentContext');
    if (_overlay != null) {
      debugPrint('⚠️ Overlay already exists, skipping');
      return;
    }
    _isDialogOpen = true;
    debugPrint('🌐 Setting _isDialogOpen = true, calling showBlockingOverlay');
    showBlockingOverlay();
  }

  void showBlockingOverlay() {
    if (_overlay != null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryShowOverlay();
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_isDialogOpen && _overlay == null && !_isBuildingOverlay) {
        _tryShowOverlay();
      }
    });
  }

  void _tryShowOverlay() {
    debugPrint(
        '🌐 _tryShowOverlay called - _isBuildingOverlay: $_isBuildingOverlay, isConnected: ${isConnected.value}, _isDialogOpen: $_isDialogOpen, _overlay: $_overlay, context: $_currentContext');
    if (_isBuildingOverlay) {
      debugPrint('⚠️ Already building overlay, skipping');
      return;
    }

    if (isConnected.value) {
      debugPrint('⚠️ Network connected, canceling overlay');
      _isDialogOpen = false;
      _retryCount = 0;
      _overlay = null;
      return;
    }

    if (!_isDialogOpen) {
      debugPrint('⚠️ Dialog not open, skipping');
      return;
    }
    if (_overlay != null) {
      debugPrint('⚠️ Overlay already exists, skipping');
      return;
    }

    _isBuildingOverlay = true;

    if (_retryCount >= _maxRetries) {
      debugPrint('❌ NetworkService: Max retries reached, giving up');
      _isDialogOpen = false;
      _retryCount = 0;
      _isBuildingOverlay = false;
      return;
    }

    // Thử nhiều cách để lấy context
    final context = Get.key.currentContext ?? Get.overlayContext ?? Get.context;

    if (context == null) {
      // Nếu context vẫn null, thử lại sau
      _retryCount++;
      debugPrint(
          '⚠️ NetworkService: Context not ready, retrying... ($_retryCount/$_maxRetries)');
      Future.delayed(const Duration(milliseconds: 500), () {
        _tryShowOverlay();
      });
      _isBuildingOverlay = false;
      return;
    }

    // Tìm NavigatorState và lấy overlay từ đó
    final navigator = Navigator.of(context, rootNavigator: true);
    final overlay = navigator.overlay;

    if (overlay == null) {
      _retryCount++;
      debugPrint(
          '⚠️ NetworkService: Overlay not found, retrying... ($_retryCount/$_maxRetries)');
      Future.delayed(const Duration(milliseconds: 500), () {
        _tryShowOverlay();
      });
      _isBuildingOverlay = false;
      return;
    }
    void _handleCancelButton() {
      debugPrint('🌐 User clicked Cancel - Current context: $_currentContext');

      if (_currentContext == NetworkContext.obd) {
        // OBD: Đóng popup và cho phép user tiếp tục vào Home
        hideBlockingOverlay();
        _isDialogOpen = false;
        // Không set _isInAppBlocked vì user có thể tiếp tục
        debugPrint('🌐 OBD: Allowing user to continue to Home');
      } else if (_currentContext == NetworkContext.inApp) {
        // In-app: Đóng popup nhưng giữ flag block, sẽ hiện lại khi click function
        hideBlockingOverlay();
        _isDialogOpen = false;
        // Giữ _isInAppBlocked = true để block các function
        _isInAppBlocked = true;
        debugPrint('🌐 In-app: Dialog closed but functions still blocked');
      }
    }

    Future<void> _openNetworkSettings() async {
      try {
        if (Platform.isAndroid) {
          await AppSettings.openAppSettings(type: AppSettingsType.wifi);
        } else if (Platform.isIOS) {
          await AppSettings.openAppSettings();
        }

        Future.delayed(const Duration(seconds: 1), () {
          _checkInitialConnection();
        });
      } catch (e) {
        debugPrint('❌ Error opening network settings: $e');
        await openAppSettings();
      }
    }

    // Reset retry count khi đã có overlay
    _retryCount = 0;

    _overlay = OverlayEntry(
      builder: (_) => Material(
        color: Colors.black.withOpacity(0.8),
        child: Stack(
          children: [
            IgnorePointer(
              child: Material(
                color: Colors.black.withOpacity(0.8),
              ),
            ),
            Center(
              child: Container(
                padding: const EdgeInsets.all(AppSizes.spacingM),
                margin: const EdgeInsets.all(AppSizes.spacingM),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(AppSizes.radiusM),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgIcon(
                      name: 'ic_warrning_network',
                      color: DynamicThemeService.shared.getPrimaryAccentColor(),
                    ),
                    const SizedBox(height: AppSizes.spacingM),
                    Text(
                      tr('network_error'),
                      style: kTextMediumtStyle.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.spacingL),
                    ElevatedButton(
                      onPressed: () async {
                        debugPrint(
                            '🌐 User clicked Settings, opening app settings...');
                        try {
                          _openNetworkSettings();
                          // Sau khi mở settings, đợi một chút rồi check lại mạng
                          Future.delayed(const Duration(seconds: 1), () {
                            _checkInitialConnection();
                          });
                        } catch (e) {
                          debugPrint('❌ Error opening app settings: $e');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            DynamicThemeService.shared.getPrimaryAccentColor(),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppSizes.radiusRound),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacingL,
                          vertical: AppSizes.spacingS,
                        ),
                      ),
                      child: Text(tr('open_settings')),
                    ),
                    const SizedBox(height: AppSizes.spacingS),
                    AppSecondaryButton(
                      onTap: () {
                        debugPrint('🌐 User clicked Cancel');
                        _handleCancelButton();
                      },
                      title: tr('cancel'),
                      idDialog: true,
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      overlay.insert(_overlay!);
      debugPrint('✅ NetworkService: Overlay displayed successfully');
      _isBuildingOverlay = false;
    } catch (e) {
      debugPrint('❌ NetworkService: Failed to show overlay: $e');
      _overlay = null;
      _isDialogOpen = false;
      _isBuildingOverlay = false;
      // Thử lại nếu lỗi
      _retryCount++;
      if (_retryCount < _maxRetries) {
        Future.delayed(const Duration(milliseconds: 500), () {
          _tryShowOverlay();
        });
      }
    }
  }

  void hideBlockingOverlay() {
    // Luôn reset cờ trạng thái để tránh giữ dialog khi overlay chưa kịp tạo
    _isDialogOpen = false;
    _retryCount = 0; // Reset retry count khi hide
    _isBuildingOverlay = false;
    _internetLoopTimer?.cancel();

    if (_overlay == null) return;
    _overlay!.remove();
    _overlay = null;
  }

  // Method để reset context về in-app (gọi khi vào Home)
  void resetToInAppContext() {
    _currentContext = NetworkContext.inApp;
    debugPrint('🌐 NetworkService: Context reset to in-app');
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _internetLoopTimer?.cancel();
    _connectivitySubscription.cancel();
    hideBlockingOverlay();
    super.onClose();
  }
}
