import 'package:dio/dio.dart';

enum AppErrorType {
  timeout, // Timeout errors
  connectionError, // Network/connection errors
  badResponse, // HTTP errors (400, 500, etc.)
  unknown, // Unknown errors
}

class AppError {
  final String message;
  final int? code;
  final AppErrorType errorType;

  const AppError._(this.message,
      {this.code, this.errorType = AppErrorType.unknown});

  factory AppError.network(String message,
          {int? code, AppErrorType errorType = AppErrorType.unknown}) =>
      AppError._(message, code: code, errorType: errorType);

  factory AppError.unknown({String? message}) =>
      AppError._(message ?? 'Unknown error', errorType: AppErrorType.unknown);

  factory AppError.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final msg = e.message ?? 'Network error';

    // Phân loại lỗi
    AppErrorType errorType;

    // Timeout errors
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      errorType = AppErrorType.timeout;
    }
    // Connection/Network errors
    else if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.badCertificate ||
        (e.type == DioExceptionType.unknown &&
            e.error?.toString().contains('SocketException') == true)) {
      errorType = AppErrorType.connectionError;
    }
    // HTTP response errors
    else if (e.type == DioExceptionType.badResponse) {
      errorType = AppErrorType.badResponse;
    }
    // Unknown
    else {
      errorType = AppErrorType.unknown;
    }

    return AppError.network(msg, code: status, errorType: errorType);
  }

  @override
  String toString() => 'AppError($code, $errorType): $message';
}
