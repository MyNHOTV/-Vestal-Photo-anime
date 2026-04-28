import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';
import 'package:get/get.dart';

class StyleCardWidget extends StatelessWidget {
  final ImageStyleModel style;
  final bool isLayoutType1;
  final double cardWidth;
  final double cardHeight;
  final Function(ImageStyleModel)? onStyleSelected;

  const StyleCardWidget({
    super.key,
    required this.style,
    required this.isLayoutType1,
    required this.cardWidth,
    required this.cardHeight,
    this.onStyleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (Get.isRegistered<NetworkService>()) {
          final hasNetwork =
              await NetworkService.to.checkNetworkForInAppFunction();
          if (!hasNetwork) {
            debugPrint('🌐 No network, blocking style selection');
            return;
          }
        }
        onStyleSelected?.call(style);
      },
      child: Container(
        height: cardHeight,
        margin: const EdgeInsets.only(right: AppSizes.spacingS),
        child: Column(
          children: [
            if (isLayoutType1 == true)
              Stack(
                children: [
                  // Image
                  Container(
                    height: cardHeight,
                    width: cardWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      child: _buildImageWidget(),
                    ),
                  ),
                  // Text overlay ở dưới cùng
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(AppSizes.radiusL),
                        bottomRight: Radius.circular(AppSizes.radiusL),
                        topLeft: Radius.circular(AppSizes.radiusL),
                        topRight: Radius.circular(AppSizes.radiusL),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.29),
                                Colors.white.withOpacity(0.59),
                                AppColors.colorECE8F7
                              ],
                            ),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(AppSizes.radiusL),
                              bottomRight: Radius.circular(AppSizes.radiusL),
                              topLeft: Radius.circular(AppSizes.radiusL),
                              topRight: Radius.circular(AppSizes.radiusL),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              style.name,
                              style: kBricolageBoldStyle.copyWith(
                                color: AppColors.color121212,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  Container(
                    height: cardHeight - 30,
                    width: cardWidth,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSizes.radiusL),
                      child: _buildImageWidget(),
                    ),
                  ),
                  // Text ở dưới
                  Container(
                    padding: const EdgeInsets.only(left: 4, right: 4, top: 6),
                    child: Text(
                      style.name,
                      style: kBricolageRegularStyle.copyWith(
                        color: AppColors.color434343,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }

  /// Build image widget với logic ưu tiên: URL -> Assets -> Placeholder
  Widget _buildImageWidget() {
    // Lấy URL thực sự (http/https) và asset path
    final networkUrl = _getNetworkUrl();
    final assetPath = _getAssetPath();

    // Ưu tiên 1: Nếu có network URL, dùng CachedNetworkImage với fallback về assets
    if (networkUrl != null) {
      return CachedNetworkImage(
        imageUrl: networkUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildAssetOrPlaceholder(assetPath),
        errorWidget: (context, url, error) {
          // Nếu URL load lỗi, fallback về assets
          return _buildAssetOrPlaceholder(assetPath);
        },
        maxWidthDiskCache: 2048,
        maxHeightDiskCache: 2048,
      );
    }

    // Ưu tiên 2: Nếu không có URL, dùng assets
    return _buildAssetOrPlaceholder(assetPath);
  }

  /// Lấy network URL (http/https) từ style
  String? _getNetworkUrl() {
    if (style.imageUrl != null && style.imageUrl!.isNotEmpty) {
      final url = style.imageUrl!;
      // Chỉ trả về nếu là URL thực sự (http/https)
      if (url.startsWith('http://') || url.startsWith('https://')) {
        return url;
      }
    }
    return null;
  }

  /// Lấy asset path từ style (imageAsset hoặc imageUrl nếu là asset path)
  String? _getAssetPath() {
    // Ưu tiên imageAsset
    if (style.imageAsset != null && style.imageAsset!.isNotEmpty) {
      return style.imageAsset;
    }
    // Nếu imageUrl là asset path thì dùng
    if (style.imageUrl != null &&
        style.imageUrl!.isNotEmpty &&
        style.imageUrl!.startsWith('assets/')) {
      return style.imageUrl;
    }
    return null;
  }

  /// Build asset image hoặc placeholder
  Widget _buildAssetOrPlaceholder(String? assetPath) {
    if (assetPath != null && assetPath.isNotEmpty) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[800],
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.grey,
          size: 32,
        ),
      ),
    );
  }
}
