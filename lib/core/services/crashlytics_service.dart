import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service để quản lý Firebase Crashlytics
class CrashlyticsService {
  CrashlyticsService._internal();
  static final CrashlyticsService shared = CrashlyticsService._internal();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  /// Khởi tạo Crashlytics
  Future<void> init() async {
    FlutterError.onError = (errorDetails) {
      _crashlytics.recordError(
        errorDetails.exception,
        errorDetails.stack,
        fatal: false,
        reason: errorDetails.context?.toString(),
      );
      if (kDebugMode) {
        FlutterError.presentError(errorDetails);
      }
    };
  }

  /// Log error không fatal
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      if (additionalData != null) {
        additionalData.forEach((key, value) {
          _crashlytics.setCustomKey(key, value.toString());
        });
      }

      if (reason != null) {
        _crashlytics.setCustomKey('reason', reason);
      }

      await _crashlytics.recordError(
        exception,
        stack,
        fatal: fatal,
      );
    } catch (e) {
      // Ignore errors in crashlytics itself
      if (kDebugMode) {
        print('Error recording to Crashlytics: $e');
      }
    }
  }

  /// Log message
  void log(String message) {
    try {
      _crashlytics.log(message);
    } catch (e) {
      if (kDebugMode) {
        print('Error logging to Crashlytics: $e');
      }
    }
  }

  /// Set user identifier
  void setUserId(String userId) {
    try {
      _crashlytics.setUserIdentifier(userId);
    } catch (e) {
      if (kDebugMode) {
        print('Error setting user ID: $e');
      }
    }
  }

  /// Set custom key
  void setCustomKey(String key, dynamic value) {
    try {
      _crashlytics.setCustomKey(key, value.toString());
    } catch (e) {
      if (kDebugMode) {
        print('Error setting custom key: $e');
      }
    }
  }

  /// Test crash (chỉ dùng trong dev)
  void testCrash() {
    if (kDebugMode) {
      _crashlytics.crash();
    }
  }
}
