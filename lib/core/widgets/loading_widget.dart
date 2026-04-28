import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// Widget hiển thị loading indicator
class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor:
                color != null ? AlwaysStoppedAnimation<Color>(color!) : null,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class LoadingSpinKitFading extends StatelessWidget {
  final double? width;
  final double? height;
  final String? imageUrl;
  final Border? border;
  final Color? borderColor;
  final double? borderWidth;
  final BorderRadius? borderRadius;

  const LoadingSpinKitFading({
    super.key,
    this.width,
    this.height,
    this.imageUrl,
    this.border,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius =
        borderRadius ?? BorderRadius.circular(AppSizes.spacingM);
    return Container(
      width: width ?? 90,
      height: height ?? 90,
      decoration: BoxDecoration(
        color: AppColors.textSecondary,
        borderRadius: effectiveBorderRadius,
        border: border ??
            (borderColor != null || borderWidth != null
                ? Border.all(
                    color: borderColor ?? Colors.transparent,
                    width: borderWidth ?? 0,
                  )
                : null),
      ),
      child: ClipRRect(
        borderRadius: effectiveBorderRadius,
        child: _buildImageWidget(),
      ),
    );
  }

  Widget _buildImageWidget() {
    // Nếu không có imageUrl, hiển thị loading
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: AppColors.textSecondary,
        child: const Center(
          child: SpinKitFadingCircle(
            color: AppColors.disableColorText,
            size: 40,
          ),
        ),
      );
    }
    // Kiểm tra xem là URL hay local path
    final isUrl =
        imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://');
    if (isUrl) {
      // Dùng CachedNetworkImage cho URL
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.textSecondary,
          child: const Center(
            child: SpinKitFadingCircle(
              color: AppColors.disableColorText,
              size: 40,
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return Container(
            color: AppColors.textSecondary,
            child: const Icon(
              Icons.error,
              color: Colors.white,
            ),
          );
        },
        maxWidthDiskCache: 2048,
        maxHeightDiskCache: 2048,
      );
    } else {
      // Dùng Image.file cho local path
      final file = File(imageUrl!);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: AppColors.textSecondary,
              child: const Icon(
                Icons.error,
                color: Colors.white,
              ),
            );
          },
        );
      } else {
        // File không tồn tại
        return Container(
          color: AppColors.textSecondary,
          child: const Icon(
            Icons.error,
            color: Colors.white,
          ),
        );
      }
    }
  }
}
