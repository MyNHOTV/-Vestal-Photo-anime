import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_quick_base/core/services/appsflyer_service.dart';
import 'package:flutter_quick_base/core/services/appmetrica_service.dart';

class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService shared = AnalyticsService._internal();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> init() async {
    try {
      // Enable analytics collection
      await _analytics.setAnalyticsCollectionEnabled(true);
      if (kDebugMode) {
        print('Analytics collection enabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error enabling analytics: $e');
      }
    }
  }

  /// Convert Map<String, dynamic> to Map<String, Object>
  Map<String, Object>? _convertParameters(Map<String, dynamic>? parameters) {
    if (parameters == null) return null;

    return parameters.map((key, value) {
      // Firebase Analytics accepts: String, int, double, bool, List, Map
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

  /// Log event với parameters tùy chọn
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: _convertParameters(parameters),
      );
      if (AppsFlyerService.shared.isInitialized) {
        await AppsFlyerService.shared.logEvent(name, parameters);
      }
      if (AppMetricaService.shared.isInitialized) {
        await AppMetricaService.shared.logEvent(name, parameters);
      }
      if (kDebugMode) {
        print(
            'Analytics Event: $name${parameters != null ? ' - $parameters' : ''}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging analytics event: $e');
      }
    }
  }

  // ========== SPLASH EVENTS ==========

  /// Banner Splash loaded successfully
  Future<void> bannerAdSplashLoad() => logEvent(name: 'banner_ad_splash_load');

  /// Banner Splash failed to load
  Future<void> bannerAdSplashFail() => logEvent(name: 'banner_ad_splash_fail');

  /// Banner Splash impression
  Future<void> bannerAdSplashImp() => logEvent(name: 'banner_ad_splash_imp');

  /// Banner Splash clicked
  Future<void> bannerAdSplashClick() =>
      logEvent(name: 'banner_ad_splash_click');

  /// App Open loaded successfully
  Future<void> appOpenAdLoad() => logEvent(name: 'app_open_ad_load');

  /// App Open failed to load
  Future<void> appOpenAdFail() => logEvent(name: 'app_open_ad_fail');

  /// App Open shown
  Future<void> appOpenAdImp() => logEvent(name: 'app_open_ad_imp');

  /// App Open clicked
  Future<void> appOpenAdClick() => logEvent(name: 'app_open_ad_click');

  /// User closed App Open
  Future<void> appOpenAdDismiss() => logEvent(name: 'app_open_ad_dismiss');

  // ========== CHOOSE LANGUAGE EVENTS ==========

  /// Màn choose language hiển thị
  Future<void> screenLanguageShow() => logEvent(name: 'screen_language_show');

  /// Xác nhận ngôn ngữ
  Future<void> actionConfirmLanguage() =>
      logEvent(name: 'action_confirm_language');

  /// Native loaded
  Future<void> nativeAdLangLoad() => logEvent(name: 'native_ad_lang_load');

  /// Native load failed
  Future<void> nativeAdLangFail() => logEvent(name: 'native_ad_lang_fail');

  /// Native displayed
  Future<void> nativeAdLangImp() => logEvent(name: 'native_ad_lang_imp');

  /// Native clicked
  Future<void> nativeAdLangClick() => logEvent(name: 'native_ad_lang_click');

  // ========== ONBOARDING EVENTS ==========

  /// Mở màn onboarding 1
  Future<void> screenOb1Show() => logEvent(name: 'screen_ob1_show');

  /// Mở màn onboarding 2
  Future<void> screenOb2Show() => logEvent(name: 'screen_ob2_show');

  /// Mở màn onboarding 3
  Future<void> screenOb3Show() => logEvent(name: 'screen_ob3_show');

  /// Mở màn onboarding 4
  Future<void> screenOb4Show() => logEvent(name: 'screen_ob4_show');

  /// Hoàn tất onboarding
  Future<void> actionCompleteOb() => logEvent(name: 'action_complete_ob');

  /// Native onboarding loaded
  Future<void> nativeAdObLoad() => logEvent(name: 'native_ad_ob_load');

  /// Native onboarding fail
  Future<void> nativeAdObFail() => logEvent(name: 'native_ad_ob_fail');

  /// Native onboarding shown
  Future<void> nativeAdObImp() => logEvent(name: 'native_ad_ob_imp');

  /// Native onboarding clicked
  Future<void> nativeAdObClick() => logEvent(name: 'native_ad_ob_click');

  /// Native fullscreen loaded
  Future<void> nativeAdObFullLoad() => logEvent(name: 'native_ad_ob_full_load');

  /// Native fullscreen fail
  Future<void> nativeAdObFullFail() => logEvent(name: 'native_ad_ob_full_fail');

  /// Native fullscreen shown
  Future<void> nativeAdObFullImp() => logEvent(name: 'native_ad_ob_full_imp');

  /// Native fullscreen clicked
  Future<void> nativeAdObFullClick() =>
      logEvent(name: 'native_ad_ob_full_click');

  /// User skip Native fullscreen
  Future<void> nativeAdObFullSkip() => logEvent(name: 'native_ad_ob_full_skip');

  // ========== HOME EVENTS ==========

  /// Mở màn Home lần đầu tiên
  Future<void> screenHomeFirstShow() =>
      logEvent(name: 'screen_home_first_show');

  /// Mở màn Home lần thứ 2
  Future<void> screenHomeSecondShow() =>
      logEvent(name: 'screen_home_second_show');

  /// Mở màn Home
  Future<void> screenHomeShow() => logEvent(name: 'screen_home_show');

  /// Click vào Style để gen ảnh
  Future<void> styleClick(String nameStyle) => logEvent(
      name: 'action_style_click', parameters: {'nameStyle': nameStyle});

  /// Click All vào Category detail
  Future<void> actionAllClick(String category) =>
      logEvent(name: 'action_all_click', parameters: {'category': category});

  /// Click Choose this style ở dialog confirm
  Future<void> actionChooseDialog() => logEvent(name: 'action_choose_dialog');

  // ========== UPLOAD IMAGE EVENTS ==========
  /// Upload ảnh thành công
  Future<void> actionUploadSuccess() => logEvent(name: 'action_upload_success');
  // ========== SUMMARY EVENTS ==========
  /// Đổi ảnh (thay vì action_change_image)
  Future<void> actionChangeImageClick() =>
      logEvent(name: 'action_change_image_click');

  /// Đổi style (thay vì action_change_style)
  Future<void> actionChangeStyleClick() =>
      logEvent(name: 'action_change_style_click');

  /// Nhấn generate
  Future<void> actionGenerateClick() => logEvent(name: 'action_generate_click');

  /// Nhấn quick generate
  Future<void> actionQuickGenerateClick() =>
      logEvent(name: 'action_quick_generate_click');

