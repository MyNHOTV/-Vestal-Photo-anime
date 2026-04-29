import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/crashlytics_service.dart';
import 'package:get/get.dart';
import '../routes/app_routes.dart';
import '../storage/local_storage_service.dart';
import '../../features/image_generation/domain/entities/generated_image.dart';
import '../../features/image_generation/data/datasources/generated_image_local_datasource.dart';

/// Top-level function để xử lý background messages
/// Phải là top-level function, không thể là method của class
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📬 Background message received: ${message.messageId}');
    print('Title: ${message.notification?.title}');
    print('Body: ${message.notification?.body}');
    print('Data: ${message.data}');
  }

  // // Log to Crashlytics
  // try {
  //   await CrashlyticsService.shared.log(
  //     'Background notification received: ${message.messageId}',
  //   );
  // } catch (e) {
  //   if (kDebugMode) {
  //     print('Error logging background message: $e');
  //   }
  // }
}

class FirebaseMessagingService {
  FirebaseMessagingService._internal();

  static final FirebaseMessagingService shared =
      FirebaseMessagingService._internal();

  // Lazy: tránh crash khi Firebase chưa init.
  FirebaseMessaging? __messaging;
  FirebaseMessaging get _messaging => __messaging ??= FirebaseMessaging.instance;

  // Stream controller để lắng nghe token changes
  final _tokenController = StreamController<String?>.broadcast();
  Stream<String?> get tokenStream => _tokenController.stream;

  String? _currentToken;
  String? get currentToken => _currentToken;

  // Lưu pending navigation message khi app đang khởi động
  RemoteMessage? _pendingNavigationMessage;
  bool _isAppReady = false;

  /// Khởi tạo Firebase Messaging
  Future<void> init() async {
    try {
      // Yêu cầu quyền thông báo (iOS)
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print(
            '📱 Notification permission status: ${settings.authorizationStatus}');
      }

      // Đăng ký background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Lắng nghe foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Lắng nghe khi user tap vào notification (app đang mở)
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Kiểm tra nếu app được mở từ notification khi app đang terminated
      RemoteMessage? initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        if (kDebugMode) {
          print('📱 App được mở từ notification (initial message)');
        }
        // Lưu message để xử lý sau khi app sẵn sàng
        _pendingNavigationMessage = initialMessage;
      }

      // Lấy FCM token
      await _getToken();

      // Tự động subscribe vào topic "all_users" để nhận notification gửi đến tất cả user
      await subscribeToTopic('all_users');

      // Lắng nghe token refresh
      _messaging.onTokenRefresh.listen((String newToken) async {
        _currentToken = newToken;
        _tokenController.add(newToken);
        if (kDebugMode) {
          print('🔄 FCM Token refreshed: $newToken');
        }
        _onTokenRefresh(newToken);
        // Re-subscribe vào topic khi token refresh
        await subscribeToTopic('all_users');
      });

