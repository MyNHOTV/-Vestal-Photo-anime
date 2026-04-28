import 'package:dio/dio.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/api_error_realtime_service.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';

/// Dio Client - Chỉ chịu trách nhiệm tạo và cấu hình Dio instance
class DioClient {
  static Dio createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 300),
      sendTimeout: const Duration(seconds: 60),
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        ApiErrorRealtimeService.shared.logApiError(e);
        return handler.next(e);
      },
    ));

    if (AppConfig.enableLog) {
      final logger = Logger();
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          logger.i('➡️ REQUEST [${options.method}] => ${options.uri}');
          logger.d('Request Path: ${options.path}');
          logger.d('Request Base URL: ${options.baseUrl}');
          if (options.queryParameters.isNotEmpty) {
            logger.d('Query Parameters: ${options.queryParameters}');
          }
          if (options.data != null) {
            logger.d('Request Data: ${options.data}');
          }
          if (options.headers.isNotEmpty) {
            logger.d('Request Headers: ${options.headers}');
          }
          if (options.contentType != null) {
            logger.d('Content-Type: ${options.contentType}');
          }
          AnalyticsService.shared.actionCallApi();
          return handler.next(options);
        },
        onResponse: (response, handler) {
          logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          logger.i(
              '✅ SUCCESS [${response.statusCode}] => ${response.requestOptions.uri}');
          logger.d('Status Message: ${response.statusMessage ?? 'N/A'}');
          logger.d('Response Data: ${response.data}');

          if (response.headers.map.isNotEmpty) {
            logger.d('Response Headers: ${response.headers.map}');
          }

          if (response.extra.isNotEmpty) {
            logger.d('Extra Info: ${response.extra}');
          }

          final requestDuration = response.extra['request_duration'] ?? 'N/A';
          logger.d('Request Duration: $requestDuration');

          logger.i('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          AnalyticsService.shared.actionCallApiSuccess();
          return handler.next(response);
        },
        onError: (e, handler) {
          logger.e('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          logger.e(
              '❌ ERROR [${e.response?.statusCode ?? 'N/A'}] => ${e.requestOptions.uri}');
          logger.e('Error Type: ${e.type}');
          logger.e('Error Message: ${e.message}');

          if (e.response != null) {
            logger.e('Response Status Code: ${e.response?.statusCode}');
            logger.e(
                'Response Status Message: ${e.response?.statusMessage ?? 'N/A'}');
            logger.e('Response Data: ${e.response?.data}');

            if (e.response?.headers.map.isNotEmpty == true) {
              logger.e('Response Headers: ${e.response?.headers.map}');
            }
          } else {
            logger.e('No Response Received');
          }

          logger.e('Request Path: ${e.requestOptions.path}');
          logger.e('Request Method: ${e.requestOptions.method}');

          if (e.requestOptions.data != null) {
            logger.e('Request Data: ${e.requestOptions.data}');
          }

          if (e.requestOptions.queryParameters.isNotEmpty) {
            logger.e('Query Parameters: ${e.requestOptions.queryParameters}');
          }

          if (e.error != null) {
            logger.e('Error Object: ${e.error}');
          }

          logger.e('Stack Trace: ${e.stackTrace}');

          logger.e('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          AnalyticsService.shared.actionCallApiFail();
          return handler.next(e);
        },
      ));
    }

    return dio;
  }
}
