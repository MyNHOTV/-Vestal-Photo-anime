import 'package:firebase_database/firebase_database.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'device_info_service.dart';

/// Service để log API errors lên Firebase Realtime Database
class ApiErrorRealtimeService {
  ApiErrorRealtimeService._internal();
  static final ApiErrorRealtimeService shared =
      ApiErrorRealtimeService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  static const String _nodePath = 'api_errors';

  /// Log API error lên Realtime Database với timestamp, device info và thông tin chi tiết
  Future<void> logApiError(DioException error) async {
    try {
      final timestamp = DateTime.now();
      final timestampMs = timestamp.millisecondsSinceEpoch;
      final uri = error.requestOptions.uri.toString();
      final method = error.requestOptions.method;
      final statusCode = error.response?.statusCode;
      final errorType = error.type.toString();

      // Lấy thông tin thiết bị
      final deviceInfo = await DeviceInfoService.shared.getDeviceInfo();

      // Tạo key unique dựa trên timestamp
      final errorKey = '$timestampMs-${Uri.parse(uri).path.hashCode}';

      // Chuẩn bị data để lưu vào Realtime Database
      final errorData = <String, dynamic>{
        'timestamp': ServerValue.timestamp,
        'local_timestamp': timestamp.toIso8601String(),
        'formatted_time': _formatTimestamp(timestamp),
        'timestamp_ms': timestampMs,

        // API thông tin
        'api_url': uri,
        'api_method': method,
        'api_path': error.requestOptions.path,
        'status_code': statusCode ?? -1,
        'error_type': errorType,
        'error_message': error.message ?? 'Unknown error',

        // Device information
        ...deviceInfo.toMap(),
      };

      // Request data (có thể null)
      if (error.requestOptions.data != null) {
        final requestDataStr = _convertToString(error.requestOptions.data);
        if (requestDataStr != null) {
          errorData['request_data'] = requestDataStr.length > 1000
              ? '${requestDataStr.substring(0, 1000)}... (truncated)'
              : requestDataStr;
        }
      }

      // Query parameters
      if (error.requestOptions.queryParameters.isNotEmpty) {
        errorData['query_parameters'] = error.requestOptions.queryParameters;
      }

      // Request headers (chỉ lưu một số headers quan trọng, tránh quá lớn)
      if (error.requestOptions.headers.isNotEmpty) {
        final headers = <String, dynamic>{};
        error.requestOptions.headers.forEach((key, value) {
          if (key.toLowerCase() != 'authorization') {
            // Không lưu token
            headers[key] = value;
          }
        });
        if (headers.isNotEmpty) {
          errorData['request_headers'] = headers;
        }
      }

      // Response data (có thể null)
      if (error.response?.data != null) {
        final responseDataStr = _convertToString(error.response!.data);
        if (responseDataStr != null) {
          errorData['response_data'] = responseDataStr.length > 1000
              ? '${responseDataStr.substring(0, 1000)}... (truncated)'
              : responseDataStr;
        }
      }

      // Response status message
      if (error.response?.statusMessage != null) {
        errorData['response_status_message'] = error.response!.statusMessage;
      }

      // Stack trace (giới hạn 500 ký tự)
      if (error.stackTrace != null) {
        final stackStr = error.stackTrace.toString();
        errorData['stack_trace'] = stackStr.length > 500
            ? '${stackStr.substring(0, 500)}... (truncated)'
            : stackStr;
      }

      // Push data lên Realtime Database
      await _database.child(_nodePath).child(errorKey).set(errorData);
    } catch (e) {
      // Ignore errors khi log lên Realtime Database để tránh loop
      if (kDebugMode) {
        print('❌ Error logging to Realtime Database: $e');
      }
    }
  }

  /// Format timestamp cho dễ đọc
  String _formatTimestamp(DateTime timestamp) {
    return '${timestamp.day}/${timestamp.month}/${timestamp.year} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';
  }

  /// Convert dynamic data thành String
  String? _convertToString(dynamic data) {
    if (data == null) return null;
    try {
      if (data is String) return data;
      if (data is Map || data is List) {
        return data.toString();
      }
      return data.toString();
    } catch (e) {
      return data.toString();
    }
  }
}
