import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_widget.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';
import 'package:get/get.dart';

import '../../../../core/constants/export_constants.dart';

class GenerationStyleGridWidget extends StatelessWidget {
  const GenerationStyleGridWidget({
    super.key,
    required this.styles,
    this.selectedStyleId,
    this.onStyleSelected,
    // required this.maxItems,
  });

  final List<ImageStyleModel> styles;
  final int? selectedStyleId;
  final Function(ImageStyleModel)? onStyleSelected;

  // final int maxItems;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
          left: AppSizes.spacingM,
          right: AppSizes.spacingM,
          bottom: AppSizes.spacingL),
      child: CustomScrollView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        slivers: [
          // 3 phần tử đầu tiên
          if (styles.length >= 3)
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSizes.spacingS,
                mainAxisSpacing: AppSizes.spacingS,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final style = styles[index];
                  final isSelected = style.id == selectedStyleId;
                  return _buildStyleCard(style, isSelected);
                },
                childCount: 3,
              ),
            )
          else
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSizes.spacingS,
                mainAxisSpacing: AppSizes.spacingS,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final style = styles[index];
                  final isSelected = style.id == selectedStyleId;
                  return _buildStyleCard(style, isSelected);
                },
                childCount: styles.length,
              ),
            ),

          if (styles.length >= 3)
            SliverToBoxAdapter(
              child: _buildMockAdNative(context),
            ),

          // Các phần tử còn lại (từ index 3 trở đi)
          if (styles.length > 3)
            SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSizes.spacingS,
                mainAxisSpacing: AppSizes.spacingS,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final style = styles[index + 3];
                  final isSelected = style.id == selectedStyleId;
                  return _buildStyleCard(style, isSelected);
                },
                childCount: styles.length - 3,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStyleCard(ImageStyleModel style, bool isSelected) {
    return GestureDetector(
      onTap: () => onStyleSelected?.call(style),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                border: Border.all(
                  color: isSelected
                      ? AppColors.colorFF00AE
                      : Colors.white.withOpacity(0),
                  width: isSelected ? 2 : 0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.colorFF00AE.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXL),
                  border: Border.all(
                    color: AppColors.color29171E,
                    width: 8,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
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
                              maxWidthDiskCache: 2048,
                              maxHeightDiskCache: 2048,
                            )
                          : _buildPlaceholder(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.spacingS),
          Text(
            style.name,
            style: kTextRegularStyle.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  //
  Widget _buildMockAdNative(BuildContext context) {
    return Obx(() {
      if (!RemoteConfigService.shared.adsEnabled &&
          !RemoteConfigService.shared.nativeStyleEnabled) {
        return const SizedBox.shrink();
      }
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.spacingS),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSizes.radiusM),
          child: NativeAdWidget(
            margin: EdgeInsets.zero,
            padding: EdgeInsets.zero,
            uniqueKey: 'native_style',
            factoryId: 'native_small_image_top',
            backgroundColor: Colors.white,
            height: 210,
          ),
        ),
      );
    });
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
