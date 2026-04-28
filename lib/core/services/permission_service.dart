import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/utils/export_extensions.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Service kiểm tra và request permissions
class PermissionService extends GetxService {
  PermissionService._internal();

  static final PermissionService shared = PermissionService._internal();

  /// Kiểm tra quyền truy cập camera
  Future<bool> checkCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Request quyền truy cập camera
  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  /// Kiểm tra và request quyền camera (nếu chưa có)
  Future<bool> checkAndRequestCameraPermission() async {
    final hasPermission = await checkCameraPermission();
    if (hasPermission) {
      return true;
    }
    return await requestCameraPermission();
  }

  /// Kiểm tra quyền truy cập thư viện ảnh (photos)
  Future<bool> checkPhotosPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Request quyền truy cập thư viện ảnh (photos)
  Future<bool> requestPhotosPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Kiểm tra và request quyền photos (nếu chưa có)
  Future<bool> checkAndRequestPhotosPermission() async {
    final hasPermission = await checkPhotosPermission();
    if (hasPermission) {
      return true;
    }
    return await requestPhotosPermission();
  }

  /// Kiểm tra quyền truy cập thư viện ảnh (storage - cho Android cũ)
  Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  /// Request quyền truy cập storage (cho Android cũ)
  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Kiểm tra và request quyền storage (nếu chưa có)
  Future<bool> checkAndRequestStoragePermission() async {
    final hasPermission = await checkStoragePermission();
    if (hasPermission) {
      return true;
    }
    return await requestStoragePermission();
  }

