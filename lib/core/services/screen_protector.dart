import 'dart:io' show Platform;

import 'package:get/get.dart';
import 'package:screen_protector/screen_protector.dart';

class ScreenProtectorService extends GetxService {
  ScreenProtectorService._internal();
  static final ScreenProtectorService shared =
      ScreenProtectorService._internal();

  bool _isProtected = false;
  bool _isScreenshotProtected = false;

  /// Bật chặn chụp màn hình
  Future<void> enableProtection() async {
    if (_isProtected) return;

    try {
      // Chặn data leakage (screen recording)
      await ScreenProtector.protectDataLeakageOn();

      // Chặn screenshot - Android
      if (Platform.isAndroid) {
        await ScreenProtector.preventScreenshotOn();
        _isScreenshotProtected = true;
        print('Screenshot protection enabled (Android)');
      }

      // Chặn screenshot - iOS
      if (Platform.isIOS) {
        await ScreenProtector.preventScreenshotOn();
        _isScreenshotProtected = true;
        print('Screenshot protection enabled (iOS)');
      }

      _isProtected = true;
      print('Screen protection enabled');
    } catch (e) {
      print('Error enabling screen protection: $e');
      _isProtected = false;
      _isScreenshotProtected = false;
    }
  }

  /// Tắt chặn chụp màn hình
  Future<void> disableProtection() async {
    if (!_isProtected) return;

    try {
      // Tắt data leakage protection
      await ScreenProtector.protectDataLeakageOff();

      // Tắt screenshot protection - Android
      if (Platform.isAndroid && _isScreenshotProtected) {
        await ScreenProtector.preventScreenshotOff();
        _isScreenshotProtected = false;
        print('Screenshot protection disabled (Android)');
      }

      // Tắt screenshot protection - iOS
      if (Platform.isIOS && _isScreenshotProtected) {
        await ScreenProtector.preventScreenshotOff();
        _isScreenshotProtected = false;
        print('Screenshot protection disabled (iOS)');
      }

      _isProtected = false;
      print('Screen protection disabled');
    } catch (e) {
      print('Error disabling screen protection: $e');
    }
  }

  /// Kiểm tra trạng thái protection
  bool get isProtected => _isProtected;
  bool get isScreenshotProtected => _isScreenshotProtected;

  /// Bật/tắt protection dựa trên điều kiện
  Future<void> setProtection(bool enable) async {
    if (enable) {
      await enableProtection();
    } else {
      await disableProtection();
    }
  }
}
