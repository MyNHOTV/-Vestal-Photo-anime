import 'package:dio/dio.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/services/screen_protector.dart';
import 'package:flutter_quick_base/main.dart';
import 'package:get/get.dart';
import '../../features/home/presentation/controller/home_controller.dart';
import '../../features/image_generation/data/datasources/generated_image_local_datasource.dart';
import '../../features/image_generation/data/datasources/image_generation_remote_datasource.dart';
import '../../features/image_generation/data/repositories/image_generation_repository_impl.dart';
import '../../features/image_generation/domain/repositories/image_generation_repository.dart';
import '../../features/image_generation/domain/usecases/image_generation_usecase.dart';
import '../../features/image_generation/presentation/controllers/image_generation_controller.dart';
import '../network/base_api_service.dart';
import '../network/dio_client.dart';
import '../services/android_splash_service.dart';
import '../services/daily_generation_service.dart';
import '../services/dynamic_theme_service.dart';
import '../services/firebase_messaging_service.dart';
import '../services/firebase_storage_service.dart';
import '../services/network_service.dart';
import '../storage/local_storage_service.dart';

/// Dependency Injection Container
class InjectionContainer {
  static void init() {
    // Services
    if (kFirebaseEnabled) {
      Get.put<FirebaseStorageService>(
        FirebaseStorageService.shared,
        permanent: true,
      );
    }

    Get.put<DailyGenerationService>(
      DailyGenerationService.shared,
      permanent: true,
    );

    // Remote Config Service
    final remoteConfigService = RemoteConfigService.shared;
    Get.put<RemoteConfigService>(remoteConfigService, permanent: true);
    Get.put<ScreenProtectorService>(ScreenProtectorService.shared,
        permanent: true);

    // Dynamic Theme Service
    Get.put<DynamicThemeService>(
      DynamicThemeService.shared,
      permanent: true,
    );

    // Android Splash Service
    Get.put<AndroidSplashService>(
      AndroidSplashService.shared,
      permanent: true,
    );

    // Firebase Messaging Service
    if (kFirebaseEnabled) {
      Get.put<FirebaseMessagingService>(
        FirebaseMessagingService.shared,
        permanent: true,
      );
    }

    // Network Service
    Get.put<NetworkService>(
      NetworkService(),
      permanent: true,
    );
    // Dio instance
    Get.put<Dio>(
      DioClient.createDio(),
      permanent: true,
    );

    // Base API service
    Get.put<BaseApiService>(
      BaseApiService(dio: Get.find<Dio>()),
      permanent: true,
    );

    // Data Sources
    Get.lazyPut<ImageGenerationRemoteDataSource>(
      () => ImageGenerationRemoteDataSourceImpl(
        apiService: Get.find<BaseApiService>(),
      ),
      fenix: true,
    );

    Get.lazyPut<GeneratedImageLocalDataSource>(
      () => GeneratedImageLocalDataSourceImpl(
        storage: LocalStorageService.shared,
      ),
      fenix: true,
    );

    // Repositories
    Get.lazyPut<ImageGenerationRepository>(
      () => ImageGenerationRepositoryImpl(
        remoteDataSource: Get.find<ImageGenerationRemoteDataSource>(),
        localDataSource: Get.find<GeneratedImageLocalDataSource>(),
      ),
      fenix: true,
    );

    // Use Cases
    Get.lazyPut<ImageGenerationUsecase>(
      () => ImageGenerationUsecaseImpl(Get.find<ImageGenerationRepository>()),
      fenix: true,
    );

    // Controllers
    Get.lazyPut<ImageGenerationController>(
      () => ImageGenerationController(
        imageGenerationUsecase: Get.find<ImageGenerationUsecase>(),
      ),
      fenix: true,
    );

    Get.lazyPut<HomeController>(
      () => HomeController(),
      fenix: true,
    );
  }
}