// ========== GENERATING EVENTS ==========
  /// Mở màn processing (sửa typo screen_geneting_show)
  Future<void> screenProcessingShow() =>
      logEvent(name: 'screen_processing_show');

// ========== GENERATION LIMIT EVENTS ==========
  /// Nhấn Watch video ở popup limit gen (2 lần/ngày)
  Future<void> actionGenerateLimit() => logEvent(name: 'action_generate_limit');
  // ========== RESULT EVENTS ==========
  /// Save with watermark
  Future<void> actionSaveWtm() => logEvent(name: 'action_save_wtm');

  /// Save without watermark
  Future<void> actionSaveNoWtm() => logEvent(name: 'action_save_no_wtm');

  /// Share with watermark
  Future<void> actionShareWtm() => logEvent(name: 'action_share_wtm');

  /// Share without watermark
  Future<void> actionShareNoWtm() => logEvent(name: 'action_share_no_wtm');

  /// Banner loaded
  Future<void> bannerAdHomeLoad() => logEvent(name: 'banner_ad_home_load');

  /// Banner fail
  Future<void> bannerAdHomeFail() => logEvent(name: 'banner_ad_home_fail');

  /// Banner impression
  Future<void> bannerAdHomeImp() => logEvent(name: 'banner_ad_home_imp');

  /// Banner clicked
  Future<void> bannerAdHomeClick() => logEvent(name: 'banner_ad_home_click');

  /// Native Small loaded (Home)
  Future<void> nativeAdHomeLoad() => logEvent(name: 'native_ad_history_load');

  /// Native Small fail (Home)
  Future<void> nativeAdHomeFail() => logEvent(name: 'native_ad_history_fail');

  /// Native Small impression (Home)
  Future<void> nativeAdHomeImp() => logEvent(name: 'native_ad_history_imp');

  /// Native Small clicked (Home)
  Future<void> nativeAdHomeClick() => logEvent(name: 'native_ad_history_click');

  // ========== HISTORY EVENTS ==========

  /// Mở màn History
  Future<void> screenHistoryShow() => logEvent(name: 'screen_history_show');

  /// Banner loaded
  Future<void> bannerAdHistoryLoad() =>
      logEvent(name: 'banner_ad_history_load');

  /// Banner fail
  Future<void> bannerAdHistoryFail() =>
      logEvent(name: 'banner_ad_history_fail');

  /// Banner impression
  Future<void> bannerAdHistoryImp() => logEvent(name: 'banner_ad_history_imp');

  /// Banner clicked
  Future<void> bannerAdHistoryClick() =>
      logEvent(name: 'banner_ad_history_click');

  /// Native Small loaded
  Future<void> nativeAdHistoryLoad() =>
      logEvent(name: 'native_ad_history_load');

  /// Native Small fail
  Future<void> nativeAdHistoryFail() =>
      logEvent(name: 'native_ad_history_fail');

  /// Native Small impression
  Future<void> nativeAdHistoryImp() => logEvent(name: 'native_ad_history_imp');

  /// Native Small clicked
  Future<void> nativeAdHistoryClick() =>
      logEvent(name: 'native_ad_history_click');

  // ========== STYLE EVENTS ==========

  /// Mở màn style
  Future<void> screenStyleShow() => logEvent(name: 'screen_style_show');

  /// Click vào Style để gen ảnh
  Future<void> styleClickFromStyle() => logEvent(name: 'style_click');

  /// Banner loaded
  Future<void> bannerAdStyleLoad() => logEvent(name: 'banner_ad_style_load');

  /// Banner fail
  Future<void> bannerAdStyleFail() => logEvent(name: 'banner_ad_style_fail');

  /// Banner impression
  Future<void> bannerAdStyleImp() => logEvent(name: 'banner_ad_style_imp');

  /// Banner clicked
  Future<void> bannerAdStyleClick() => logEvent(name: 'banner_ad_style_click');

  /// Interstitial loaded
  Future<void> interAdStyleLoad() => logEvent(name: 'inter_ad_style_load');

  /// Interstitial fail
  Future<void> interAdStyleFail() => logEvent(name: 'inter_ad_style_fail');

  /// Interstitial shown
  Future<void> interAdStyleImp() => logEvent(name: 'inter_ad_style_imp');

  /// Interstitial clicked
  Future<void> interAdStyleClick() => logEvent(name: 'inter_ad_style_click');

  // ========== IMAGE GENERATION EVENTS ==========

  /// Mở màn chọn style gen ảnh
  Future<void> screenChooseStyleShow() =>
      logEvent(name: 'screen_choose_style_show');

  // ========== CHOOSE STYLE EVENTS ==========

  /// Banner loaded
  Future<void> bannerAdChooseStyleLoad() =>
      logEvent(name: 'banner_ad_choose_style_load');

  /// Banner fail
  Future<void> bannerAdChooseStyleFail() =>
      logEvent(name: 'banner_ad_choose_style_fail');

  /// Banner impression
  Future<void> bannerAdChooseStyleImp() =>
      logEvent(name: 'banner_ad_choose_style_imp');

  /// Banner clicked
  Future<void> bannerAdChooseStyleClick() =>
      logEvent(name: 'banner_ad_choose_style_click');

  // ========== UPLOAD IMAGE EVENTS ==========

  /// Mở màn chọn ảnh
  Future<void> screenUploadImageShow() =>
      logEvent(name: 'screen_upload_image_show');

  /// Bấm vào chọn ảnh
  Future<void> actionSelectImageClick() =>
      logEvent(name: 'action_select_image_click');

  /// Back trở ra có ảnh
  Future<void> actionUploadImageBackWithImage() =>
      logEvent(name: 'action_upload_image_back_with_image');

  /// Back trở ra không có ảnh
  Future<void> actionUploadImageBackWithoutImage() =>
      logEvent(name: 'action_upload_image_back_without_image');

  /// Banner loaded
  Future<void> bannerAdChooseImageLoad() =>
      logEvent(name: 'banner_ad_choose_image_load');

  /// Banner fail
  Future<void> bannerAdChooseImageFail() =>
      logEvent(name: 'banner_ad_choose_image_fail');

  /// Banner impression
  Future<void> bannerAdChooseImageImp() =>
      logEvent(name: 'banner_ad_choose_image_imp');

  /// Banner clicked
  Future<void> bannerAdChooseImageClick() =>
      logEvent(name: 'banner_ad_choose_image_click');

  // ========== CHOOSE RATIO EVENTS ==========

  /// Mở màn chọn ratio
  Future<void> screenChooseRatioShow() =>
      logEvent(name: 'screen_choose_ratio_show');

  /// Banner loaded
  Future<void> bannerAdChooseRatioLoad() =>
      logEvent(name: 'banner_ad_choose_ratio_load');

  /// Banner fail
  Future<void> bannerAdChooseRatioFail() =>
      logEvent(name: 'banner_ad_choose_ratio_fail');

  /// Banner impression
  Future<void> bannerAdChooseRatioImp() =>
      logEvent(name: 'banner_ad_choose_ratio_imp');

  /// Banner clicked
  Future<void> bannerAdChooseRatioClick() =>
      logEvent(name: 'banner_ad_choose_ratio_click');

  // ========== SUMMARY EVENTS ==========

  /// Mở màn tổng hợp
  Future<void> screenSummaryShow() => logEvent(name: 'screen_summary_show');

  /// Banner loaded
  Future<void> bannerAdSummaryLoad() =>
      logEvent(name: 'banner_ad_summary_load');

  /// Banner fail
  Future<void> bannerAdSummaryFail() =>
      logEvent(name: 'banner_ad_summary_fail');

  /// Banner impression
  Future<void> bannerAdSummaryImp() => logEvent(name: 'banner_ad_summary_imp');

  /// Banner clicked
  Future<void> bannerAdSummaryClick() =>
      logEvent(name: 'banner_ad_summary_click');

  /// Đổi ảnh
  Future<void> actionChangeImage() => logEvent(name: 'action_change_image');

  /// Đổi style
  Future<void> actionChangeStyle() => logEvent(name: 'action_change_style');

  /// Đổi ratio
  Future<void> actionChangeRatio() => logEvent(name: 'action_change_ratio');

  /// Interstitial loaded (change)
  Future<void> interAdChangeLoad() => logEvent(name: 'inter_ad_change_load');

  /// Interstitial fail (change)
  Future<void> interAdChangeFail() => logEvent(name: 'inter_ad_change_fail');

  /// Interstitial impression (change)
  Future<void> interAdChangeImp() => logEvent(name: 'inter_ad_change_imp');

  /// Interstitial clicked (change)
  Future<void> interAdChangeClick() => logEvent(name: 'inter_ad_change_click');

  /// Interstitial loaded (generating)
  Future<void> interAdGeneratingLoad() =>
      logEvent(name: 'inter_ad_generating_load');

  /// Interstitial fail (generating)
  Future<void> interAdGeneratingFail() =>
      logEvent(name: 'inter_ad_generating_fail');

  /// Interstitial impression (generating)
  Future<void> interAdGeneratingImp() =>
      logEvent(name: 'inter_ad_generating_imp');

  /// Interstitial clicked (generating)
  Future<void> interAdGeneratingClick() =>
      logEvent(name: 'inter_ad_generating_click');

  // ========== GENERATING EVENTS ==========

  /// Banner loaded
  Future<void> bannerAdGeneratingLoad() =>
      logEvent(name: 'banner_ad_generating_load');

  /// Banner fail
  Future<void> bannerAdGeneratingFail() =>
      logEvent(name: 'banner_ad_generating_fail');

  /// Banner impression
  Future<void> bannerAdGeneratingImp() =>
      logEvent(name: 'banner_ad_generating_imp');

  /// Banner clicked
  Future<void> bannerAdGeneratingClick() =>
      logEvent(name: 'banner_ad_generating_click');

  // ========== RESULT EVENTS ==========

  /// Mở màn kết quả gen ảnh
  Future<void> screenResultShow() => logEvent(name: 'screen_result_show');

  /// Banner loaded
  Future<void> bannerAdResultLoad() => logEvent(name: 'banner_ad_result_load');

  /// Banner fail
  Future<void> bannerAdResultFail() => logEvent(name: 'banner_ad_result_fail');

  /// Banner impression
  Future<void> bannerAdResultImp() => logEvent(name: 'banner_ad_result_imp');

  /// Banner clicked
  Future<void> bannerAdResultClick() =>
      logEvent(name: 'banner_ad_result_click');

  /// Reward loaded (save)
  Future<void> rewardAdSaveLoad() => logEvent(name: 'reward_ad_save_load');

  /// Reward fail (save)
  Future<void> rewardAdSaveFail() => logEvent(name: 'reward_ad_save_fail');

  /// Reward shown (save)
  Future<void> rewardAdSaveImp() => logEvent(name: 'reward_ad_save_imp');

  /// Reward reward granted (save)
  Future<void> rewardAdSaveReward() => logEvent(name: 'reward_ad_save_reward');

  /// Reward clicked (save)
  Future<void> rewardAdSaveClick() => logEvent(name: 'reward_ad_save_click');

  /// Reward loaded (share)
  Future<void> rewardAdShareLoad() => logEvent(name: 'reward_ad_share_load');

  /// Reward fail (share)
  Future<void> rewardAdShareFail() => logEvent(name: 'reward_ad_share_fail');

  /// Reward shown (share)
  Future<void> rewardAdShareImp() => logEvent(name: 'reward_ad_share_imp');

  /// Reward grant (share)
  Future<void> rewardAdShareReward() =>
      logEvent(name: 'reward_ad_share_reward');

  /// Reward clicked (share)
  Future<void> rewardAdShareClick() => logEvent(name: 'reward_ad_share_click');

  // ========== INFO EVENTS ==========

  /// Mở màn info của ảnh
  Future<void> screenImageInfoShow() =>
      logEvent(name: 'screen_image_info_show');

  /// Banner loaded
  Future<void> bannerAdInfoLoad() => logEvent(name: 'banner_ad_info_load');

  /// Banner fail
  Future<void> bannerAdInfoFail() => logEvent(name: 'banner_ad_info_fail');

  /// Banner impression
  Future<void> bannerAdInfoImp() => logEvent(name: 'banner_ad_info_imp');

  /// Banner clicked
  Future<void> bannerAdInfoClick() => logEvent(name: 'banner_ad_info_click');

  /// Interstitial loaded
  Future<void> interAdInfoLoad() => logEvent(name: 'inter_ad_info_load');

  /// Interstitial fail
  Future<void> interAdInfoFail() => logEvent(name: 'inter_ad_info_fail');

  /// Interstitial impression
  Future<void> interAdInfoImp() => logEvent(name: 'inter_ad_info_imp');

  /// Interstitial clicked
  Future<void> interAdInfoClick() => logEvent(name: 'inter_ad_info_click');

  // ========== NEW EVENTS ==========

  /// Interstitial loaded
  Future<void> interAdNewLoad() => logEvent(name: 'inter_ad_new_load');

  /// Interstitial fail
  Future<void> interAdNewFail() => logEvent(name: 'inter_ad_new_fail');

  /// Interstitial shown
  Future<void> interAdNewImp() => logEvent(name: 'inter_ad_new_imp');

  /// Interstitial clicked
  Future<void> interAdNewClick() => logEvent(name: 'inter_ad_new_click');

  // ========== OTHER EVENTS ==========

  /// Call API to generate image
  Future<void> actionCallApi() => logEvent(name: 'action_call_api');

  /// Image generated successfully
  Future<void> actionGenerateSuccess() =>
      logEvent(name: 'action_generate_success');

  /// Call API success
  Future<void> actionCallApiSuccess() =>
      logEvent(name: 'action_call_api_success');

  /// Call API fail
  Future<void> actionCallApiFail() => logEvent(name: 'action_call_api_fail');

  /// Call API exception
  Future<void> actionCallApiException() =>
      logEvent(name: 'action_call_api_exception');

  /// Call Api log event
  Future<void> actionStyleCall(String nameStyle) => logEvent(
      name: 'action_style_call_api', parameters: {'nameStyle': nameStyle});

  /// App Open Resume loaded
  Future<void> appOpenResumeAdLoad() =>
      logEvent(name: 'app_open_resume_ad_load');

  /// App Open Resume fail
  Future<void> appOpenResumeAdFail() =>
      logEvent(name: 'app_open_resume_ad_fail');

  /// App Open Resume displayed
  Future<void> appOpenResumeAdImp() => logEvent(name: 'app_open_resume_ad_imp');

  /// Clicked App Open Resume
  Future<void> appOpenResumeAdClick() =>
      logEvent(name: 'app_open_resume_ad_click');

  /// App Open Resume closed
  Future<void> appOpenResumeAdDismiss() =>
      logEvent(name: 'app_open_resume_ad_dismiss');

  // ========== HELPER METHODS ==========

  /// Set user ID
  Future<void> setUserId(String userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) {
        print('Analytics User ID set: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user ID: $e');
      }
    }
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('Analytics User Property set: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user property: $e');
      }
    }
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      if (kDebugMode) {
        print('Analytics Screen View: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error logging screen view: $e');
      }
    }
  }

  /// Report ad revenue
  Future<void> logAdRevenue({
    required double amount,
    required String currency,
    String? adNetwork,
    String? adUnitId,
    String? adPlacement,
    String? adType,
  }) async {
    try {
      // Log to AppMetrica
      if (AppMetricaService.shared.isInitialized) {
        await AppMetricaService.shared.reportAdRevenue(
          amount: amount,
          currency: currency,
          adNetwork: adNetwork,
          adUnitId: adUnitId,
          adPlacement: adPlacement,
          adType: adType,
        );
      }

      // Log to Firebase as well if needed (using logEvent with value)
      await _analytics.logEvent(
        name: 'ad_revenue',
        parameters: {
          'amount': amount,
          'currency': currency,
          if (adNetwork != null) 'ad_network': adNetwork,
          if (adUnitId != null) 'ad_unit_id': adUnitId,
          if (adPlacement != null) 'ad_placement': adPlacement,
          if (adType != null) 'ad_type': adType,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting ad revenue: $e');
      }
    }
  }
}