      if (kDebugMode) {
        print('✅ Firebase Messaging initialized successfully');
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Error initializing Firebase Messaging: $e');
      }
      await CrashlyticsService.shared.recordError(
        e,
        stack,
        reason: 'Firebase Messaging init failed',
      );
    }
  }

  /// Lấy FCM token
  Future<String?> _getToken() async {
    try {
      _currentToken = await _messaging.getToken();
      _tokenController.add(_currentToken);
      if (kDebugMode) {
        print('🔑 FCM Token: $_currentToken');
      }
      return _currentToken;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting FCM token: $e');
      }
      return null;
    }
  }

  /// Xử lý foreground messages (khi app đang mở)
  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      print('📬 Foreground message received: ${message.messageId}');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
    }

    // Log to Crashlytics
    CrashlyticsService.shared.log(
      'Foreground notification: ${message.messageId}',
    );

    // Hiển thị notification trong app (tùy chọn)
    _showLocalNotification(message);
  }

  /// Xử lý khi user tap vào notification
  void _handleMessageOpenedApp(RemoteMessage message) {
    if (kDebugMode) {
      print('👆 Notification tapped: ${message.messageId}');
      print('Data: ${message.data}');
    }

    // Log to Crashlytics
    CrashlyticsService.shared.log(
      'Notification opened: ${message.messageId}',
    );

    // Kiểm tra xem app đã sẵn sàng chưa
    if (!_isAppReady || Get.context == null || !Get.context!.mounted) {
      // App chưa sẵn sàng, lưu message để xử lý sau
      _pendingNavigationMessage = message;
      if (kDebugMode) {
        print('⏳ App chưa sẵn sàng, lưu navigation message để xử lý sau');
      }
      return;
    }

    // App đã sẵn sàng, xử lý navigation ngay
    _handleNotificationNavigation(message);
  }

  /// Đánh dấu app đã sẵn sàng và xử lý pending navigation nếu có
  void markAppReady() {
    // Kiểm tra xem user đã hoàn thành onboarding chưa
    final hasCompletedOnboarding = LocalStorageService.shared.get<bool>(
          'has_completed_onboarding',
          defaultValue: false,
        ) ??
        false;

    if (!hasCompletedOnboarding) {
      if (kDebugMode) {
        print('⏸️ User chưa hoàn thành onboarding, bỏ qua pending navigation');
      }
      // Xóa pending message nếu user chưa hoàn thành onboarding
      _pendingNavigationMessage = null;
      return;
    }

    _isAppReady = true;
    if (kDebugMode) {
      print('✅ App đã sẵn sàng (user đã hoàn thành onboarding)');
    }

    // Nếu có pending navigation message, xử lý ngay
    if (_pendingNavigationMessage != null) {
      if (kDebugMode) {
        print('🚀 Thực hiện pending navigation');
      }
      // Đợi một chút để đảm bảo navigation stack đã sẵn sàng
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_pendingNavigationMessage != null) {
          final message = _pendingNavigationMessage!;
          _pendingNavigationMessage = null;
          _handleNotificationNavigation(message);
        }
      });
    }
  }

  /// Hiển thị local notification khi app đang mở (foreground)
  void _showLocalNotification(RemoteMessage message) {
    // Có thể sử dụng flutter_local_notifications package để hiển thị
    // Hoặc hiển thị custom dialog/snackbar
    if (Get.context != null && Get.context!.mounted) {
      final notification = message.notification;
      if (notification != null) {
        Get.snackbar(
          notification.title ?? 'Notification',
          notification.body ?? '',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.black87,
          colorText: Colors.white,
          margin: const EdgeInsets.all(16),
          borderRadius: 8,
          onTap: (_) {
            _handleNotificationNavigation(message);
          },
        );
      }
    }
  }

  /// Xử lý navigation dựa trên data trong notification
  Future<void> _handleNotificationNavigation(RemoteMessage message) async {
    try {
      final data = message.data;

      if (kDebugMode) {
        print('🧭 Handling navigation with data: $data');
      }

      // Đợi một chút để đảm bảo context đã sẵn sàng
      int attempts = 0;
      while ((Get.context == null || !Get.context!.mounted) && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }

      if (Get.context == null || !Get.context!.mounted) {
        if (kDebugMode) {
          print('⚠️ Context chưa sẵn sàng sau 2 giây, bỏ qua navigation');
        }
        return;
      }

      // Kiểm tra xem có type không
      if (!data.containsKey('type')) {
        if (kDebugMode) {
          print('⚠️ Notification không có type, điều hướng về home');
        }
        _navigateToHome();
        return;
      }

      final type = data['type'] as String;

      switch (type) {
        case 'image_detail':
          await _navigateToImageDetail(data);
          break;
        case 'home':
          _navigateToHome();
          break;
        case 'library':
          _navigateToLibrary();
          break;
        case 'history':
          _navigateToHistory();
          break;
        case 'profile':
          _navigateToProfile();
          break;
        case 'generate':
          _navigateToGenerate();
          break;
        case 'list_style':
          _navigateToListStyle(data);
          break;
        default:
          if (kDebugMode) {
            print('⚠️ Unknown notification type: $type, điều hướng về home');
          }
          _navigateToHome();
      }
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Error handling notification navigation: $e');
      }
      await CrashlyticsService.shared.recordError(
        e,
        stack,
        reason: 'Notification navigation failed',
      );
      // Fallback: điều hướng về home
      _navigateToHome();
    }
  }

  /// Điều hướng đến màn hình Image Detail
  Future<void> _navigateToImageDetail(Map<String, dynamic> data) async {
    try {
      if (!data.containsKey('image_id')) {
        if (kDebugMode) {
          print('⚠️ Notification thiếu image_id, điều hướng về home');
        }
        _navigateToHome();
        return;
      }

      final imageId = data['image_id'] as String;

      if (kDebugMode) {
        print('🖼️ Navigating to image detail with ID: $imageId');
      }

      // Thử lấy image từ local storage
      GeneratedImage? image;
      try {
        if (Get.isRegistered<GeneratedImageLocalDataSource>()) {
          final localDataSource = Get.find<GeneratedImageLocalDataSource>();
          final model = await localDataSource.getImageById(imageId);
          if (model != null) {
            image = model.toEntity();
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Không thể lấy image từ local storage: $e');
        }
      }

      // Nếu không tìm thấy image trong local storage, điều hướng về home
      if (image == null) {
        if (kDebugMode) {
          print(
              '⚠️ Image không tìm thấy trong local storage (ID: $imageId), điều hướng về home');
        }
        _navigateToHome();
        return;
      }

      // Điều hướng đến màn hình image detail
      if (Get.context != null && Get.context!.mounted) {
        Get.toNamed(
          AppRoutes.imageDetail,
          arguments: image,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error navigating to image detail: $e');
      }
      _navigateToHome();
    }
  }

  /// Điều hướng đến màn hình Home
  void _navigateToHome() {
    if (Get.context != null && Get.context!.mounted) {
      Get.offAllNamed(AppRoutes.mainTabar);
    }
  }

  /// Điều hướng đến màn hình Library
  void _navigateToLibrary() {
    if (Get.context != null && Get.context!.mounted) {
      Get.toNamed(AppRoutes.library);
    }
  }

  /// Điều hướng đến màn hình History
  void _navigateToHistory() {
    if (Get.context != null && Get.context!.mounted) {
      Get.toNamed(AppRoutes.history);
    }
  }

  /// Điều hướng đến màn hình Profile
  void _navigateToProfile() {
    if (Get.context != null && Get.context!.mounted) {
      Get.toNamed(AppRoutes.profile);
    }
  }

  /// Điều hướng đến màn hình Generate
  void _navigateToGenerate() {
    if (Get.context != null && Get.context!.mounted) {
      Get.toNamed(AppRoutes.generate);
    }
  }

  /// Điều hướng đến màn hình List Style
  void _navigateToListStyle(Map<String, dynamic> data) {
    if (Get.context != null && Get.context!.mounted) {
      final args = <String, dynamic>{
        'isView': data['isView'] ?? true,
        'styles': data['styles'] ?? [],
        'initialSelectedIndex': data['initialSelectedIndex'],
      };
      Get.toNamed(AppRoutes.listStyle, arguments: args);
    }
  }

  /// Callback khi token được refresh
  void _onTokenRefresh(String newToken) {
    // Có thể gửi token mới lên server
    // Ví dụ: await apiService.updateFcmToken(newToken);
    if (kDebugMode) {
      print('Token refreshed, should update on server: $newToken');
    }
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        print('✅ Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error subscribing to topic $topic: $e');
      }
    }
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        print('✅ Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error unsubscribing from topic $topic: $e');
      }
    }
  }

  /// Delete token (logout)
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      _currentToken = null;
      _tokenController.add(null);
      if (kDebugMode) {
        print('🗑️ FCM Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting FCM token: $e');
      }
    }
  }

  void dispose() {
    _tokenController.close();
  }
}
