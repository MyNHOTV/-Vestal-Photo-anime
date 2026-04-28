import 'dart:async';
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'dynamic_theme_service.dart';

class RemoteConfigService extends GetxService {
  RemoteConfigService._internal();
  static final RemoteConfigService shared = RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  StreamSubscription<RemoteConfigUpdate>? _configUpdateSubscription;

  final RxBool isInitialized = false.obs;

  // ========= SINGLE JSON KEY =========
  static const String _keyAppConfig = 'app_config_v2';
  static const String _keyAppConfigTest = 'app_config_test_v2';

  static const String _keyMaintenanceMode = 'MaintenanceMode';
  static const String _keySurpriseMe = 'SurpriseMe';
  static const String _keyReverseStylesOrder = 'ReverseStylesOrder';
  static const String _keyMinLengthGenerate = 'MinLengthGenerate';
  static const String _keyMaxLengthGenerate = 'MaxLengthGenerate';
  static const String _keyPromptExample = 'PromptExample';
  static const String _keyGeneratePhase1Duration = 'GeneratePhase1Duration';
  static const String _keyGeneratePhase2MinDuration =
      'GeneratePhase2MinDuration';
  static const String _keyGeneratePhase2MaxDuration =
      'GeneratePhase2MaxDuration';
  static const String _keyEnableScreenProtection = 'EnableScreenProtection';
  static const String _keyAppTheme =
      'COLOR_PINK'; // 'COLOR_PINK' hoặc 'COLOR_BLUE'

  // ========= REACTIVE CONFIG STORAGE =========
  final RxMap<String, dynamic> _config = <String, dynamic>{}.obs;
  final RxBool adsEnabledRx = false.obs;

  // Non-JSON properties (Top level keys)
  final RxBool _maintenanceMode = false.obs;
  final RxString _surpriseMe = ''.obs;
  final RxBool _reverseStylesOrder = false.obs;
  final RxInt _minLengthGenerate = 10.obs;
  final RxInt _maxLengthGenerate = 500.obs;
  final RxString _promptExample = ''.obs;
  final RxInt _generatePhase1Duration = 30.obs;
  final RxInt _generatePhase2MinDuration = 60.obs;
  final RxInt _generatePhase2MaxDuration = 119.obs;
  final RxBool _enableScreenProtection = false.obs;

  // ========= DEFAULT NORMAL CONFIG =========
  static const String _defaultSurpriseMe =
      'Anime girl with long pink hair, school uniform, soft lighting';
  static const int _defaultMinLengthGenerate = 10;
  static const int _defaultMaxLengthGenerate = 500;
  static const String _defaultPromptExample =
      'Ex: Anime girl with long pink hair, school uniform, soft lighting';
  static const int _defaultGeneratePhase1Duration = 30;
  static const int _defaultGeneratePhase2MinDuration = 60;
  static const int _defaultGeneratePhase2MaxDuration = 119;
  static const bool _defaultMaintenanceMode = false;

  // ========= DEBUG CONFIG =========
  static final Map<String, dynamic> _debugConfig = {
    // ===== URLS =====
    'image_style_cloudfare':
        'https://pub-08a759829a13466fb4f02013d6018d53.r2.dev/style-debug.json',
    'image_style_cloudfare_v2':
        'https://pub-08a759829a13466fb4f02013d6018d53.r2.dev/resource-json/style-debug.json',
    'image_style_groups_cloudfare':
        'https://pub-08a759829a13466fb4f02013d6018d53.r2.dev/resource-json/category-debug.json',
  };

  // ========= RELEASE CONFIG =========
  static final Map<String, dynamic> _releaseConfig = {
    // ===== URLS =====
    'image_style_cloudfare': 'https://cdn.zi003.imgly.store/style-release.json',
    'image_style_cloudfare_v2':
        'https://cdn.zi003.imgly.store/resource-json/style-release.json',
    'image_style_groups_cloudfare':
        'https://cdn.zi003.imgly.store/resource-json/category-release.json',
  };

