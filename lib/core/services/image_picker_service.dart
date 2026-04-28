import 'dart:async';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'permission_service.dart';

/// Service để chọn ảnh từ camera, gallery hoặc file
class ImagePickerService extends GetxService {
  ImagePickerService._internal();

  static final ImagePickerService shared = ImagePickerService._internal();

  final ImagePicker _picker = ImagePicker();

  // Track ongoing image pick request để tránh concurrent calls
  Future<File?>? _ongoingPickImageRequest;

  // Flag để track đang pick image (dùng cho resume check)
  bool _isPickingImage = false;

  // Getter để check xem có đang pick image không
  bool get isPickingImage => _isPickingImage;

  // Track ongoing camera pick request để tránh concurrent calls
  Future<File?>? _ongoingPickCameraRequest;

  // Flag để track đang pick camera (dùng cho resume check)
  bool _isPickingCamera = false;

  // Getter để check xem có đang pick camera không
  bool get isPickingCamera => _isPickingCamera;

  bool _isSharing = false;

  bool get isPicking => _isPickingImage || _isPickingCamera || _isSharing;

  void setSharing(bool value) {
    _isSharing = value;
  }

  /// Chọn ảnh từ gallery
  Future<File?> pickImageFromGallery(BuildContext context) async {
    // Nếu đã có request đang chạy, trả về request đó
    if (_ongoingPickImageRequest != null) {
      return await _ongoingPickImageRequest!;
    }

    // Set flag khi bắt đầu pick
    _isPickingImage = true;

    // Tạo request mới và lưu lại
    _ongoingPickImageRequest = _performPickImageFromGallery(context);
    try {
      final result = await _ongoingPickImageRequest!;
      return result;
    } finally {
      // Xóa tracking khi xong
      _ongoingPickImageRequest = null;
      // Reset flag sau một chút delay để app resume có thể check được
      Future.delayed(const Duration(milliseconds: 500), () {
        _isPickingImage = false;
      });
    }
  }

  /// Method thực hiện pick image từ gallery
  Future<File?> _performPickImageFromGallery(BuildContext context) async {
    try {
      final hasPermission =
          await PermissionService.checkLibraryPermissionAndRequest(context);
      if (!hasPermission) {
        _isPickingImage = false; // Reset ngay nếu không có permission
        return null;
      }
      // Chọn ảnh sau khi có quyền
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null) {
        // Reset flag nếu user cancel (sẽ được reset trong finally sau delay)
        return null;
      }
      return File(image.path);
    } catch (e) {
      _isPickingImage = false; // Reset flag nếu có lỗi
      print('Lỗi khi chọn ảnh từ gallery: $e');
      rethrow;
    }
  }

  /// Chọn ảnh từ camera
  Future<File?> pickImageFromCamera(BuildContext context) async {
    // Nếu đã có request đang chạy, trả về request đó
    if (_ongoingPickCameraRequest != null) {
      return await _ongoingPickCameraRequest!;
    }

    // Set flag khi bắt đầu pick
    _isPickingCamera = true;

    // Tạo request mới và lưu lại
    _ongoingPickCameraRequest = _performPickImageFromCamera(context);
    try {
      final result = await _ongoingPickCameraRequest!;
      return result;
    } finally {
      // Xóa tracking khi xong
      _ongoingPickCameraRequest = null;
      // Reset flag sau một chút delay để app resume có thể check được
      Future.delayed(const Duration(milliseconds: 500), () {
        _isPickingCamera = false;
      });
    }
  }

  /// Method thực hiện pick image từ camera
  Future<File?> _performPickImageFromCamera(BuildContext context) async {
    try {
      final hasPermission =
          await PermissionService.checkCameraPermissionAndRequest(context);
      if (!hasPermission) {
        _isPickingCamera = false; // Reset ngay nếu không có permission
        return null;
      }
      // Chọn ảnh sau khi có quyền
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (image == null) {
        // Reset flag nếu user cancel (sẽ được reset trong finally sau delay)
        return null;
      }
      return File(image.path);
    } catch (e) {
      _isPickingCamera = false; // Reset flag nếu có lỗi
      print('Lỗi khi chọn ảnh từ camera: $e');
      rethrow;
    }
  }
}
