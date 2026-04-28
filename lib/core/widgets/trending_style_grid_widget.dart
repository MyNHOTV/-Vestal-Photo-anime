import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';
import 'package:get/get.dart';

class TrendingStyleGridWidget extends StatelessWidget {
  const TrendingStyleGridWidget({
    super.key,
    required this.styles,
    this.selectedStyleId,
    this.onStyleSelected,
    this.onSeeMoreTap,
    this.maxItems = 6,
    this.crossAxisCount = 2,
  });

  final List<ImageStyleModel> styles;
  final int? selectedStyleId;
  final Function(ImageStyleModel)? onStyleSelected;
  final VoidCallback? onSeeMoreTap;
  final int maxItems;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    final displayStyles = styles.take(maxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSizes.spacingM,
            right: AppSizes.spacingM,
            // bottom: AppSizes.spacingM
          ),
          child: CustomScrollView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            slivers: [
              // 2 phần tử đầu tiên
              if (displayStyles.length >= 2)
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSizes.spacingS,
                    mainAxisSpacing: AppSizes.spacingM,
                    childAspectRatio: 3 / 4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final style = displayStyles[index];
                      final isSelected = style.id == selectedStyleId;
                      return _buildStyleCard(style, isSelected);
                    },
                    childCount: 2,
                  ),
                )
              else
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSizes.spacingS,
                    mainAxisSpacing: AppSizes.spacingM,
                    childAspectRatio: 3 / 4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final style = displayStyles[index];
                      final isSelected = style.id == selectedStyleId;
                      return _buildStyleCard(style, isSelected);
                    },
                    childCount: displayStyles.length,
                  ),
                ),

              // Các phần tử còn lại (từ index 2 trở đi)
              if (displayStyles.length > 2)
                SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: AppSizes.spacingS,
                    mainAxisSpacing: AppSizes.spacingM,
                    childAspectRatio: 3 / 4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final style = displayStyles[index + 2];
                      final isSelected = style.id == selectedStyleId;
                      return _buildStyleCard(style, isSelected);
                    },
                    childCount: displayStyles.length - 2,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStyleCard(ImageStyleModel style, bool isSelected) {
    return GestureDetector(
      onTap: () async {
        // Check network trước khi navigate
        if (Get.isRegistered<NetworkService>()) {
          final hasNetwork =
              await NetworkService.to.checkNetworkForInAppFunction();
          if (!hasNetwork) {
            debugPrint('🌐 No network, blocking language selection');
            return;
          }
          // Có mạng, tiếp tục navigate
          onStyleSelected?.call(style);
        } else {
          // Fallback nếu NetworkService chưa sẵn sàng
          onStyleSelected?.call(style);
        }
      },
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? DynamicThemeService.shared.getActiveColor()
                      : Colors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  if (isSelected)
                    BoxShadow(
                      color: DynamicThemeService.shared
                          .getActiveColor()
                          .withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 250,
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: style.imageAsset != null
                            ? Image.asset(
                                style.imageAsset!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildPlaceholder(),
                              )
                            : style.imageUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: style.imageUrl!,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        _buildPlaceholder(),
                                    errorWidget: (context, url, error) =>
                                        _buildPlaceholder(),
                                    maxWidthDiskCache: 1024,
                                    maxHeightDiskCache: 1024,
                                  )
                                : _buildPlaceholder(),
                      ),
                      // Bottom White Gradient to match the reference design
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 100,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0),
                                Colors.white.withOpacity(0.6),
                                Colors.white.withOpacity(0.95),
                                Colors.white,
                              ],
                              stops: const [0.0, 0.4, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // Style Name centered at the bottom
                      Positioned(
                        bottom: 12,
                        left: 8,
                        right: 8,
                        child: Text(
                          style.name,
                          style: kBricolageBoldStyle.copyWith(
                            color: AppColors.color121212,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
