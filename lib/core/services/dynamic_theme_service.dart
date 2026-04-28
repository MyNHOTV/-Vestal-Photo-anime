import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../storage/local_storage_service.dart';
import 'android_splash_service.dart';

enum DynamicTheme {
  COLOR_PINK,
  COLOR_BLUE,
}

class DynamicThemeService extends GetxService {
  DynamicThemeService._internal();
  static final DynamicThemeService shared = DynamicThemeService._internal();

  final Rx<DynamicTheme> currentTheme = DynamicTheme.COLOR_PINK.obs;
  final Random _random = Random();

  static const String _themeKey = 'last_dynamic_theme';

  @override
  void onInit() {
    super.onInit();
    // Load theme mặc định khi khởi động
    _loadDefaultTheme();
  }

  Future<void> _loadDefaultTheme() async {
    // Ưu tiên 1: Lấy theme từ Android (nếu có)
    try {
      final androidTheme = await AndroidSplashService.shared.getSavedTheme();
      if (androidTheme != null) {
        final theme = DynamicTheme.values.firstWhere(
          (t) => t.name == androidTheme,
          orElse: () => DynamicTheme.COLOR_PINK,
        );
        currentTheme.value = theme;
        LocalStorageService.shared.put(_themeKey, theme.name);
        debugPrint('🎨 Loaded theme from Android: ${theme.name}');
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Error loading theme from Android: $e');
    }

    // Ưu tiên 2: Lấy từ LocalStorage
    final savedTheme = LocalStorageService.shared.get<String>(
      _themeKey,
      defaultValue: DynamicTheme.COLOR_PINK.name,
    );

    currentTheme.value = DynamicTheme.values.firstWhere(
      (theme) => theme.name == savedTheme,
      orElse: () => DynamicTheme.COLOR_PINK,
    );

    // Note: Remote Config sẽ override theme sau khi load xong (trong RemoteConfigService._notifyThemeService)
  }

  /// Switch theme khi show ads (toggle giữa 2 theme)
  void switchThemeForAd() {
    // Toggle giữa pink và blue
    currentTheme.value = currentTheme.value == DynamicTheme.COLOR_PINK
        ? DynamicTheme.COLOR_BLUE
        : DynamicTheme.COLOR_PINK;

    LocalStorageService.shared.put(_themeKey, currentTheme.value.name);
    debugPrint('🎨 Dynamic theme switched to: ${currentTheme.value.name}');

    // Lưu theme cho Android native splash (sẽ áp dụng khi app restart)
    try {
      AndroidSplashService.shared.saveThemeForNextLaunch();
    } catch (e) {
      debugPrint('⚠️ Error saving theme for Android splash: $e');
    }
  }

  /// Random theme (50/50 giữa pink và blue)
  void randomizeThemeForAd() {
    final newTheme =
        _random.nextBool() ? DynamicTheme.COLOR_PINK : DynamicTheme.COLOR_BLUE;

    currentTheme.value = newTheme;
    LocalStorageService.shared.put(_themeKey, newTheme.name);
    debugPrint('🎨 Dynamic theme randomized to: ${newTheme.name}');
  }

  /// Set theme cụ thể
  void setTheme(DynamicTheme theme) {
    currentTheme.value = theme;
    LocalStorageService.shared.put(_themeKey, theme.name);

    // Lưu theme cho Android native splash (async, không block UI)
    AndroidSplashService.shared.saveThemeForNextLaunch().catchError((e) {
      debugPrint('⚠️ Error saving theme for Android splash: $e');
    });
  }

  /// Set theme từ Remote Config (không lưu vào LocalStorage để Remote Config có thể override)
  void setThemeFromRemoteConfig(DynamicTheme theme) {
    currentTheme.value = theme;
    // Không lưu vào LocalStorage vì Remote Config có thể thay đổi
    debugPrint('🎨 Theme set from Remote Config: ${theme.name}');
  }

  /// Get splash screen asset path based on theme
  String getSplashScreenAsset() {
    switch (currentTheme.value) {
      case DynamicTheme.COLOR_PINK:
        return 'assets/icons/splash_screen.png';
      case DynamicTheme.COLOR_BLUE:
        return 'assets/icons/splash_screen.png';
    }
  }

  /// Get button gradient colors based on theme
  List<Color> getButtonGradientColors() {
    switch (currentTheme.value) {
      case DynamicTheme.COLOR_PINK:
        return [
          AppColors.color6657F0,
          AppColors.colorF46EF8,
        ];
      case DynamicTheme.COLOR_BLUE:
        return [
          AppColors.primaryDark,
          AppColors.primary,
          AppColors.primaryLight,
          AppColors.primary,
          AppColors.primaryDark,
        ];
    }
  }

  /// Get secondary button gradient colors
  List<Color> getSecondaryButtonGradientColors() {
    switch (currentTheme.value) {
      case DynamicTheme.COLOR_PINK:
        // Theme hồng
        return [
          AppColors.colorFF00AE,
          AppColors.colorAD01C3,
          AppColors.color600088,
        ];
      case DynamicTheme.COLOR_BLUE:
        // Theme xanh dương nhạt
        return [
          AppColors.primary,
          AppColors.primaryLight,
          AppColors.primaryDark,
        ];
    }
  }

  /// Get loading spinner color
  Color getLoadingSpinnerColor() {
    switch (currentTheme.value) {
      case DynamicTheme.COLOR_PINK:
        return AppColors.colorFF00AE;
      case DynamicTheme.COLOR_BLUE:
        return AppColors.primaryLight;
    }
  }

  /// Get primary accent color
  Color getPrimaryAccentColor() {
    switch (currentTheme.value) {
      case DynamicTheme.COLOR_PINK:
        return AppColors.color7259F1;
      case DynamicTheme.COLOR_BLUE:
        return AppColors.primaryLight;
    }
  }
  //dot gradient colors

  List<Color> getDotGradientColors() {
    switch (currentTheme.value) {
      case DynamicTheme.COLOR_PINK:
        return [
          AppColors.color6C1BF7,
          AppColors.colorF58AED,
        ];
      case DynamicTheme.COLOR_BLUE:
        return [
          AppColors.color6C1BF7,
          AppColors.colorF58AED,
        ];
    }
  }

  /// Get primary accent color
  Color getActiveColor() {
    switch (currentTheme.value) {
      case DynamicTheme.COLOR_PINK:
        return AppColors.color7259F1;
      case DynamicTheme.COLOR_BLUE:
        return AppColors.primaryLight;
    }
  }

  Color getActiveColorADS() {
    switch (currentTheme.value) {
      case DynamicTheme.COLOR_PINK:
        return AppColors.colorAE8CF5;
      case DynamicTheme.COLOR_BLUE:
        return AppColors.primaryLight;
    }
  }
}
