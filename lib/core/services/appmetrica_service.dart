import 'package:flutter/foundation.dart';
import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:decimal/decimal.dart';

class AppMetricaService {
  AppMetricaService._internal();
  static final AppMetricaService shared = AppMetricaService._internal();

  bool _isInitialized = false;

  /// Khởi tạo AppMetrica
  Future<void> init({
    required String apiKey,
  }) async {
    if (_isInitialized) return;

    try {
      final config = AppMetricaConfig(
        apiKey,
        sessionTimeout: 10,
        firstActivationAsUpdate: false,
        locationTracking: false,
        crashReporting: true,
        logs: kDebugMode,
      );

      await AppMetrica.activate(config);
      _isInitialized = true;
      if (kDebugMode) print('✅ AppMetrica initialized');
    } catch (e) {
      if (kDebugMode) print('❌ AppMetrica init error: $e');
    }
  }

  /// Convert Map<String, dynamic> to Map<String, Object>
  Map<String, Object>? _convertParameters(Map<String, dynamic>? params) {
    if (params == null) return null;

    return params.map((key, value) {
      // AppMetrica accepts: String, int, double, bool, List, Map
      if (value is String ||
          value is int ||
          value is double ||
          value is bool ||
          value is List ||
          value is Map) {
        return MapEntry(key, value as Object);
      }
      // Convert other types to String
      return MapEntry(key, value.toString());
    });
  }

  /// Log event
  Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {
    if (!_isInitialized) return;

    try {
      if (params != null && params.isNotEmpty) {
        final convertedParams = _convertParameters(params);
        await AppMetrica.reportEventWithMap(name, convertedParams);
      } else {
        await AppMetrica.reportEvent(name);
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ AppMetrica log error: $e');
    }
  }

  /// Set user ID
  Future<void> setUserId(String userId) async {
    if (!_isInitialized) return;

    try {
      await AppMetrica.setUserProfileID(userId);
    } catch (e) {
      if (kDebugMode) print('⚠️ AppMetrica setUserId error: $e');
    }
  }

  /// Report ad revenue
  ///
  /// [amount] - Số tiền revenue
  /// [currency] - Currency code (ví dụ: 'USD', 'VND')
  /// [adNetwork] - Ad network name (ví dụ: 'admob', 'mediation_adapter_class_name')
  /// [adUnitId] - Ad unit ID
  /// [adPlacement] - Placement ID (ví dụ: 'inter_info', 'banner_home')
  /// [adType] - Loại ad: 'Interstitial', 'Banner', 'Rewarded', 'Native', 'AppOpen'
  Future<void> reportAdRevenue({
    required double amount,
    required String currency,
    String? adNetwork,
    String? adUnitId,
    String? adPlacement,
    String? adType,
  }) async {
    if (!_isInitialized) return;

    try {
      // Convert adType string to AppMetricaAdType enum
      AppMetricaAdType? appMetricaAdType;
      if (adType != null) {
        switch (adType.toLowerCase()) {
          case 'interstitial':
            appMetricaAdType = AppMetricaAdType.interstitial;
            break;
          case 'banner':
            appMetricaAdType = AppMetricaAdType.banner;
            break;
          case 'rewarded':
            appMetricaAdType = AppMetricaAdType.rewarded;
            break;
          case 'native':
            appMetricaAdType = AppMetricaAdType.native;
            break;
          case 'appopen':
          case 'app_open':
            appMetricaAdType = AppMetricaAdType.appOpen;
            break;
          default:
            appMetricaAdType = AppMetricaAdType.unknown;
        }
      }

      final adRevenueData = AppMetricaAdRevenue(
        adRevenue: Decimal.parse(amount.toStringAsFixed(6)),
        currency: currency,
        adType: appMetricaAdType,
        adNetwork: adNetwork,
        adUnitId: adUnitId,
        adPlacementId: adPlacement,
        adPlacementName: adPlacement,
      );

      await AppMetrica.reportAdRevenue(adRevenueData);

      if (kDebugMode) {
        print(
            '✅ AppMetrica Ad Revenue reported: $amount $currency ($adType) - Network: $adNetwork');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ AppMetrica reportAdRevenue error: $e');
    }
  }

  bool get isInitialized => _isInitialized;
}
