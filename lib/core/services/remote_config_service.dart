import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
  static const String _keyInterInterval = 'inter_interval';
  static const String _keyInterDetailClickThreshold =
      'inter_detail_click_threshold';
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
  final RxBool adsEnabledRx = true.obs;

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
  static const int _defaultInterInterval = 30;
  static const int _defaultInterDetailClickThreshold = 3;

  // ========= DEBUG CONFIG (TEST ADS) =========
  static final Map<String, dynamic> _debugConfig = {
    // ===== GLOBAL =====
    'ads_enabled': true,

    // ===== APP OPEN (FLAGS) =====
    'app_open_enabled': true,
    'app_open_resume_enabled': true,
    'app_open_2floor_enabled': true,
    'app_open_resume_2floor_enabled': true,

    // ===== BANNER (FLAGS) =====
    'banner_splash_enabled': true,
    'banner_home_enabled': true,
    'banner_history_enabled': true,
    'banner_style_enabled': true,
    'banner_adaptive_generate_enabled': true,
    'banner_change_style_enabled': true,
    'banner_change_image_enabled': true,
    'banner_change_ratio_enabled': true,
    'banner_processing_enabled': true,
    'banner_splash_2floor_enabled': true,

    // ===== INTER (FLAGS) =====
    'inter_splash_enabled': true,
    'inter_style_enabled': true,
    'inter_change_enabled': true,
    'inter_processing_enabled': true,
    'inter_detail_enabled': true,
    'inter_new_enabled': true,
    'inter_new_2floor_enabled': true,

    // ===== REWARD (FLAGS) =====
    'reward_save_1_enabled': true,
    'reward_share_1_enabled': true,
    'reward_save_3_enabled': true,
    'reward_share_3_enabled': true,
    'reward_quick_generate_enabled': true,
    'reward_quick_generate_2floor_enabled': true,

    // ===== NATIVE (FLAGS) =====
    'native_language_enabled': true,
    'native_language_2floor_enabled': true,
    'native_language_select_enabled': true,
    'native_language_select_2floor_enabled': true,
    'native_onboarding_1_enabled': true,
    'native_onboarding_1_2floor_enabled': true,
    'native_onboarding_2_enabled': true,
    'native_onboarding_2_2floor_enabled': true,
    'native_onboarding_3_enabled': true,
    'native_onboarding_3_2floor_enabled': true,
    'native_onboarding_full_enabled': true,
    'native_onboarding_full_2floor_enabled': true,
    'native_style_enabled': true,
    'native_history_enabled': true,
    'native_image_enabled': true,
    'native_info_enabled': true,
    'native_home_enabled': true,
    'native_slider_enabled': true,
    'native_choose_style_enabled': true,
    'native_upload_image_enabled': true,
    'native_upload_image_select_enabled': true,
    'native_generation_enabled': true,
    'native_processing_enabled': true,

    // ===== TUNING =====
    'inter_interval': 45,
    'inter_detail_click_threshold': 3,
    'ad_count_save_with_watermark': 1,
    'ad_count_save_without_watermark': 3,
    'ad_count_share_with_watermark': 1,
    'ad_count_share_without_watermark': 3,
    'ad_count_daily_limit_generate': 1,

    // ===== URLS =====
    'image_style_cloudfare':
        'https://pub-08a759829a13466fb4f02013d6018d53.r2.dev/style-debug.json',
    'image_style_cloudfare_v2':
        'https://pub-08a759829a13466fb4f02013d6018d53.r2.dev/resource-json/style-debug.json',
    'image_style_groups_cloudfare':
        'https://pub-08a759829a13466fb4f02013d6018d53.r2.dev/resource-json/category-debug.json',

    // ===== APP OPEN (IDs) =====
    'android_app_open': 'ca-app-pub-3940256099942544/9257395921',
    'ios_app_open': 'ca-app-pub-3940256099942544/5575463023',
    'android_app_open_2floor': 'ca-app-pub-3940256099942544/9257395921',
    'ios_app_open_2floor': 'ca-app-pub-3940256099942544/5575463023',
    'android_app_open_resume': 'ca-app-pub-3940256099942544/9257395921',
    'ios_app_open_resume': 'ca-app-pub-3940256099942544/5575463023',
    'android_app_open_resume_2floor': 'ca-app-pub-3940256099942544/9257395921',
    'ios_app_open_resume_2floor': 'ca-app-pub-3940256099942544/5575463023',

    // ===== BANNER (IDs) =====
    'android_banner_splash': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_splash': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_home': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_home': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_history': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_history': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_style': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_style': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_adaptive_generate':
        'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_adaptive_generate': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_change_style': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_change_style': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_change_image': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_change_image': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_change_ratio': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_change_ratio': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_processing': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_processing': 'ca-app-pub-3940256099942544/2934735716',
    'android_banner_splash_2floor': 'ca-app-pub-3940256099942544/6300978111',
    'ios_banner_splash_2floor': 'ca-app-pub-3940256099942544/2934735716',

    // ===== INTER (IDs) =====
    'android_inter_style': 'ca-app-pub-3940256099942544/1033173712',
    'ios_inter_style': 'ca-app-pub-3940256099942544/4411468910',
    'android_inter_change': 'ca-app-pub-3940256099942544/1033173712',
    'ios_inter_change': 'ca-app-pub-3940256099942544/4411468910',
    'android_inter_processing': 'ca-app-pub-3940256099942544/1033173712',
    'ios_inter_processing': 'ca-app-pub-3940256099942544/4411468910',
    'android_inter_detail': 'ca-app-pub-3940256099942544/1033173712',
    'ios_inter_detail': 'ca-app-pub-3940256099942544/4411468910',
    'android_inter_new': 'ca-app-pub-3940256099942544/1033173712',
    'ios_inter_new': 'ca-app-pub-3940256099942544/4411468910',
    'android_inter_new_2floor': 'ca-app-pub-3940256099942544/1033173712',
    'ios_inter_new_2floor': 'ca-app-pub-3940256099942544/4411468910',

    // ===== REWARD (IDs) =====
    'android_reward_save_1': 'ca-app-pub-3940256099942544/5224354917',
    'ios_reward_save_1': 'ca-app-pub-3940256099942544/1712485313',
    'android_reward_share_1': 'ca-app-pub-3940256099942544/5224354917',
    'ios_reward_share_1': 'ca-app-pub-3940256099942544/1712485313',
    'android_reward_save_3': 'ca-app-pub-3940256099942544/5224354917',
    'ios_reward_save_3': 'ca-app-pub-3940256099942544/1712485313',
    'android_reward_share_3': 'ca-app-pub-3940256099942544/5224354917',
    'ios_reward_share_3': 'ca-app-pub-3940256099942544/1712485313',
    'android_reward_quick_generate': 'ca-app-pub-3940256099942544/5224354917',
    'ios_reward_quick_generate': 'ca-app-pub-3940256099942544/1712485313',
    'android_reward_quick_generate_2floor':
        'ca-app-pub-3940256099942544/5224354917',
    'ios_reward_quick_generate_2floor':
        'ca-app-pub-3940256099942544/1712485313',

    // ===== NATIVE (IDs) =====
    'android_native_language': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_language': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_language_2floor': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_language_2floor': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_language_select': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_language_select': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_language_select_2floor':
        'ca-app-pub-3940256099942544/2247696110',
    'ios_native_language_select_2floor':
        'ca-app-pub-3940256099942544/3986624511',
    'android_native_onboarding_1': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_onboarding_1': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_onboarding_1_2floor':
        'ca-app-pub-3940256099942544/2247696110',
    'ios_native_onboarding_1_2floor': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_onboarding_2': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_onboarding_2': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_onboarding_2_2floor':
        'ca-app-pub-3940256099942544/2247696110',
    'ios_native_onboarding_2_2floor': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_onboarding_3': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_onboarding_3': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_onboarding_3_2floor':
        'ca-app-pub-3940256099942544/2247696110',
    'ios_native_onboarding_3_2floor': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_onboarding_full': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_onboarding_full': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_onboarding_full_2floor':
        'ca-app-pub-3940256099942544/2247696110',
    'ios_native_onboarding_full_2floor':
        'ca-app-pub-3940256099942544/3986624511',
    'android_native_history': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_history': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_image': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_image': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_info': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_info': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_style': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_style': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_home': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_home': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_slider': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_slider': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_choose_style': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_choose_style': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_upload_image': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_upload_image': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_upload_image_select':
        'ca-app-pub-3940256099942544/2247696110',
    'ios_native_upload_image_select': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_generation': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_generation': 'ca-app-pub-3940256099942544/3986624511',
    'android_native_processing': 'ca-app-pub-3940256099942544/2247696110',
    'ios_native_processing': 'ca-app-pub-3940256099942544/3986624511',
  };

  // ========= RELEASE CONFIG (PRODUCTION ADS) =========
  static final Map<String, dynamic> _releaseConfig = {
    // ===== GLOBAL =====
    'ads_enabled': true,

    // ===== APP OPEN (FLAGS) =====
    'app_open_enabled': true,
    'app_open_resume_enabled': true,
    'app_open_2floor_enabled': true,
    'app_open_resume_2floor_enabled': true,

    // ===== BANNER (FLAGS) =====
    'banner_splash_enabled': true,
    'banner_home_enabled': true,
    'banner_history_enabled': true,
    'banner_style_enabled': true,
    'banner_adaptive_generate_enabled': true,
    'banner_change_style_enabled': true,
    'banner_change_image_enabled': true,
    'banner_change_ratio_enabled': true,
    'banner_processing_enabled': true,
    'banner_splash_2floor_enabled': true,

    // ===== INTER (FLAGS) =====
    'inter_style_enabled': true,
    'inter_change_enabled': true,
    'inter_processing_enabled': true,
    'inter_detail_enabled': true,
    'inter_new_enabled': true,
    'inter_new_2floor_enabled': true,

    // ===== REWARD (FLAGS) =====
    'reward_save_1_enabled': true,
    'reward_share_1_enabled': true,
    'reward_save_3_enabled': true,
    'reward_share_3_enabled': true,
    'reward_quick_generate_enabled': true,
    'reward_quick_generate_2floor_enabled': true,

    // ===== NATIVE (FLAGS) =====
    'native_language_enabled': true,
    'native_language_2floor_enabled': true,
    'native_language_select_enabled': true,
    'native_language_select_2floor_enabled': true,
    'native_onboarding_1_enabled': true,
    'native_onboarding_1_2floor_enabled': true,
    'native_onboarding_2_enabled': true,
    'native_onboarding_2_2floor_enabled': true,
    'native_onboarding_3_enabled': true,
    'native_onboarding_3_2floor_enabled': true,
    'native_onboarding_full_enabled': true,
    'native_onboarding_full_2floor_enabled': true,
    'native_style_enabled': true,
    'native_history_enabled': true,
    'native_image_enabled': true,
    'native_info_enabled': true,
    'native_home_enabled': true,
    'native_slider_enabled': true,
    'native_choose_style_enabled': true,
    'native_upload_image_enabled': true,
    'native_upload_image_select_enabled': true,
    'native_generation_enabled': true,
    'native_processing_enabled': true,

    // ===== TUNING =====
    'inter_interval': 45,
    'inter_detail_click_threshold': 3,
    'ad_count_save_with_watermark': 1,
    'ad_count_save_without_watermark': 3,
    'ad_count_share_with_watermark': 1,
    'ad_count_share_without_watermark': 3,
    'ad_count_daily_limit_generate': 1,

    // ===== URLS =====
    'image_style_cloudfare': 'https://cdn.zi003.imgly.store/style-release.json',
    'image_style_cloudfare_v2':
        'https://cdn.zi003.imgly.store/resource-json/style-release.json',
    'image_style_groups_cloudfare':
        'https://cdn.zi003.imgly.store/resource-json/category-release.json',

    // ===== APP OPEN (IDs) =====
    'android_app_open': 'ca-app-pub-4916271104673099/1775705302',
    'ios_app_open': 'ca-app-pub-4916271104673099/1775705302',
    'android_app_open_2floor': 'ca-app-pub-4916271104673099/9240080590',
    'ios_app_open_2floor': 'ca-app-pub-4916271104673099/9240080590',
    'android_app_open_resume': 'ca-app-pub-4916271104673099/1281699528',
    'ios_app_open_resume': 'ca-app-pub-4916271104673099/1281699528',
    'android_app_open_resume_2floor': 'ca-app-pub-4916271104673099/9656041231',
    'ios_app_open_resume_2floor': 'ca-app-pub-4916271104673099/9656041231',

    // ===== BANNER (IDs) =====
    'android_banner_splash': 'ca-app-pub-4916271104673099/5788775034',
    'ios_banner_splash': 'ca-app-pub-4916271104673099/5788775034',
    'android_banner_home': 'ca-app-pub-4916271104673099/2221049209',
    'ios_banner_home': 'ca-app-pub-4916271104673099/2221049209',
    'android_banner_history': 'ca-app-pub-4916271104673099/5511118021',
    'ios_banner_history': 'ca-app-pub-4916271104673099/5511118021',
    'android_banner_style': 'ca-app-pub-4916271104673099/3071096443',
    'ios_banner_style': 'ca-app-pub-4916271104673099/3071096443',
    'android_banner_adaptive_generate':
        'ca-app-pub-4916271104673099/1767314132',
    'ios_banner_adaptive_generate': 'ca-app-pub-4916271104673099/1767314132',
    'android_banner_change_style': 'ca-app-pub-4916271104673099/5974152456',
    'ios_banner_change_style': 'ca-app-pub-4916271104673099/5974152456',
    'android_banner_change_image': 'ca-app-pub-4916271104673099/8650726185',
    'ios_banner_change_image': 'ca-app-pub-4916271104673099/8650726185',
    'android_banner_change_ratio': 'ca-app-pub-4916271104673099/8674776914',
    'ios_banner_change_ratio': 'ca-app-pub-4916271104673099/8674776914',
    'android_banner_processing': 'ca-app-pub-4916271104673099/8870218037',
    'ios_banner_processing': 'ca-app-pub-4916271104673099/8870218037',
    'android_banner_splash_2floor': 'ca-app-pub-4916271104673099/6772941187',
    'ios_banner_splash_2floor': 'ca-app-pub-4916271104673099/6772941187',

    // ===== INTER (IDs) =====
    'android_inter_style': 'ca-app-pub-4916271104673099/4198036355',
    'ios_inter_style': 'ca-app-pub-4916271104673099/4198036355',
    'android_inter_change': 'ca-app-pub-4916271104673099/5832991153',
    'ios_inter_change': 'ca-app-pub-4916271104673099/5832991153',
    'android_inter_processing': 'ca-app-pub-4916271104673099/4735531908',
    'ios_inter_processing': 'ca-app-pub-4916271104673099/4735531908',
    'android_inter_detail': 'ca-app-pub-4916271104673099/1212780365',
    'ios_inter_detail': 'ca-app-pub-4916271104673099/1212780365',
    'android_inter_new': 'ca-app-pub-4916271104673099/1763853825',
    'ios_inter_new': 'ca-app-pub-4916271104673099/1763853825',
    'android_inter_new_2floor': 'ca-app-pub-4916271104673099/5119736715',
    'ios_inter_new_2floor': 'ca-app-pub-4916271104673099/5119736715',

    // ===== REWARD (IDs) =====
    'android_reward_save_1': 'ca-app-pub-4916271104673099/9604715202',
    'ios_reward_save_1': 'ca-app-pub-4916271104673099/9604715202',
    'android_reward_share_1': 'ca-app-pub-4916271104673099/7652822365',
    'ios_reward_share_1': 'ca-app-pub-4916271104673099/7652822365',
    'android_reward_save_3': 'ca-app-pub-4916271104673099/4510997165',
    'ios_reward_save_3': 'ca-app-pub-4916271104673099/4510997165',
    'android_reward_share_3': 'ca-app-pub-4916271104673099/5632507146',
    'ios_reward_share_3': 'ca-app-pub-4916271104673099/5632507146',
    'android_reward_quick_generate': 'ca-app-pub-4916271104673099/3955206150',
    'ios_reward_quick_generate': 'ca-app-pub-4916271104673099/3955206150',
    'android_reward_quick_generate_2floor':
        'ca-app-pub-4916271104673099/7745900051',
    'ios_reward_quick_generate_2floor':
        'ca-app-pub-4916271104673099/7745900051',

    // ===== NATIVE (IDs) =====
    'android_native_language': 'ca-app-pub-4916271104673099/1949586467',
    'ios_native_language': 'ca-app-pub-4916271104673099/1949586467',
    'android_native_language_2floor': 'ca-app-pub-4916271104673099/2631248718',
    'ios_native_language_2floor': 'ca-app-pub-4916271104673099/2631248718',
    'android_native_language_select': 'ca-app-pub-4916271104673099/1652568330',
    'ios_native_language_select': 'ca-app-pub-4916271104673099/1652568330',
    'android_native_language_select_2floor':
        'ca-app-pub-4916271104673099/4916934039',
    'ios_native_language_select_2floor':
        'ca-app-pub-4916271104673099/4916934039',
    'android_native_onboarding_1': 'ca-app-pub-4916271104673099/9636504792',
    'ios_native_onboarding_1': 'ca-app-pub-4916271104673099/9636504792',
    'android_native_onboarding_1_2floor':
        'ca-app-pub-4916271104673099/4976558069',
    'ios_native_onboarding_1_2floor': 'ca-app-pub-4916271104673099/4976558069',
    'android_native_onboarding_2': 'ca-app-pub-4916271104673099/8538181510',
    'ios_native_onboarding_2': 'ca-app-pub-4916271104673099/8538181510',
    'android_native_onboarding_2_2floor':
        'ca-app-pub-4916271104673099/2188395582',
    'ios_native_onboarding_2_2floor': 'ca-app-pub-4916271104673099/2188395582',
    'android_native_onboarding_3': 'ca-app-pub-4916271104673099/1460996643',
    'ios_native_onboarding_3': 'ca-app-pub-4916271104673099/1460996643',
    'android_native_onboarding_3_2floor':
        'ca-app-pub-4916271104673099/8125551308',
    'ios_native_onboarding_3_2floor': 'ca-app-pub-4916271104673099/8125551308',
    'android_native_onboarding_full': 'ca-app-pub-4916271104673099/3781542886',
    'ios_native_onboarding_full': 'ca-app-pub-4916271104673099/3781542886',
    'android_native_onboarding_full_2floor':
        'ca-app-pub-4916271104673099/8724231384',
    'ios_native_onboarding_full_2floor':
        'ca-app-pub-4916271104673099/8724231384',
    'android_native_history': 'ca-app-pub-4916271104673099/5697259781',
    'ios_native_history': 'ca-app-pub-4916271104673099/5697259781',
    'android_native_image': 'ca-app-pub-4916271104673099/3393651767',
    'ios_native_image': 'ca-app-pub-4916271104673099/3393651767',
    'android_native_info': 'ca-app-pub-4916271104673099/9978299460',
    'ios_native_info': 'ca-app-pub-4916271104673099/9978299460',
    'android_native_style': 'ca-app-pub-4916271104673099/6052909971',
    'ios_native_style': 'ca-app-pub-4916271104673099/6052909971',
    'android_native_home': 'ca-app-pub-4916271104673099/4086260561',
    'ios_native_home': 'ca-app-pub-4916271104673099/4086260561',
    'android_native_slider': 'ca-app-pub-4916271104673099/5399342233',
    'ios_native_slider': 'ca-app-pub-4916271104673099/5399342233',
    'android_native_choose_style': 'ca-app-pub-4916271104673099/4716815954',
    'ios_native_choose_style': 'ca-app-pub-4916271104673099/4716815954',
    'android_native_upload_image': 'ca-app-pub-4916271104673099/8657212344',
    'ios_native_upload_image': 'ca-app-pub-4916271104673099/8657212344',
    'android_native_upload_image_select':
        'ca-app-pub-4916271104673099/8657212344',
    'ios_native_upload_image_select': 'ca-app-pub-4916271104673099/8657212344',
    'android_native_generation': 'ca-app-pub-4916271104673099/7344130671',
    'ios_native_generation': 'ca-app-pub-4916271104673099/7344130671',
    'android_native_processing': 'ca-app-pub-4916271104673099/6031049009',
    'ios_native_processing': 'ca-app-pub-4916271104673099/6031049009',
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
        _keyInterInterval: _defaultInterInterval,
        _keyInterDetailClickThreshold: _defaultInterDetailClickThreshold,
      });
      debugPrint('✅ Default values set');

      // Load defaults immediately
      debugPrint('🔄 Loading default configs...');
      _loadConfigs();

      // try {
      //   debugPrint('🔄 Fetching Remote Config from server...');
      //   await _remoteConfig!.fetchAndActivate();
      //   debugPrint('✅ Remote Config fetched and activated');
      //
      //   debugPrint('🔄 Reloading configs after fetch...');
      //   _loadConfigs();
      //
      //   // Wrap trong try-catch để tránh crash nếu realtime listener fail
      //   try {
      //     debugPrint('🔄 Setting up realtime config listener...');
      //     _listenRealtime();
      //     debugPrint('✅ Realtime listener set up successfully');
      //   } catch (e) {
      //     debugPrint('❌ Error setting up realtime config listener: $e');
      //     // Tiếp tục mà không có realtime updates
      //   }
      // } catch (e, stackTrace) {
      //   debugPrint('❌ Remote Config fetch failed: $e');
      //   debugPrint('Stack trace: $stackTrace');
      //   // Tiếp tục với default configs
      // }

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
      // Kiểm tra _remoteConfig không null trước khi listen
      if (_remoteConfig == null) {
        debugPrint('⚠️ RemoteConfig is null, skipping realtime listener');
        return;
      }

      _configUpdateSubscription?.cancel(); // Cancel subscription cũ nếu có

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
        cancelOnError: false, // Không tự động cancel khi có lỗi
      );
    } catch (e) {
      debugPrint('❌ Error setting up realtime listener: $e');
      // Không throw, chỉ log để app vẫn chạy được
    }
  }

  void _loadConfigs() {
    try {
      debugPrint('🔄 Starting to load Remote Configs...');

      // Kiểm tra _remoteConfig không null
      if (_remoteConfig == null) {
        debugPrint('❌ RemoteConfig is null, using default configs');
        _config.assignAll(kDebugMode ? _debugConfig : _releaseConfig);
        return;
      }

      // 1. Load JSON-based ad configs
      String raw = '';
      try {
        if (kDebugMode) {
          raw = _remoteConfig!.getString(_keyAppConfigTest);
          debugPrint(
              '📝 Test config key: $_keyAppConfigTest, value length: ${raw.length}');
          if (raw.isEmpty ||
              raw == _remoteConfig!.getAll()[_keyAppConfigTest]?.source) {
            // Fallback to main config if test config is empty or invalid
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
          // Validate JSON string trước khi parse
          raw = raw.trim();
          if (raw.isEmpty) {
            throw FormatException('Empty JSON string');
          }

          // Kiểm tra xem có phải JSON hợp lệ không
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
          debugPrint('Raw JSON length: ${raw.length}');
          debugPrint(
              'Raw JSON preview (first 200 chars): ${raw.length > 200 ? raw.substring(0, 200) : raw}');
          if (e is FormatException) {
            debugPrint('FormatException details: ${e.message}');
            debugPrint('Source: ${e.source}');
            debugPrint('Offset: ${e.offset}');
          }
          debugPrint('Stack trace: $stackTrace');
          // Fallback về default config
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
        // Sử dụng default values nếu có lỗi
      }

      // Update adsEnabledRx
      try {
        adsEnabledRx.value = _b('ads_enabled');
        debugPrint('✅ Ads enabled: ${adsEnabledRx.value}');
      } catch (e) {
        debugPrint('❌ Error getting ads_enabled: $e');
        adsEnabledRx.value = true; // Default
      }

      // _notifyThemeService();

      debugPrint('✅ Remote Configs loaded and updated successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ CRITICAL ERROR in _loadConfigs: $e');
      debugPrint('Stack trace: $stackTrace');
      // Fallback về default config để app vẫn chạy được
      _config.assignAll(kDebugMode ? _debugConfig : _releaseConfig);
    }
  }

  void _notifyThemeService() {
    try {
      final themeString = _remoteConfig!.getString(_keyAppTheme);
      if (themeString.isNotEmpty &&
          (themeString == 'COLOR_PINK' || themeString == 'COLOR_BLUE')) {
        // Kiểm tra xem DynamicThemeService đã được đăng ký chưa
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

  // ========= HELPERS =========
  bool _b(String k) => _config[k] == true;
  String _s(String k) => _config[k]?.toString() ?? '';

  // ========= PUBLIC GETTERS (REACTIVE) =========
  bool get adsEnabled => adsEnabledRx.value;

  RxBool get maintenanceMode => _maintenanceMode;
  bool get isInMaintenance => _maintenanceMode.value;

  // ===== APP OPEN =====
  // Tầng thường
  bool get appOpenNormalEnabled => adsEnabled && _b('app_open_enabled');
  bool get appOpenResumeNormalEnabled =>
      adsEnabled && _b('app_open_resume_enabled');

  // Tầng 2Floor
  bool get appOpen2FloorEnabled => adsEnabled && _b('app_open_2floor_enabled');
  bool get appOpenResume2FloorEnabled =>
      adsEnabled && _b('app_open_resume_2floor_enabled');

  // Tổng hợp (Bật nếu một trong hai tầng bật)
  bool get appOpenEnabled => appOpenNormalEnabled || appOpen2FloorEnabled;
  bool get appOpenResumeEnabled =>
      appOpenResumeNormalEnabled || appOpenResume2FloorEnabled;

  // ===== BANNER =====
  bool get bannerSplashEnabled => adsEnabled && _b('banner_splash_enabled');
  bool get bannerHomeEnabled => adsEnabled && _b('banner_home_enabled');
  bool get bannerHistoryEnabled => adsEnabled && _b('banner_history_enabled');
  bool get bannerStyleEnabled => adsEnabled && _b('banner_style_enabled');
  bool get bannerAdaptiveGenerateEnabled =>
      adsEnabled && _b('banner_adaptive_generate_enabled');
  bool get bannerChangeStyleEnabled =>
      adsEnabled && _b('banner_change_style_enabled');
  bool get bannerChangeImageEnabled =>
      adsEnabled && _b('banner_change_image_enabled');
  bool get bannerChangeRatioEnabled =>
      adsEnabled && _b('banner_change_ratio_enabled');
  bool get bannerProcessingEnabled =>
      adsEnabled && _b('banner_processing_enabled');
  bool get bannerSplash2FloorEnabled =>
      adsEnabled && _b('banner_splash_2floor_enabled');
  bool get isBannerSplashEnabled =>
      bannerSplashEnabled || bannerSplash2FloorEnabled;

  // ===== INTER =====
  bool get interStyleEnabled => adsEnabled && _b('inter_style_enabled');
  bool get interChangeEnabled => adsEnabled && _b('inter_change_enabled');
  bool get interProcessingEnabled =>
      adsEnabled && _b('inter_processing_enabled');
  bool get interDetailEnabled => adsEnabled && _b('inter_detail_enabled');
  bool get interNewEnabled => adsEnabled && _b('inter_new_enabled');

  int get interInterval => _config[_keyInterInterval] ?? _defaultInterInterval;
  int get interDetailClickThreshold =>
      _config[_keyInterDetailClickThreshold] ??
      _defaultInterDetailClickThreshold;

  // ===== REWARD =====
  bool get rewardSave1Enabled => adsEnabled && _b('reward_save_1_enabled');
  bool get rewardShare1Enabled => adsEnabled && _b('reward_share_1_enabled');
  bool get rewardSave3Enabled => adsEnabled && _b('reward_save_3_enabled');
  bool get rewardShare3Enabled => adsEnabled && _b('reward_share_3_enabled');
  bool get rewardQuickGenerateEnabled =>
      adsEnabled && _b('reward_quick_generate_enabled');

  // ===== NATIVE =====
  bool get nativeLanguageEnabled => adsEnabled && _b('native_language_enabled');
  bool get nativeLanguageSelectEnabled =>
      adsEnabled && _b('native_language_select_enabled');
  bool get nativeLanguageSelect2FloorEnabled =>
      adsEnabled && _b('native_language_select_2floor_enabled');
  bool get nativeLanguage2FloorEnabled =>
      adsEnabled && _b('native_language_2floor_enabled');
  bool get nativeHistoryEnabled => adsEnabled && _b('native_history_enabled');
  bool get nativeImageEnabled => adsEnabled && _b('native_image_enabled');
  bool get nativeInfoEnabled => adsEnabled && _b('native_info_enabled');
  bool get nativeStyleEnabled => adsEnabled && _b('native_style_enabled');
  bool get nativeHomeEnabled => adsEnabled && _b('native_home_enabled');
  bool get nativeSliderEnabled => adsEnabled && _b('native_slider_enabled');
  bool get nativeChooseStyleEnabled =>
      adsEnabled && _b('native_choose_style_enabled');
  bool get nativeUploadImageEnabled =>
      adsEnabled && _b('native_upload_image_enabled');
  bool get nativeUploadImageSelectEnabled =>
      adsEnabled && _b('native_upload_image_select_enabled');
  bool get nativeGenerationEnabled =>
      adsEnabled && _b('native_generation_enabled');
  bool get nativeProcessingEnabled =>
      adsEnabled && _b('native_processing_enabled');
  // ===== ONBOARDING =====
  bool get nativeOnboarding1Enabled =>
      adsEnabled && _b('native_onboarding_1_enabled');
  bool get nativeOnboarding1_2FloorEnabled =>
      adsEnabled && _b('native_onboarding_1_2floor_enabled');
  bool get nativeOnboarding2Enabled =>
      adsEnabled && _b('native_onboarding_2_enabled');
  bool get nativeOnboarding2_2FloorEnabled =>
      adsEnabled && _b('native_onboarding_2_2floor_enabled');
  bool get nativeOnboarding3Enabled =>
      adsEnabled && _b('native_onboarding_3_enabled');
  bool get nativeOnboarding3_2FloorEnabled =>
      adsEnabled && _b('native_onboarding_3_2floor_enabled');
  bool get nativeOnboardingFullEnabled =>
      adsEnabled && _b('native_onboarding_full_enabled');
  bool get nativeOnboardingFull2FloorEnabled =>
      adsEnabled && _b('native_onboarding_full_2floor_enabled');
  bool get rewardQuickGenerate2FloorEnabled =>
      adsEnabled && _b('reward_quick_generate_2floor_enabled');
  bool get interNew2FloorEnabled =>
      adsEnabled && _b('inter_new_2floor_enabled');

  RxMap<String, dynamic> get configRx => _config;

  // ========= DYNAMIC GETTERS FOR NATIVE =========
  bool isNativeEnabled(String uniqueKey) {
    if (!adsEnabled) return false;

    var key = uniqueKey.replaceAll('_OB', '_onboarding_');

    if (key == 'native_home_medium') key = 'native_home';
    if (key == 'native_generating') key = 'native_generation';
    if (key.startsWith('2f_')) {
      key = '${key.substring(3)}_2F';
    }

    switch (key) {
      case 'native_language':
        return nativeLanguageEnabled;
      case 'native_language_2F':
        return nativeLanguage2FloorEnabled;
      case 'native_language_select':
        return nativeLanguageSelectEnabled;
      case 'native_language_select_2F':
        return nativeLanguageSelect2FloorEnabled;
      case 'native_onboarding_1':
        return nativeOnboarding1Enabled;
      case 'native_onboarding_1_2F':
        return nativeOnboarding1_2FloorEnabled;
      case 'native_onboarding_2':
        return nativeOnboarding2Enabled;
      case 'native_onboarding_2_2F':
        return nativeOnboarding2_2FloorEnabled;
      case 'native_onboarding_3':
        return nativeOnboarding3Enabled;
      case 'native_onboarding_3_2F':
        return nativeOnboarding3_2FloorEnabled;
      case 'native_onboarding_full':
        return nativeOnboardingFullEnabled;
      case 'native_onboarding_full_2F':
        return nativeOnboardingFull2FloorEnabled;
      case 'native_history':
        return nativeHistoryEnabled;
      case 'native_image':
        return nativeImageEnabled;
      case 'native_info':
        return nativeInfoEnabled;
      case 'native_style':
        return nativeStyleEnabled;
      case 'native_home':
        return nativeHomeEnabled;
      case 'native_slider':
        return nativeSliderEnabled;
      case 'native_choose_style':
        return nativeChooseStyleEnabled;
      case 'native_upload_image':
      case 'native_upload_image_2F':
        return nativeUploadImageEnabled;
      case 'native_upload_image_select':
      case 'native_upload_image_select_2F':
        return nativeUploadImageSelectEnabled;
      case 'native_generation':
        return nativeGenerationEnabled;
      case 'native_processing':
        return nativeProcessingEnabled;
      default:
        return adsEnabled;
    }
  }

  bool isAppOpenNormalEnabled(String type) {
    if (!adsEnabled) return false;
    if (type == 'resume') {
      return appOpenResumeNormalEnabled;
    }
    return appOpenNormalEnabled;
  }

  bool isAppOpenHighFloorEnabled(String type) {
    if (!adsEnabled) return false;
    if (type == 'resume') {
      return appOpenResume2FloorEnabled;
    }
    return appOpen2FloorEnabled;
  }

  bool isAppOpenEnabled(String type) {
    return isAppOpenNormalEnabled(type) || isAppOpenHighFloorEnabled(type);
  }

  bool isBannerEnabled(String placement) {
    return isBannerNormalEnabled(placement) ||
        isBannerHighFloorEnabled(placement);
  }

  bool isBannerNormalEnabled(String placement) {
    if (!adsEnabled) return false;
    switch (placement) {
      case 'banner_home':
        return bannerHomeEnabled;
      case 'banner_splash':
        return bannerSplashEnabled;
      case 'banner_history':
        return bannerHistoryEnabled;
      case 'banner_style':
        return bannerStyleEnabled;
      case 'banner_change_style':
        return bannerChangeStyleEnabled;
      case 'banner_change_image':
        return bannerChangeImageEnabled;
      case 'banner_change_ratio':
        return bannerChangeRatioEnabled;
      case 'banner_adaptive_generate':
        return bannerAdaptiveGenerateEnabled;
      case 'banner_processing':
        return bannerProcessingEnabled;
      default:
        return adsEnabled;
    }
  }

  bool isBannerHighFloorEnabled(String placement) {
    if (!adsEnabled) return false;
    switch (placement) {
      case 'banner_splash':
        return bannerSplash2FloorEnabled;
      default:
        return false;
    }
  }

  String getAppOpenAdUnitId(String type) {
    if (type == 'resume') {
      return Platform.isAndroid ? androidAppOpenResume : iosAppOpenResume;
    }
    return Platform.isAndroid ? androidAppOpen : iosAppOpen;
  }

  String getAppOpenHighFloorAdUnitId(String type) {
    if (type == 'resume') {
      return Platform.isAndroid
          ? androidAppOpenResume2Floor
          : iosAppOpenResume2Floor;
    }
    return Platform.isAndroid ? androidAppOpen2Floor : iosAppOpen2Floor;
  }

  String getBannerAdUnitId(String placement) {
    if (Platform.isAndroid) {
      switch (placement) {
        case 'banner_home':
          return androidBannerHome;
        case 'banner_splash':
          return androidBannerSplash;
        case 'banner_history':
          return androidBannerHistory;
        case 'banner_style':
          return androidBannerStyle;
        case 'banner_change_style':
          return androidBannerChangeStyle;
        case 'banner_change_image':
          return androidBannerChangeImage;
        case 'banner_change_ratio':
          return androidBannerChangeRatio;
        case 'banner_adaptive_generate':
          return androidBannerAdaptiveGenerate;
        case 'banner_processing':
          return androidBannerProcessing;
        default:
          return 'ca-app-pub-3940256099942544/6300978111';
      }
    } else {
      switch (placement) {
        case 'banner_home':
          return iosBannerHome;
        case 'banner_splash':
          return iosBannerSplash;
        case 'banner_history':
          return iosBannerHistory;
        case 'banner_style':
          return iosBannerStyle;
        case 'banner_change_style':
          return iosBannerChangeStyle;
        case 'banner_change_image':
          return iosBannerChangeImage;
        case 'banner_change_ratio':
          return iosBannerChangeRatio;
        case 'banner_adaptive_generate':
          return iosBannerAdaptiveGenerate;
        case 'banner_processing':
          return iosBannerProcessing;

        default:
          return 'ca-app-pub-3940256099942544/2934735716';
      }
    }
  }

  String getBannerHighFloorAdUnitId(String placement) {
    if (Platform.isAndroid) {
      switch (placement) {
        case 'banner_splash':
          return androidBannerSplash2Floor;
        default:
          return '';
      }
    } else {
      switch (placement) {
        case 'banner_splash':
          return iosBannerSplash2Floor;
        default:
          return '';
      }
    }
  }

  String getNativeAdUnitId(String uniqueKey) {
    var key = uniqueKey.replaceAll('_OB', '_onboarding_');

    if (key == 'native_home_medium') key = 'native_home';
    if (key == 'native_generating') key = 'native_generation';
    if (key.startsWith('2f_')) {
      key = '${key.substring(3)}_2F';
    }

    if (Platform.isAndroid) {
      switch (key) {
        case 'native_language':
          return androidNativeLanguage;
        case 'native_language_2F':
          return androidNativeLanguage2Floor;
        case 'native_language_select':
          return androidNativeLanguageSelect;
        case 'native_language_select_2F':
          return androidNativeLanguageSelect2Floor;
        case 'native_onboarding_1':
          return androidNativeOnboarding1;
        case 'native_onboarding_1_2F':
          return androidNativeOnboarding1_2Floor;
        case 'native_onboarding_2':
          return androidNativeOnboarding2;
        case 'native_onboarding_2_2F':
          return androidNativeOnboarding2_2Floor;
        case 'native_onboarding_3':
          return androidNativeOnboarding3;
        case 'native_onboarding_3_2F':
          return androidNativeOnboarding3_2Floor;
        case 'native_onboarding_full':
          return androidNativeOnboardingFull;
        case 'native_onboarding_full_2F':
          return androidNativeOnboardingFull2Floor;
        case 'native_history':
          return androidNativeHistory;
        case 'native_image':
          return androidNativeImage;
        case 'native_info':
          return androidNativeInfo;
        case 'native_style':
          return androidNativeStyle;
        case 'native_home':
          return androidNativeHome;
        case 'native_slider':
          return androidNativeSlider;
        case 'native_choose_style':
          return androidNativeChooseStyle;
        case 'native_upload_image':
        case 'native_upload_image_2F':
          return androidNativeUploadImage;
        case 'native_upload_image_select':
        case 'native_upload_image_select_2F':
          return androidNativeUploadImageSelect;
        case 'native_generation':
          return androidNativeGeneration;
        case 'native_processing':
          return androidNativeProcessing;
        default:
          return androidNativeLanguage;
      }
    } else {
      switch (key) {
        case 'native_language':
          return iosNativeLanguage;
        case 'native_language_2F':
          return iosNativeLanguage2Floor;
        case 'native_language_select':
          return iosNativeLanguageSelect;
        case 'native_language_select_2F':
          return iosNativeLanguageSelect2Floor;
        case 'native_onboarding_1':
          return iosNativeOnboarding1;
        case 'native_onboarding_1_2F':
          return iosNativeOnboarding1_2Floor;
        case 'native_onboarding_2':
          return iosNativeOnboarding2;
        case 'native_onboarding_2_2F':
          return iosNativeOnboarding2_2Floor;
        case 'native_onboarding_3':
          return iosNativeOnboarding3;
        case 'native_onboarding_3_2F':
          return iosNativeOnboarding3_2Floor;
        case 'native_onboarding_full':
          return iosNativeOnboardingFull;
        case 'native_onboarding_full_2F':
          return iosNativeOnboardingFull2Floor;
        case 'native_history':
          return iosNativeHistory;
        case 'native_image':
          return iosNativeImage;
        case 'native_info':
          return iosNativeInfo;
        case 'native_style':
          return iosNativeStyle;
        case 'native_home':
          return iosNativeHome;
        case 'native_slider':
          return iosNativeSlider;
        case 'native_choose_style':
          return iosNativeChooseStyle;
        case 'native_upload_image':
        case 'native_upload_image_2F':
          return iosNativeUploadImage;
        case 'native_upload_image_select':
        case 'native_upload_image_select_2F':
          return iosNativeUploadImageSelect;
        case 'native_generation':
          return iosNativeGeneration;
        case 'native_processing':
          return iosNativeProcessing;
        default:
          return iosNativeLanguage;
      }
    }
  }

  // APP OPEN ADS IDs
  String get androidAppOpen => _s('android_app_open');
  String get androidAppOpenResume => _s('android_app_open_resume');
  String get iosAppOpen => _s('ios_app_open');
  String get iosAppOpenResume => _s('ios_app_open_resume');
  String get androidAppOpen2Floor => _s('android_app_open_2floor');
  String get iosAppOpen2Floor => _s('ios_app_open_2floor');
  String get androidAppOpenResume2Floor => _s('android_app_open_resume_2floor');
  String get iosAppOpenResume2Floor => _s('ios_app_open_resume_2floor');

  // INTERSTITIAL ADS IDs
  String get androidInterStyle => _s('android_inter_style');
  String get iosInterStyle => _s('ios_inter_style');
  String get androidInterChange => _s('android_inter_change');
  String get iosInterChange => _s('ios_inter_change');
  String get androidInterProcessing => _s('android_inter_processing');
  String get iosInterProcessing => _s('ios_inter_processing');
  String get androidInterDetail => _s('android_inter_detail');
  String get iosInterDetail => _s('ios_inter_detail');
  String get androidInterNew => _s('android_inter_new');
  String get iosInterNew => _s('ios_inter_new');
  String get androidInterNew2Floor => _s('android_inter_new_2floor');
  String get iosInterNew2Floor => _s('ios_inter_new_2floor');

  // REWARD ADS IDs
  String get androidRewardSave1 => _s('android_reward_save_1');
  String get iosRewardSave1 => _s('ios_reward_save_1');
  String get androidRewardShare1 => _s('android_reward_share_1');
  String get iosRewardShare1 => _s('ios_reward_share_1');
  String get androidRewardSave3 => _s('android_reward_save_3');
  String get iosRewardSave3 => _s('ios_reward_save_3');
  String get androidRewardShare3 => _s('android_reward_share_3');
  String get iosRewardShare3 => _s('ios_reward_share_3');
  String get androidRewardQuickGenerate => _s('android_reward_quick_generate');
  String get iosRewardQuickGenerate => _s('ios_reward_quick_generate');
  String get androidRewardQuickGenerate2Floor =>
      _s('android_reward_quick_generate_2floor');
  String get iosRewardQuickGenerate2Floor =>
      _s('ios_reward_quick_generate_2floor');

  // NATIVE ADS IDs
  String get androidNativeLanguage => _s('android_native_language');
  String get iosNativeLanguage => _s('ios_native_language');
  String get androidNativeLanguage2Floor =>
      _s('android_native_language_2floor');
  String get iosNativeLanguage2Floor => _s('ios_native_language_2floor');
  String get androidNativeLanguageSelect =>
      _s('android_native_language_select');
  String get iosNativeLanguageSelect => _s('ios_native_language_select');
  String get androidNativeLanguageSelect2Floor =>
      _s('android_native_language_select_2floor');
  String get iosNativeLanguageSelect2Floor =>
      _s('ios_native_language_select_2floor');
  String get androidNativeOnboarding1 => _s('android_native_onboarding_1');
  String get iosNativeOnboarding1 => _s('ios_native_onboarding_1');
  String get androidNativeOnboarding1_2Floor =>
      _s('android_native_onboarding_1_2floor');
  String get iosNativeOnboarding1_2Floor =>
      _s('ios_native_onboarding_1_2floor');
  String get androidNativeOnboarding2 => _s('android_native_onboarding_2');
  String get iosNativeOnboarding2 => _s('ios_native_onboarding_2');
  String get androidNativeOnboarding2_2Floor =>
      _s('android_native_onboarding_2_2floor');
  String get iosNativeOnboarding2_2Floor =>
      _s('ios_native_onboarding_2_2floor');
  String get androidNativeOnboarding3 => _s('android_native_onboarding_3');
  String get iosNativeOnboarding3 => _s('ios_native_onboarding_3');
  String get androidNativeOnboarding3_2Floor =>
      _s('android_native_onboarding_3_2floor');
  String get iosNativeOnboarding3_2Floor =>
      _s('ios_native_onboarding_3_2floor');
  String get androidNativeOnboardingFull =>
      _s('android_native_onboarding_full');
  String get iosNativeOnboardingFull => _s('ios_native_onboarding_full');
  String get androidNativeOnboardingFull2Floor =>
      _s('android_native_onboarding_full_2floor');
  String get iosNativeOnboardingFull2Floor =>
      _s('ios_native_onboarding_full_2floor');
  String get androidNativeHistory => _s('android_native_history');
  String get iosNativeHistory => _s('ios_native_history');
  String get androidNativeImage => _s('android_native_image');
  String get iosNativeImage => _s('ios_native_image');
  String get androidNativeInfo => _s('android_native_info');
  String get iosNativeInfo => _s('ios_native_info');
  String get androidNativeStyle => _s('android_native_style');
  String get iosNativeStyle => _s('ios_native_style');
  String get androidNativeHome => _s('android_native_home');
  String get iosNativeHome => _s('ios_native_home');
  String get androidNativeSlider => _s('android_native_slider');
  String get iosNativeSlider => _s('ios_native_slider');
  String get androidNativeChooseStyle => _s('android_native_choose_style');
  String get iosNativeChooseStyle => _s('ios_native_choose_style');
  String get androidNativeUploadImage => _s('android_native_upload_image');
  String get iosNativeUploadImage => _s('ios_native_upload_image');
  String get androidNativeUploadImageSelect =>
      _s('android_native_upload_image_select');
  String get iosNativeUploadImageSelect => _s('ios_native_upload_image_select');
  String get androidNativeGeneration => _s('android_native_generation');
  String get iosNativeGeneration => _s('ios_native_generation');
  String get androidNativeProcessing => _s('android_native_processing');
  String get iosNativeProcessing => _s('ios_native_processing');

  // BANNER ADS IDs
  String get androidBannerSplash => _s('android_banner_splash');
  String get iosBannerSplash => _s('ios_banner_splash');
  String get androidBannerHome => _s('android_banner_home');
  String get iosBannerHome => _s('ios_banner_home');
  String get androidBannerHistory => _s('android_banner_history');
  String get iosBannerHistory => _s('ios_banner_history');
  String get androidBannerStyle => _s('android_banner_style');
  String get iosBannerStyle => _s('ios_banner_style');
  String get androidBannerAdaptiveGenerate =>
      _s('android_banner_adaptive_generate');
  String get iosBannerAdaptiveGenerate => _s('ios_banner_adaptive_generate');
  String get androidBannerChangeStyle => _s('android_banner_change_style');
  String get iosBannerChangeStyle => _s('ios_banner_change_style');
  String get androidBannerChangeImage => _s('android_banner_change_image');
  String get iosBannerChangeImage => _s('ios_banner_change_image');
  String get androidBannerChangeRatio => _s('android_banner_change_ratio');
  String get iosBannerChangeRatio => _s('ios_banner_change_ratio');
  String get androidBannerProcessing => _s('android_banner_processing');
  String get iosBannerProcessing => _s('ios_banner_processing');
  String get androidBannerSplash2Floor => _s('android_banner_splash_2floor');
  String get iosBannerSplash2Floor => _s('ios_banner_splash_2floor');

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

  // ===== AD COUNT CONFIG =====
  int get adCountSaveWithWatermark =>
      _config['ad_count_save_with_watermark'] ?? 1;

  int get adCountSaveWithoutWatermark =>
      _config['ad_count_save_without_watermark'] ?? 3;

  int get adCountShareWithWatermark =>
      _config['ad_count_share_with_watermark'] ?? 1;

  int get adCountShareWithoutWatermark =>
      _config['ad_count_share_without_watermark'] ?? 3;

  int get adCountDailyLimitGenerate =>
      _config['ad_count_daily_limit_generate'] ?? 1;

  void dispose() {
    try {
      _configUpdateSubscription?.cancel();
      _configUpdateSubscription = null;
    } catch (e) {
      debugPrint('❌ Error canceling config subscription: $e');
      // Không throw, chỉ log
    }
  }
}
