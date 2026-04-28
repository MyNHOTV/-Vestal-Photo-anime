import 'package:dio/dio.dart';

import 'base_api_service.dart';
import 'dio_client.dart';
import 'errors.dart';

typedef Success<T> = void Function(T data);
typedef Fail = void Function(AppError error);

class ApiProvider {
  ApiProvider._internal() {
    _dio = DioClient.createDio();
    _baseService = BaseApiService(dio: _dio);
  }

  static final ApiProvider shared = ApiProvider._internal();

  late final Dio _dio;
  late final BaseApiService _baseService;

  BaseApiService get baseService => _baseService;

  // Expose APIs via getters to match pattern: ApiProvider.shared.xxxAPI.method(...)
  SampleAPI get sampleAPI => SampleAPI(_baseService);
}

class SampleAPI {
  final BaseApiService _service;
  SampleAPI(this._service);

  // Example method matching the requested callback style
  Future<void> getSomething({
    required Success<String> success,
    required Fail fail,
  }) async {
    final result = await _service.get<String>(
      path: '/anything', // replace with your path
      parser: (data) => data.toString(),
    );

    result.fold(fail, success);
  }
}
