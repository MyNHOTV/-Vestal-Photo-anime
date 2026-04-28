import 'package:dio/dio.dart';

import '../utils/either.dart';
import 'base_api_service.dart';
import 'errors.dart';

typedef RequestErrorHandler = void Function(AppError error);

enum HttpMethod { get, post, put, patch, delete }

abstract class BaseClient {
  BaseClient({required BaseApiService apiService})
      : appApiService = AppApiService(apiService: apiService);

  final AppApiService appApiService;
}

class AppApiService {
  AppApiService({required BaseApiService apiService})
      : client = RestClient(apiService: apiService);

  final RestClient client;
}

class RestClient {
  RestClient({required BaseApiService apiService}) : _apiService = apiService;

  final BaseApiService _apiService;

  Future<Either<AppError, T>> requestApi<T>({
    required String path,
    HttpMethod method = HttpMethod.post,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    ResponseParser<T>? parser,
    RequestErrorHandler? onError,
  }) async {
    final result = await _dispatch<T>(
      path: path,
      method: method,
      body: body,
      queryParameters: queryParameters,
      headers: headers,
      parser: parser,
    );

    return result.fold(
      (error) {
        onError?.call(error);
        return Left<AppError, T>(error);
      },
      (data) => Right<AppError, T>(data),
    );
  }

  Future<Either<AppError, T>> _dispatch<T>({
    required String path,
    required HttpMethod method,
    dynamic body,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? headers,
    ResponseParser<T>? parser,
  }) {
    final options = headers != null ? Options(headers: headers) : null;

    switch (method) {
      case HttpMethod.get:
        return _apiService.get<T>(
          path: path,
          queryParameters: queryParameters,
          options: options,
          parser: parser,
        );
      case HttpMethod.post:
        return _apiService.post<T>(
          path: path,
          data: body,
          queryParameters: queryParameters,
          options: options,
          parser: parser,
        );
      case HttpMethod.put:
        return _apiService.put<T>(
          path: path,
          data: body,
          queryParameters: queryParameters,
          options: options,
          parser: parser,
        );
      case HttpMethod.patch:
        return _apiService.patch<T>(
          path: path,
          data: body,
          queryParameters: queryParameters,
          options: options,
          parser: parser,
        );
      case HttpMethod.delete:
        return _apiService.delete<T>(
          path: path,
          data: body,
          queryParameters: queryParameters,
          options: options,
          parser: parser,
        );
    }
  }
}
