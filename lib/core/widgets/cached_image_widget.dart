import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Widget helper để hiển thị ảnh với cache tự động
/// Hỗ trợ cả URL, file path và base64
class CachedImageWidget extends StatelessWidget {
  const CachedImageWidget({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  /// Kiểm tra xem imagePath có phải là base64 không
  bool _isBase64(String path) {
    if (path.isEmpty) return false;
    if (path.startsWith('data:image/')) return true;
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Pattern.hasMatch(path) && path.length > 100;
  }

  @override
  Widget build(BuildContext context) {
    final isUrl =
        imagePath.startsWith('http://') || imagePath.startsWith('https://');
    final isBase64 = _isBase64(imagePath);

    Widget imageWidget;

    if (isUrl) {
      // Dùng CachedNetworkImage cho URL
      // Kiểm tra width/height có phải infinity hoặc NaN không
      int? memCacheWidth;
      int? memCacheHeight;

      if (width != null && width!.isFinite) {
        memCacheWidth = width!.toInt();
      }

      if (height != null && height!.isFinite) {
        memCacheHeight = height!.toInt();
      }
      imageWidget = CachedNetworkImage(
        imageUrl: imagePath,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildDefaultError(),
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        maxWidthDiskCache: 2048,
        maxHeightDiskCache: 2048,
      );
    } else if (isBase64) {
      // Xử lý base64
      try {
        String base64String = imagePath;
        // Nếu có prefix data:image, loại bỏ nó
        if (base64String.startsWith('data:image/')) {
          final commaIndex = base64String.indexOf(',');
          if (commaIndex != -1) {
            base64String = base64String.substring(commaIndex + 1);
          }
        }
        final imageBytes = base64Decode(base64String);
        imageWidget = Image.memory(
          imageBytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _buildDefaultError(),
        );
      } catch (e) {
        print('Lỗi khi decode base64: $e');
        imageWidget = errorWidget ?? _buildDefaultError();
      }
    } else {
      // Dùng Image.file cho file path
      final file = File(imagePath);
      if (file.existsSync()) {
        imageWidget = Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _buildDefaultError(),
        );
      } else {
        imageWidget = errorWidget ?? _buildDefaultError();
      }
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width?.isFinite == true ? width : null,
      height: height?.isFinite == true ? height : null,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildDefaultError() {
    return Container(
      width: width?.isFinite == true ? width : null,
      height: height?.isFinite == true ? height : null,
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 48,
        ),
      ),
    );
  }
}