  /// Kiểm tra quyền truy cập media library (cho Android 13+)
  Future<bool> checkMediaLibraryPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted;
  }

  /// Request quyền truy cập media library (cho Android 13+)
  Future<bool> requestMediaLibraryPermission() async {
    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Kiểm tra và request quyền media library (nếu chưa có)
  Future<bool> checkAndRequestMediaLibraryPermission() async {
    final hasPermission = await checkMediaLibraryPermission();
    if (hasPermission) {
      return true;
    }
    return await requestMediaLibraryPermission();
  }

  /// Kiểm tra quyền truy cập thư viện ảnh (tự động chọn permission phù hợp theo platform)
  Future<bool> checkLibraryPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ (API 33+) sử dụng photos
      // Android < 13 sử dụng storage
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;

      if (photosStatus.isGranted || storageStatus.isGranted) {
        return true;
      }
      return false;
    } else {
      // iOS sử dụng photos
      return await checkPhotosPermission();
    }
  }

  /// Request quyền truy cập thư viện ảnh (tự động chọn permission phù hợp theo platform)
  Future<bool> requestLibraryPermission() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.request();
      if (photosStatus.isGranted) {
        return true;
      }
      final storageStatus = await Permission.storage.request();
      return storageStatus.isGranted;
    } else {
      // iOS sử dụng photos
      return await requestPhotosPermission();
    }
  }

  /// Kiểm tra và request quyền thư viện ảnh (nếu chưa có)
  Future<bool> checkAndRequestLibraryPermission() async {
    final hasPermission = await checkLibraryPermission();
    if (hasPermission) {
      return true;
    }
    return await requestLibraryPermission();
  }

  /// Kiểm tra cả camera và library permissions
  Future<Map<String, bool>> checkCameraAndLibraryPermissions() async {
    return {
      'camera': await checkCameraPermission(),
      'library': await checkLibraryPermission(),
    };
  }

  /// Request cả camera và library permissions
  Future<Map<String, bool>> requestCameraAndLibraryPermissions() async {
    return {
      'camera': await requestCameraPermission(),
      'library': await requestLibraryPermission(),
    };
  }

  /// Kiểm tra permission có bị denied permanently không
  Future<bool> isCameraPermissionPermanentlyDenied() async {
    final status = await Permission.camera.status;
    return status.isPermanentlyDenied;
  }

  /// Kiểm tra permission có bị denied permanently không
  Future<bool> isLibraryPermissionPermanentlyDenied() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;

      return photosStatus.isPermanentlyDenied &&
          storageStatus.isPermanentlyDenied;
    } else {
      final status = await Permission.photos.status;
      return status.isPermanentlyDenied;
    }
  }

  /// Mở settings để user có thể cấp quyền thủ công
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Kiểm tra trạng thái permission
  Future<PermissionStatus> getCameraPermissionStatus() async {
    return await Permission.camera.status;
  }

  /// Kiểm tra trạng thái permission
  Future<PermissionStatus> getLibraryPermissionStatus() async {
    if (Platform.isAndroid) {
      final photosStatus = await Permission.photos.status;
      final storageStatus = await Permission.storage.status;

      if (photosStatus.isGranted || storageStatus.isGranted) {
        return PermissionStatus.granted;
      }

      if (photosStatus.isPermanentlyDenied ||
          storageStatus.isPermanentlyDenied) {
        return PermissionStatus.permanentlyDenied;
      }

      if (photosStatus.isDenied || storageStatus.isDenied) {
        return PermissionStatus.denied;
      }

      return photosStatus;
    } else {
      return await Permission.photos.status;
    }
  }

  static Future<bool> checkCameraPermissionAndRequest(
    BuildContext context, {
    VoidCallback? onPermissionDenied,
  }) async {
    // Kiểm tra trạng thái hiện tại
    final currentStatus =
        await PermissionService.shared.getCameraPermissionStatus();

    // Nếu đã được cấp quyền, return true
    if (currentStatus.isGranted) {
      return true;
    }

    // Nếu bị permanently denied, hiển thị dialog
    if (currentStatus.isPermanentlyDenied) {
      await _showPermissionDeniedDialog(
        context: context,
        permissionType: 'camera',
      );
      return false;
    }

    // Kiểm tra và request permission
    final hasPermission =
        await PermissionService.shared.checkAndRequestCameraPermission();

    if (!hasPermission) {
      final newStatus =
          await PermissionService.shared.getCameraPermissionStatus();

      if (newStatus.isPermanentlyDenied) {
        // Chỉ hiển thị dialog settings khi bị permanently denied
        await _showPermissionDeniedDialog(
          context: context,
          permissionType: 'camera',
        );
      } else {
        // Lần đầu từ chối: nếu có callback, gọi callback, nếu không thì show toast
        if (onPermissionDenied != null) {
          onPermissionDenied();
        } else {
          context.showErrorToast(tr('camera_permission_required'));
        }
      }
      return false;
    }
    return true;
  }

  static Future<bool> checkLibraryPermissionAndRequest(
    BuildContext context, {
    VoidCallback? onPermissionDenied,
  }) async {
    // Kiểm tra trạng thái hiện tại
    final currentStatus =
        await PermissionService.shared.getLibraryPermissionStatus();

    // Nếu đã được cấp quyền, return true
    if (currentStatus.isGranted) {
      return true;
    }

    // Nếu bị permanently denied, hiển thị dialog
    if (currentStatus.isPermanentlyDenied) {
      await _showPermissionDeniedDialog(
        context: context,
        permissionType: 'gallery',
      );
      return false;
    }

    // Nếu chưa được cấp, request permission
    final hasPermission =
        await PermissionService.shared.checkAndRequestLibraryPermission();

    if (!hasPermission) {
      final newStatus =
          await PermissionService.shared.getLibraryPermissionStatus();

      if (newStatus.isPermanentlyDenied) {
        // Chỉ hiển thị dialog settings khi bị permanently denied
        await _showPermissionDeniedDialog(
          context: context,
          permissionType: 'gallery',
        );
      } else {
        // Lần đầu từ chối: nếu có callback, gọi callback, nếu không thì show toast
        if (onPermissionDenied != null) {
          onPermissionDenied();
        } else {
          context.showErrorToast(tr('gallery_permission_required'));
        }
      }
      return false;
    }
    return true;
  }

  /// Hiển thị dialog khi permission bị denied permanently
  static Future<void> _showPermissionDeniedDialog({
    required BuildContext context,
    required String permissionType,
  }) async {
    final permissionName =
        permissionType == 'camera' ? tr('camera') : tr('gallery');

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text(
          tr('permission_required'),
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          tr('permission_denied_message', namedArgs: {
            'value': permissionName,
          }),
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              tr('cancel'),
              style: const TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await PermissionService.shared.openSettings();
            },
            child: Text(
              tr('open_settings'),
              style: const TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
