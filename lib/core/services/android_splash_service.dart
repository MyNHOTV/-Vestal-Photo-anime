import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'dynamic_theme_service.dart';

/// Service để quản lý Android native splash screen
/// Lưu ý: Android native splash chỉ có thể thay đổi khi app restart
class AndroidSplashService extends GetxService {
  AndroidSplashService._internal();
  static final AndroidSplashService shared = AndroidSplashService._internal();

  static const MethodChannel _channel =
      MethodChannel('com.ai.anime.art.generator.photo.create.aiart/splash');

  /// Lưu theme preference để Android native splash có thể đọc khi app khởi động
  Future<void> saveThemeForNextLaunch() async {
    try {
      final theme = DynamicThemeService.shared.currentTheme.value;
      await _channel.invokeMethod('saveTheme', {'theme': theme.name});
      debugPrint('💾 Saved theme for next Android splash: ${theme.name}');
    } catch (e) {
      debugPrint('⚠️ Error saving theme for Android splash: $e');
    }
  }

  /// Lấy theme hiện tại từ Android (được set khi app khởi động)
  Future<String?> getSavedTheme() async {
    try {
      final theme = await _channel.invokeMethod<String>('getTheme');
      return theme;
    } catch (e) {
      debugPrint('⚠️ Error getting theme from Android: $e');
      return null;
    }
  }

  /// Restart app để áp dụng native splash screen mới
  Future<void> restartApp() async {
    try {
      await _channel.invokeMethod('restartApp');
      debugPrint('🔄 App restart requested');
    } catch (e) {
      debugPrint('⚠️ Error restarting app: $e');
      // Fallback: exit app và để user mở lại
      SystemNavigator.pop();
    }
  }
}
