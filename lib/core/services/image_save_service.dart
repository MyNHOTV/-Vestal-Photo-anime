import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:gal/gal.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'permission_service.dart';
import 'package:flutter_svg/flutter_svg.dart' as vg;

/// Service để save ảnh vào gallery với các size khác nhau
class ImageSaveService extends GetxService {
  ImageSaveService._internal();
  static final ImageSaveService shared = ImageSaveService._internal();

  /// Helper method để lấy imageBytes từ imagePath (URL, file path, hoặc base64)
  Future<Uint8List> _getImageBytesFromPath(String imagePath) async {
    final isUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final isBase64 = _isBase64(imagePath);

    if (isUrl) {
      // Download ảnh từ URL
      final dio = Dio();
      final response = await dio.get<Uint8List>(
        imagePath,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data ?? Uint8List(0);
    } else if (isBase64) {
      // Decode base64
      try {
        String base64String = imagePath;
        // Nếu có prefix data:image, loại bỏ nó
        if (base64String.startsWith('data:image/')) {
          final commaIndex = base64String.indexOf(',');
          if (commaIndex != -1) {
            base64String = base64String.substring(commaIndex + 1);
          }
        }
        return base64Decode(base64String);
      } catch (e) {
        print('Lỗi khi decode base64: $e');
        throw Exception('Không thể decode base64: $e');
      }
    } else {
      // Đọc từ file local
      final file = File(imagePath);
      if (!await file.exists()) {
        throw Exception('File không tồn tại: $imagePath');
      }
      return await file.readAsBytes();
    }
  }

  /// Kiểm tra xem imagePath có phải là base64 không
  bool _isBase64(String path) {
    if (path.isEmpty) return false;
    if (path.startsWith('data:image/')) return true;
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Pattern.hasMatch(path) && path.length > 100;
  }

  /// Save ảnh vào gallery với size tùy chỉnh
  ///
  /// [imagePath] - Đường dẫn file ảnh hoặc URL cần save
  /// [width] - Chiều rộng mới (nếu null giữ nguyên)
  /// [height] - Chiều cao mới (nếu null giữ nguyên)
  ///
  /// Returns: Đường dẫn file đã save hoặc null nếu lỗi
  Future<String?> saveImageToGallery({
    required String imagePath,
    int? width,
    int? height,
  }) async {
    try {
      // Kiểm tra và request permission
      final hasPermission =
          await PermissionService.shared.checkAndRequestLibraryPermission();

      if (!hasPermission) {
        throw Exception(tr('no_library_permission'));
      }

      // Sử dụng helper method để lấy imageBytes
      Uint8List imageBytes = await _getImageBytesFromPath(imagePath);

      // Resize ảnh nếu có width hoặc height
      if (width != null || height != null) {
        final originalImage = img.decodeImage(imageBytes);
        if (originalImage == null) {
          throw Exception('Không thể decode ảnh');
        }

        // Tính toán size mới
        int newWidth = width ?? originalImage.width;
        int newHeight = height ?? originalImage.height;

        // Nếu chỉ có 1 trong 2, tính theo tỷ lệ
        if (width != null && height == null) {
          final ratio = width / originalImage.width;
          newHeight = (originalImage.height * ratio).round();
        } else if (height != null && width == null) {
          final ratio = height / originalImage.height;
          newWidth = (originalImage.width * ratio).round();
        }

        // Resize ảnh
        final resizedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear,
        );

        // Encode lại thành bytes (dùng JPEG để giảm dung lượng)
        imageBytes = Uint8List.fromList(
          img.encodeJpg(resizedImage, quality: 100),
        );
      }
      // Lưu vào thư mục riêng của app (thay vì temp)
      final appDir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${appDir.path}/saved_images');
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      // Tạo file trong thư mục app
      final savedFile = File(
        '${savedDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await savedFile.writeAsBytes(imageBytes);

      // Copy vào gallery (nếu cần)
      await Gal.putImage(savedFile.path);

      // Trả về path file trong thư mục app (KHÔNG phải gallery path)
      return savedFile.path;
    } catch (e) {
      print('Lỗi khi save ảnh vào gallery: $e');
      rethrow;
    }
  }

  /// Save ảnh với size cụ thể (Small, Medium, Large)
  ///
  /// [imagePath] - Đường dẫn file ảnh
  /// [size] - Size cần save: 'small', 'medium', 'large'
  /// [aspectRatio] - Aspect ratio: '1:1', '3:4', '9:16', '4:3', '16:9'
  Future<String?> saveImageWithSize({
    required String imagePath,
    required String size, // 'small', 'medium', 'large'
    required String aspectRatio, // '1:1', '3:4', '9:16', '4:3', '16:9'
  }) async {
    final dimensions = _getDimensions(size, aspectRatio);
    return await saveImageToGallery(
      imagePath: imagePath,
      width: dimensions['width'],
      height: dimensions['height'],
    );
  }

  /// Lấy dimensions theo size và aspect ratio
  Map<String, int?> _getDimensions(String size, String aspectRatio) {
    final sizeMap = {
      'small': 0,
      'medium': 1,
      'large': 2,
    };

    final sizeIndex = sizeMap[size.toLowerCase()] ?? 0;

    final dimensionsMap = {
      '1:1': [
        {'width': 512, 'height': 512},
        {'width': 768, 'height': 768},
        {'width': 1024, 'height': 1024},
      ],
      '3:4': [
        {'width': 432, 'height': 576},
        {'width': 648, 'height': 864},
        {'width': 864, 'height': 1152},
      ],
      '9:16': [
        {'width': 378, 'height': 672},
        {'width': 567, 'height': 1008},
        {'width': 756, 'height': 1344},
      ],
      '4:3': [
        {'width': 576, 'height': 432},
        {'width': 864, 'height': 648},
        {'width': 1152, 'height': 864},
      ],
      '16:9': [
        {'width': 672, 'height': 378},
        {'width': 1008, 'height': 567},
        {'width': 1344, 'height': 756},
      ],
    };

    final dimensions =
        dimensionsMap[aspectRatio]?[sizeIndex] ?? {'width': 512, 'height': 512};

    return {
      'width': dimensions['width'] as int,
      'height': dimensions['height'] as int,
    };
  }

  Future<String?> saveImageWithWatermark({
    required String imagePath,
    required BuildContext context,
  }) async {
    try {
      final hasPermission =
          await PermissionService.shared.checkAndRequestLibraryPermission();

      if (!hasPermission) {
        throw Exception(tr('no_library_permission'));
      }

      // Sử dụng helper method để lấy imageBytes
      Uint8List imageBytes = await _getImageBytesFromPath(imagePath);

      // Decode image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Không thể decode ảnh');
      }

      // Add watermark (truyền context)
      final watermarkedImage = await _addWatermarkIcon(originalImage, context);

      // Encode lại
      imageBytes = Uint8List.fromList(
        img.encodeJpg(watermarkedImage, quality: 100),
      );

      // Save file
      final appDir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${appDir.path}/saved_images');
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      final savedFile = File(
        '${savedDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await savedFile.writeAsBytes(imageBytes);

      await Gal.putImage(savedFile.path);

      return savedFile.path;
    } catch (e) {
      print('Lỗi khi save ảnh với watermark: $e');
      rethrow;
    }
  }

  /// Thêm watermark icon vào ảnh bằng cách chụp widget
  Future<img.Image> _addWatermarkIcon(
    img.Image image,
    BuildContext context,
  ) async {
    try {
      // Chụp widget thành image bytes
      final watermarkBytes = await _captureWidgetToImageBytes(
        context: context,
        widget: const SvgIcon(
          name: 'ic_generate_ai',
          width: 80,
          height: 80,
          color: Color(0x8AFFFFFF), // Colors.white54
        ),
        width: 80,
        height: 80,
      );

      if (watermarkBytes == null) {
        return image; // Return original nếu không chụp được
      }

      // Decode watermark image
      final watermarkImage = img.decodeImage(watermarkBytes);
      if (watermarkImage == null) {
        return image;
      }

      // Tính toán vị trí watermark (bottom right với padding 12px)
      final padding = 12;
      final watermarkWidth = watermarkImage.width;
      final watermarkHeight = watermarkImage.height;

      final x = image.width - watermarkWidth - padding;
      final y = image.height - watermarkHeight - padding;

      // Composite watermark lên ảnh gốc
      return img.compositeImage(
        image,
        watermarkImage,
        dstX: x,
        dstY: y,
      );
    } catch (e) {
      print('Lỗi khi thêm watermark: $e');
      return image; // Return original nếu có lỗi
    }
  }

  /// Chụp widget thành image bytes sử dụng screenshot package
  Future<Uint8List?> _captureWidgetToImageBytes({
    required BuildContext context,
    required Widget widget,
    required double width,
    required double height,
  }) async {
    try {
      final screenshotController = ScreenshotController();

      // Tạo widget với Screenshot
      final screenshotWidget = Screenshot(
        controller: screenshotController,
        child: Container(
          width: width,
          height: height,
          color: Colors.transparent,
          child: widget,
        ),
      );

      // Render widget vào overlay (ẩn)
      final overlay = Overlay.of(context);
      final overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: -10000, // Đặt ngoài màn hình để không thấy
          top: -10000,
          child: Material(
            type: MaterialType.transparency,
            child: screenshotWidget,
          ),
        ),
      );

      overlay.insert(overlayEntry);

      // Đợi widget được render
      await Future.delayed(const Duration(milliseconds: 100));
      await WidgetsBinding.instance.endOfFrame;

      // Chụp screenshot
      final imageBytes = await screenshotController.capture(
        pixelRatio: 3.0, // High DPI
      );

      // Cleanup
      overlayEntry.remove();

      return imageBytes;
    } catch (e) {
      print('Lỗi khi chụp widget: $e');
      return null;
    }
  }

  Future<String?> saveImageWithoutWatermark({
    required String imagePath,
  }) async {
    try {
      final hasPermission =
          await PermissionService.shared.checkAndRequestLibraryPermission();

      if (!hasPermission) {
        throw Exception(tr('no_library_permission'));
      }

      // Sử dụng helper method để lấy imageBytes
      Uint8List imageBytes = await _getImageBytesFromPath(imagePath);

      // Save file (không thêm watermark, giữ nguyên ảnh gốc)
      final appDir = await getApplicationDocumentsDirectory();
      final savedDir = Directory('${appDir.path}/saved_images');
      if (!await savedDir.exists()) {
        await savedDir.create(recursive: true);
      }

      final savedFile = File(
        '${savedDir.path}/image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await savedFile.writeAsBytes(imageBytes);

      await Gal.putImage(savedFile.path);

      return savedFile.path;
    } catch (e) {
      print('Lỗi khi save ảnh: $e');
      rethrow;
    }
  }

  /// Share ảnh với watermark
  Future<File?> shareImageWithWatermark({
    required String imagePath,
    required BuildContext context,
  }) async {
    try {
      // Sử dụng helper method để lấy imageBytes
      Uint8List imageBytes = await _getImageBytesFromPath(imagePath);

      // Decode image
      img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) {
        throw Exception('Không thể decode ảnh');
      }

      // Add watermark
      final watermarkedImage = await _addWatermarkIcon(originalImage, context);

      // Encode lại
      imageBytes = Uint8List.fromList(
        img.encodeJpg(watermarkedImage, quality: 100),
      );

      // Save vào temp file để share
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/share_watermark_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(imageBytes);

      return tempFile;
    } catch (e) {
      print('Lỗi khi tạo ảnh với watermark để share: $e');
      rethrow;
    }
  }

  /// Share ảnh không có watermark
  Future<File?> shareImageWithoutWatermark({
    required String imagePath,
  }) async {
    try {
      // Sử dụng helper method để lấy imageBytes
      Uint8List imageBytes = await _getImageBytesFromPath(imagePath);

      // Save vào temp file để share (không thêm watermark)
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
        '${tempDir.path}/share_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await tempFile.writeAsBytes(imageBytes);

      return tempFile;
    } catch (e) {
      print('Lỗi khi tạo ảnh để share: $e');
      rethrow;
    }
  }
}
