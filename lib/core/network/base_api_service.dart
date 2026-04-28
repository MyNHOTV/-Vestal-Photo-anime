import 'package:dio/dio.dart';

import '../utils/either.dart';
import 'errors.dart';

typedef ResponseParser<T> = T Function(dynamic data);

/// Base service cung cấp các phương thức CRUD chuẩn hoá dựa trên Dio.
class BaseApiService {
  BaseApiService({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<Either<AppError, T>> get<T>({
    required String path,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    ResponseParser<T>? parser,
  }) {
    return _request(
      request: () => _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      ),
      parser: parser,
    );
  }

  Future<Either<AppError, T>> post<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    ResponseParser<T>? parser,
  }) {
    return _request(
      request: () => _dio.post<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      parser: parser,
    );
  }

  Future<Either<AppError, T>> put<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    ResponseParser<T>? parser,
  }) {
    return _request(
      request: () => _dio.put<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      parser: parser,
    );
  }

  Future<Either<AppError, T>> patch<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
    ResponseParser<T>? parser,
  }) {
    return _request(
      request: () => _dio.patch<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      ),
      parser: parser,
    );
  }

  Future<Either<AppError, T>> delete<T>({
    required String path,
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ResponseParser<T>? parser,
  }) {
    return _request(
      request: () => _dio.delete<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
      parser: parser,
    );
  }

  Future<Either<AppError, T>> _request<T>({
    required Future<Response<dynamic>> Function() request,
    ResponseParser<T>? parser,
  }) async {
    try {
      final response = await request();
      final dynamic body = response.data;
      final parserFn = parser ?? _defaultParser<T>;
      final result = parserFn(body);
      return Right(result);
    } on DioException catch (e) {
      return Left(AppError.fromDio(e));
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  T _defaultParser<T>(dynamic data) {
    if (data is T) {
      return data;
    }

    throw AppError.unknown(
      message:
          'Unexpected response type. Provide a parser for type $T to deserialize the payload.',
    );
  }
}
