import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service để quản lý Firebase App Check
class AppCheckService {
  AppCheckService._internal();
  static final AppCheckService shared = AppCheckService._internal();

  bool _isInitialized = false;
  bool _isAvailable = false;

  // Cache token để tránh gọi nhiều lần
  String? _cachedToken;
  DateTime? _tokenExpiryTime;
  static const Duration _tokenCacheDuration =
      Duration(minutes: 50); // Token thường sống 1 giờ, cache 50 phút

  /// Khởi tạo Firebase App Check
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await FirebaseAppCheck.instance.activate(
        // Android provider
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        // iOS provider
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );

      _isInitialized = true;
      _isAvailable = true;
      if (kDebugMode) {
        print('✅ Firebase App Check initialized');
      }
    } on MissingPluginException catch (e) {
      _isInitialized = true;
      _isAvailable = false;
      if (kDebugMode) {
        print('⚠️ Firebase App Check không khả dụng (MissingPluginException)');
      }
    } catch (e) {
      _isInitialized = true; // Đánh dấu đã thử init
      _isAvailable = false;
      if (kDebugMode) {
        print('❌ Error initializing Firebase App Check: $e');
      }
    }
  }

  /// Kiểm tra xem App Check có available không
  bool get isAvailable => _isAvailable;

  /// Lấy App Check token (có cache)
  Future<String?> getToken({bool forceRefresh = false}) async {
    if (!_isAvailable) {
      if (kDebugMode) {
        print('⚠️ App Check không khả dụng, không thể lấy token');
      }
      return null;
    }

    try {
      if (!_isInitialized) {
        await init();
        if (!_isAvailable) {
          return null;
        }
      }

      // Kiểm tra cache nếu không force refresh
      if (!forceRefresh && _cachedToken != null && _tokenExpiryTime != null) {
        if (DateTime.now().isBefore(_tokenExpiryTime!)) {
          if (kDebugMode) {
            print('✅ Using cached App Check token');
          }
          return _cachedToken;
        } else {
          // Token đã hết hạn, xóa cache
          _cachedToken = null;
          _tokenExpiryTime = null;
        }
      }

      // Lấy token mới từ Firebase
      // getToken() trả về AppCheckToken? hoặc String? tùy version
      // Thử lấy token trực tiếp
      final appCheckTokenResult = await FirebaseAppCheck.instance.getToken();

      String? token;

      // Xử lý cả 2 trường hợp: AppCheckToken object hoặc String trực tiếp
      if (appCheckTokenResult != null) {
        if (appCheckTokenResult is String) {
          token = appCheckTokenResult;
        } else {
          // Nếu là object, thử lấy property token
          try {
            token = (appCheckTokenResult as dynamic).token as String?;
          } catch (e) {
            if (kDebugMode) {
              print('⚠️ Could not extract token from AppCheckToken: $e');
            }
            return null;
          }
        }
      }

      if (token != null && token.isNotEmpty) {
        // Cache token
        _cachedToken = token;
        _tokenExpiryTime = DateTime.now().add(_tokenCacheDuration);

        if (kDebugMode) {
          print(
              '✅ Got new App Check token (cached for ${_tokenCacheDuration.inMinutes} minutes)');
        }

        return token;
      }

      return null;
    } on MissingPluginException catch (e) {
      _isAvailable = false;
      if (kDebugMode) {
        print('⚠️ MissingPluginException khi lấy App Check token: $e');
      }
      return null;
    } on FirebaseException catch (e) {
      // Xử lý lỗi Firebase cụ thể
      if (kDebugMode) {
        print('❌ Firebase App Check error: ${e.code} - ${e.message}');
        if (e.code == 'app-check/app-attestation-failed' ||
            e.code == 'app-check/play-integrity-failed' ||
            e.message?.contains('App attestation failed') == true) {
          print(
              '💡 Tip: Đảm bảo bạn đã đăng ký debug token trong Firebase Console');
          print('💡 Hoặc đang test trên thiết bị thật (không phải simulator)');
          print(
              '💡 Vào Firebase Console > Project Settings > App Check để thêm debug token');
        }
      }
      // Xóa cache nếu có lỗi
      _cachedToken = null;
      _tokenExpiryTime = null;
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting App Check token: $e');
      }
      // Xóa cache nếu có lỗi
      _cachedToken = null;
      _tokenExpiryTime = null;
      return null;
    }
  }

  /// Xóa cache token (dùng khi cần refresh ngay)
  void clearCache() {
    _cachedToken = null;
    _tokenExpiryTime = null;
    if (kDebugMode) {
      print('🗑️ App Check token cache cleared');
    }
  }
}
