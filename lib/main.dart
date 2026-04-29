import 'dart:async';
import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/app_check_service.dart';
import 'package:flutter_quick_base/core/services/crashlytics_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/services/screen_protector.dart';
import 'package:flutter_quick_base/features/home/data/datasources/home_data_source.dart';
import 'package:get/get.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/daily_generation_service.dart';
import 'core/storage/local_storage_service.dart';
import 'firebase_options.dart';

// Firebase được cấu hình cho Android (google-services.json + firebase_options.dart).
// iOS chưa có GoogleService-Info.plist thực → bỏ qua để app vẫn build/chạy được.
final bool kFirebaseEnabled = !kIsWeb && Platform.isAndroid;

Future<void> main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    await EasyLocalization.ensureInitialized();

    // Flavors via --dart-define
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
    const enableLog = bool.fromEnvironment('ENABLE_LOG', defaultValue: true);

    await dotenv.load(fileName: _envFileFor(flavor));

    if (kFirebaseEnabled) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        AnalyticsService.shared.init();
        await CrashlyticsService.shared.init();
        CrashlyticsService.shared.log('App started');
        await AppCheckService.shared.init();
      } catch (e, stack) {
        debugPrint('Firebase init failed: $e\n$stack');
      }
    } else {
      debugPrint('Firebase disabled (kFirebaseEnabled=false)');
    }

    // Initialize Local Storage
    await LocalStorageService.shared.init();

    // Initialize Daily Generation Service
    await DailyGenerationService.shared.init();

    // Initialize Connectivity Service
    await ConnectivityService.shared.init();

    // Initialize Remote Config Service (skips if Firebase disabled)
    if (kFirebaseEnabled) {
      await RemoteConfigService.shared.init();
    }
    if (ConnectivityService.shared.isConnected) {
      unawaited(
        HomeDataSource.fetchImageStyles().catchError((error) {
          print('Error fetching image styles in main: $error');
        }),
      );
      unawaited(
        HomeDataSource.fetchImageStyleGroups().catchError((error) {
          print('Error fetching group in main: $error');
        }),
      );
    }

    // Listen connectivity changes để fetch khi mạng về
    ever(ConnectivityService.shared.connectivityStatus, (results) {
      if (ConnectivityService.shared.isConnected) {
        // Mạng về, fetch styles nếu cần
        HomeDataSource.fetchWhenOnline().catchError((error) {
          print('Error fetching image styles when online: $error');
        });
      }
    });

    AppConfig.init(
      flavor: flavor,
      enableLog: enableLog,
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
    );

    // Initialize Dependency Injection
    InjectionContainer.init();

    runApp(
      EasyLocalization(
        supportedLocales: const [
          Locale('en'),
          Locale('vi'),
          Locale('hi'),
          Locale('es'),
          Locale('fr'),
          Locale('pt'),
          Locale('ja'),
          Locale('ko'),
          Locale('tr'),
          Locale('de'),
          Locale('hr'),
          Locale('hu'),
          Locale('id'),
          Locale('it'),
          Locale('ne'),
          Locale('th'),
          Locale('uk'),
          Locale('zh'),
          Locale('ar'),
        ],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        child: const QuickBaseApp(),
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shouldEnable =
          RemoteConfigService.shared.shouldEnableScreenProtection;
      ScreenProtectorService.shared.setProtection(shouldEnable);
    });
    ever(RemoteConfigService.shared.enableScreenProtection, (bool enable) {
      ScreenProtectorService.shared.setProtection(enable);
      print(
          'Screen protection ${enable ? "enabled" : "disabled"} (updated from Remote Config)');
    });
  }, (error, stack) {
    if (kFirebaseEnabled) {
      CrashlyticsService.shared.recordError(
        error,
        stack,
        reason: 'Uncaught async error in runZonedGuarded',
        fatal: true,
      );
    } else {
      debugPrint('Uncaught async error: $error\n$stack');
    }
  });
}

String _envFileFor(String flavor) {
  switch (flavor) {
    case 'prod':
      return '.env.prod';
    case 'stg':
      return '.env.stg';
    case 'dev':
    default:
      return '.env.dev';
  }
}
