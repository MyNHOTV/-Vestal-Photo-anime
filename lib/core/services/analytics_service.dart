import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._internal();

  static final AnalyticsService shared = AnalyticsService._internal();

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  Future<void> init() async {
    try {
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

  Map<String, Object>? _convertParameters(Map<String, dynamic>? parameters) {
    if (parameters == null) return null;
    return parameters.map((key, value) {
      if (value is String ||
          value is int ||
          value is double ||
          value is bool ||
          value is List ||
          value is Map) {
        return MapEntry(key, value as Object);
      }
      return MapEntry(key, value.toString());
    });
  }

  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: _convertParameters(parameters),
      );
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

  // ========== CHOOSE LANGUAGE EVENTS ==========
  Future<void> screenLanguageShow() => logEvent(name: 'screen_language_show');
  Future<void> actionConfirmLanguage() =>
      logEvent(name: 'action_confirm_language');

  // ========== ONBOARDING EVENTS ==========
  Future<void> screenOb1Show() => logEvent(name: 'screen_ob1_show');
  Future<void> screenOb2Show() => logEvent(name: 'screen_ob2_show');
  Future<void> screenOb3Show() => logEvent(name: 'screen_ob3_show');
  Future<void> screenOb4Show() => logEvent(name: 'screen_ob4_show');
  Future<void> actionCompleteOb() => logEvent(name: 'action_complete_ob');

  // ========== HOME EVENTS ==========
  Future<void> screenHomeFirstShow() =>
      logEvent(name: 'screen_home_first_show');
  Future<void> screenHomeSecondShow() =>
      logEvent(name: 'screen_home_second_show');
  Future<void> screenHomeShow() => logEvent(name: 'screen_home_show');
  Future<void> styleClick(String nameStyle) => logEvent(
      name: 'action_style_click', parameters: {'nameStyle': nameStyle});
  Future<void> actionAllClick(String category) =>
      logEvent(name: 'action_all_click', parameters: {'category': category});
  Future<void> actionChooseDialog() => logEvent(name: 'action_choose_dialog');

  // ========== UPLOAD IMAGE EVENTS ==========
  Future<void> actionUploadSuccess() => logEvent(name: 'action_upload_success');
  Future<void> screenUploadImageShow() =>
      logEvent(name: 'screen_upload_image_show');
  Future<void> actionSelectImageClick() =>
      logEvent(name: 'action_select_image_click');
  Future<void> actionUploadImageBackWithImage() =>
      logEvent(name: 'action_upload_image_back_with_image');
  Future<void> actionUploadImageBackWithoutImage() =>
      logEvent(name: 'action_upload_image_back_without_image');

  // ========== SUMMARY EVENTS ==========
  Future<void> actionChangeImageClick() =>
      logEvent(name: 'action_change_image_click');
  Future<void> actionChangeStyleClick() =>
      logEvent(name: 'action_change_style_click');
  Future<void> actionGenerateClick() => logEvent(name: 'action_generate_click');
  Future<void> actionQuickGenerateClick() =>
      logEvent(name: 'action_quick_generate_click');
  Future<void> screenSummaryShow() => logEvent(name: 'screen_summary_show');
  Future<void> actionChangeImage() => logEvent(name: 'action_change_image');
  Future<void> actionChangeStyle() => logEvent(name: 'action_change_style');
  Future<void> actionChangeRatio() => logEvent(name: 'action_change_ratio');

  // ========== GENERATING EVENTS ==========
  Future<void> screenProcessingShow() =>
      logEvent(name: 'screen_processing_show');
  Future<void> actionGenerateLimit() => logEvent(name: 'action_generate_limit');

  // ========== RESULT EVENTS ==========
  Future<void> actionSaveWtm() => logEvent(name: 'action_save_wtm');
  Future<void> actionSaveNoWtm() => logEvent(name: 'action_save_no_wtm');
  Future<void> actionShareWtm() => logEvent(name: 'action_share_wtm');
  Future<void> actionShareNoWtm() => logEvent(name: 'action_share_no_wtm');
  Future<void> screenResultShow() => logEvent(name: 'screen_result_show');

  // ========== HISTORY EVENTS ==========
  Future<void> screenHistoryShow() => logEvent(name: 'screen_history_show');

  // ========== STYLE EVENTS ==========
  Future<void> screenStyleShow() => logEvent(name: 'screen_style_show');
  Future<void> styleClickFromStyle() => logEvent(name: 'style_click');

  // ========== IMAGE GENERATION EVENTS ==========
  Future<void> screenChooseStyleShow() =>
      logEvent(name: 'screen_choose_style_show');
  Future<void> screenChooseRatioShow() =>
      logEvent(name: 'screen_choose_ratio_show');

  // ========== INFO EVENTS ==========
  Future<void> screenImageInfoShow() =>
      logEvent(name: 'screen_image_info_show');

  // ========== OTHER EVENTS ==========
  Future<void> actionCallApi() => logEvent(name: 'action_call_api');
  Future<void> actionGenerateSuccess() =>
      logEvent(name: 'action_generate_success');
  Future<void> actionCallApiSuccess() =>
      logEvent(name: 'action_call_api_success');
  Future<void> actionCallApiFail() => logEvent(name: 'action_call_api_fail');
  Future<void> actionCallApiException() =>
      logEvent(name: 'action_call_api_exception');
  Future<void> actionStyleCall(String nameStyle) => logEvent(
      name: 'action_style_call_api', parameters: {'nameStyle': nameStyle});

  // ========== HELPER METHODS ==========
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
}
