import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class ConsentManager {
  static final ConsentManager instance = ConsentManager._internal();
  factory ConsentManager() => instance;
  ConsentManager._internal();

  /// Kiểm tra xem có thể yêu cầu quảng cáo hay không.
  Future<bool> canRequestAds() async {
    return await ConsentInformation.instance.canRequestAds();
  }

  /// Bắt đầu quá trình thu thập sự đồng ý của người dùng.
  /// Hàm này sẽ yêu cầu thông tin, và nếu cần, sẽ tải và hiển thị biểu mẫu.
  Future<void> gatherConsent() async {
    ConsentRequestParameters params;

    if (kDebugMode) {
      final debugSettings = ConsentDebugSettings(
        debugGeography: DebugGeography.debugGeographyEea,
        testIdentifiers: [
          '0EA27AE7D7C039044431FC592628E054',
        ],
      );

      params = ConsentRequestParameters(
        consentDebugSettings: debugSettings,
      );
    } else {
      params = ConsentRequestParameters();
    }

    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        if (await ConsentInformation.instance.isConsentFormAvailable()) {
          await _loadAndShowForm();
        }
        completer.complete();
      },
      (FormError error) {
        log('Consent info update error: ${error.message}');
        completer.complete();
      },
    );

    return completer.future;
  }

  Future<void> _loadAndShowForm() async {
    final completer = Completer<void>();

    ConsentForm.loadConsentForm(
      (form) async {
        // Kiểm tra status để xác định có cần show form không
        final status = await ConsentInformation.instance.getConsentStatus();

        if (status == ConsentStatus.required) {
          // Consent chưa có, hiển thị form
          form.show((formError) {
            if (formError != null) {
              log('Form show error: ${formError.message}');
            }
            completer.complete();
          });
        } else {
          // Đã có consent hoặc không cần thiết
          completer.complete();
        }
      },
      (error) {
        log('Load consent form error: ${error.message}');
        completer.complete();
      },
    );

    return completer.future;
  }
}