  // ========= INIT =========
  Future<void> init() async {
    try {
      debugPrint('🚀 Initializing Remote Config Service...');
      _remoteConfig = FirebaseRemoteConfig.instance;
      debugPrint('✅ FirebaseRemoteConfig instance created');

      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 20),
          minimumFetchInterval:
              kDebugMode ? Duration.zero : const Duration(minutes: 30),
        ),
      );
      debugPrint('✅ Config settings set');

      await _remoteConfig!.setDefaults({
        _keyAppConfig: jsonEncode(kDebugMode ? _debugConfig : _releaseConfig),
        _keySurpriseMe: _defaultSurpriseMe,
        _keyMinLengthGenerate: _defaultMinLengthGenerate,
        _keyMaxLengthGenerate: _defaultMaxLengthGenerate,
        _keyPromptExample: _defaultPromptExample,
        _keyGeneratePhase1Duration: _defaultGeneratePhase1Duration,
        _keyGeneratePhase2MinDuration: _defaultGeneratePhase2MinDuration,
        _keyGeneratePhase2MaxDuration: _defaultGeneratePhase2MaxDuration,
        _keyEnableScreenProtection: false,
        _keyMaintenanceMode: _defaultMaintenanceMode,
        _keyReverseStylesOrder: false,
      });
      debugPrint('✅ Default values set');

      // Load defaults immediately
      debugPrint('🔄 Loading default configs...');
      _loadConfigs();

      isInitialized.value = true;
      debugPrint('✅ Remote Config Service initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR in Remote Config init: $e');
      debugPrint('Stack trace: $stackTrace');
      isInitialized.value = true; // Vẫn set true để app không bị block
    }
  }

  void _listenRealtime() {
    try {
      if (_remoteConfig == null) {
        debugPrint('⚠️ RemoteConfig is null, skipping realtime listener');
        return;
      }

      _configUpdateSubscription?.cancel();

      _configUpdateSubscription = _remoteConfig!.onConfigUpdated.listen(
        (event) async {
          try {
            await _remoteConfig?.activate();
            _loadConfigs();
          } catch (e) {
            debugPrint('❌ Error in config update listener: $e');
          }
        },
        onError: (error) {
          debugPrint('❌ Error in config update stream: $error');
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('❌ Error setting up realtime listener: $e');
    }
  }

  void _loadConfigs() {
    try {
      debugPrint('🔄 Starting to load Remote Configs...');

      if (_remoteConfig == null) {
        debugPrint('❌ RemoteConfig is null, using default configs');
        _config.assignAll(kDebugMode ? _debugConfig : _releaseConfig);
        return;
      }

      // 1. Load JSON-based configs
      String raw = '';
      try {
        if (kDebugMode) {
          raw = _remoteConfig!.getString(_keyAppConfigTest);
          debugPrint(
              '📝 Test config key: $_keyAppConfigTest, value length: ${raw.length}');
          if (raw.isEmpty ||
              raw == _remoteConfig!.getAll()[_keyAppConfigTest]?.source) {
            raw = _remoteConfig!.getString(_keyAppConfig);
            debugPrint(
                '📝 Using main config key: $_keyAppConfig, value length: ${raw.length}');
          }
        } else {
          raw = _remoteConfig!.getString(_keyAppConfig);
          debugPrint(
              '📝 Main config key: $_keyAppConfig, value length: ${raw.length}');
        }
      } catch (e) {
        debugPrint('❌ Error getting config string: $e');
        raw = '';
      }

      if (raw.isNotEmpty) {
        try {
          raw = raw.trim();
          if (raw.isEmpty) {
            throw FormatException('Empty JSON string');
          }

          if (!raw.startsWith('{') && !raw.startsWith('[')) {
            throw FormatException(
                'Invalid JSON format: does not start with { or [');
          }

          debugPrint('📝 Parsing JSON config, length: ${raw.length}');
          final Map<String, dynamic> decoded = jsonDecode(raw);
          _config.assignAll(decoded);
          debugPrint('✅ JSON config parsed successfully');
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing app_config JSON: $e');
          debugPrint('Stack trace: $stackTrace');
          _config.assignAll(kDebugMode ? _debugConfig : _releaseConfig);
        }
      } else {
        debugPrint('⚠️ Config string is empty, using default configs');
        _config.assignAll(kDebugMode ? _debugConfig : _releaseConfig);
      }

      // 2. Load Top-level keys into Rx variables
      try {
        _maintenanceMode.value = _remoteConfig!.getBool(_keyMaintenanceMode);
        _surpriseMe.value = _remoteConfig!.getString(_keySurpriseMe).isEmpty
            ? _defaultSurpriseMe
            : _remoteConfig!.getString(_keySurpriseMe);
        _reverseStylesOrder.value =
            _remoteConfig!.getBool(_keyReverseStylesOrder);
        _minLengthGenerate.value = _remoteConfig!.getInt(_keyMinLengthGenerate);
        _maxLengthGenerate.value = _remoteConfig!.getInt(_keyMaxLengthGenerate);
        _promptExample.value =
            _remoteConfig!.getString(_keyPromptExample).isEmpty
                ? _defaultPromptExample
                : _remoteConfig!.getString(_keyPromptExample);
        _generatePhase1Duration.value =
            _remoteConfig!.getInt(_keyGeneratePhase1Duration);
        _generatePhase2MinDuration.value =
            _remoteConfig!.getInt(_keyGeneratePhase2MinDuration);
        _generatePhase2MaxDuration.value =
            _remoteConfig!.getInt(_keyGeneratePhase2MaxDuration);
        _enableScreenProtection.value =
            _remoteConfig!.getBool(_keyEnableScreenProtection);
        debugPrint('✅ Top-level keys loaded successfully');
      } catch (e) {
        debugPrint('❌ Error loading top-level keys: $e');
      }

      debugPrint('✅ Remote Configs loaded and updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR in _loadConfigs: $e');
      debugPrint('Stack trace: $stackTrace');
      _config.assignAll(kDebugMode ? _debugConfig : _releaseConfig);
    }
  }

  void _notifyThemeService() {
    try {
      final themeString = _remoteConfig!.getString(_keyAppTheme);
      if (themeString.isNotEmpty &&
          (themeString == 'COLOR_PINK' || themeString == 'COLOR_BLUE')) {
        if (Get.isRegistered<DynamicThemeService>()) {
          final themeService = Get.find<DynamicThemeService>();
          final theme = themeString == 'COLOR_PINK'
              ? DynamicTheme.COLOR_PINK
              : DynamicTheme.COLOR_BLUE;
          themeService.setThemeFromRemoteConfig(theme);
          debugPrint('🎨 Theme set from Remote Config: $themeString');
        } else {
          debugPrint(
              '⚠️ DynamicThemeService not registered yet, will set theme later');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error setting theme from Remote Config: $e');
    }
  }

  /// Get theme từ Remote Config
  String? get appThemeFromRemoteConfig {
    try {
      final themeString = _remoteConfig?.getString(_keyAppTheme);
      if (themeString != null &&
          themeString.isNotEmpty &&
          (themeString == 'COLOR_PINK' || themeString == 'COLOR_BLUE')) {
        return themeString;
      }
    } catch (e) {
      debugPrint('⚠️ Error getting theme from Remote Config: $e');
    }
    return null;
  }

  // ========= PUBLIC GETTERS =========
  bool get adsEnabled => false;

  RxBool get maintenanceMode => _maintenanceMode;
  bool get isInMaintenance => _maintenanceMode.value;

  RxMap<String, dynamic> get configRx => _config;

  // REACTIVE TOP-LEVEL GETTERS
  RxString get surpriseMeRx => _surpriseMe;
  String get surpriseMe => _surpriseMe.value;

  RxBool get reverseStylesOrder => _reverseStylesOrder;

  RxInt get minLengthGenerateRx => _minLengthGenerate;
  int get minLengthGenerate => _minLengthGenerate.value;

  RxInt get maxLengthGenerateRx => _maxLengthGenerate;
  int get maxLengthGenerate => _maxLengthGenerate.value;

  RxString get promptExampleRx => _promptExample;
  String get promptExample => _promptExample.value;

  RxInt get generatePhase1DurationRx => _generatePhase1Duration;
  int get generatePhase1Duration => _generatePhase1Duration.value;

  RxInt get generatePhase2MinDurationRx => _generatePhase2MinDuration;
  int get generatePhase2MinDuration => _generatePhase2MinDuration.value;

  RxInt get generatePhase2MaxDurationRx => _generatePhase2MaxDuration;
  int get generatePhase2MaxDuration => _generatePhase2MaxDuration.value;

  RxBool get enableScreenProtection => _enableScreenProtection;
  bool get shouldEnableScreenProtection => _enableScreenProtection.value;

  void dispose() {
    try {
      _configUpdateSubscription?.cancel();
      _configUpdateSubscription = null;
    } catch (e) {
      debugPrint('❌ Error canceling config subscription: $e');
    }
  }
}
