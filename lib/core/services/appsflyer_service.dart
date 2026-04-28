import 'package:flutter/foundation.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';

class AppsFlyerService {
  AppsFlyerService._internal();
  static final AppsFlyerService shared = AppsFlyerService._internal();

  AppsflyerSdk? _appsflyerSdk;
  bool _isInitialized = false;

  /// Khởi tạo AppsFlyer
  Future<void> init({
    required String devKey,
    required String appId,
  }) async {
    if (_isInitialized) return;

    try {
      _appsflyerSdk = AppsflyerSdk(
        AppsFlyerOptions(
          afDevKey: devKey,
          appId: appId,
          showDebug: kDebugMode,
          timeToWaitForATTUserAuthorization: 60,
        ),
      );

      await _appsflyerSdk!.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      _isInitialized = true;
      if (kDebugMode) print('✅ AppsFlyer initialized');
    } catch (e) {
      if (kDebugMode) print('❌ AppsFlyer init error: $e');
    }
  }

  /// Log event
  Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {
    if (!_isInitialized || _appsflyerSdk == null) return;

    try {
      await _appsflyerSdk!.logEvent(name, params ?? {});
    } catch (e) {
      if (kDebugMode) print('⚠️ AppsFlyer log error: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    if (!_isInitialized || _appsflyerSdk == null) return;

    try {
      _appsflyerSdk?.setCustomerUserId(userId);
    } catch (e) {
      if (kDebugMode) print('⚠️ AppsFlyer setUserId error: $e');
    }
  }

  bool get isInitialized => _isInitialized;
}
