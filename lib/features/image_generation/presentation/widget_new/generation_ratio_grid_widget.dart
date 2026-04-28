import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/features/image_generation/data/model/aspect_ratio_model.dart';
import 'package:get/get.dart';

class GenerationRatioGridWidget extends StatelessWidget {
  const GenerationRatioGridWidget(
      {super.key,
      required this.styles,
      this.aspectRatio,
      this.onStyleSelected});

  final List<AspectRatioModel> styles;
  final String? aspectRatio;
  final Function(AspectRatioModel)? onStyleSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSizes.spacingS,
            mainAxisSpacing: AppSizes.spacingS,
            childAspectRatio: 0.83,
          ),
          itemCount: styles.length,
          itemBuilder: (context, index) {
            final style = styles[index];
            final isSelected = style.aspectRatio == aspectRatio;
            return _buildAspectRatioOption(style, isSelected);
          },
        ),
      ],
    );
  }

  Widget _buildAspectRatioOption(
      AspectRatioModel aspectRatioModel, bool isSelected) {
    return GestureDetector(
      onTap: () => onStyleSelected?.call(aspectRatioModel),
      child: Column(
        children: [
          // Container với icon
          Container(
            width: MediaQuery.of(Get.context!).size.width / 3,
            height: MediaQuery.of(Get.context!).size.width / 3.4,
            decoration: BoxDecoration(
              color: AppColors.color231B1D,
              borderRadius: BorderRadius.circular(AppSizes.radiusL),
              border: isSelected
                  ? Border.all(
                      width: 0.2,
                      color: Colors.transparent,
                    )
                  : null,
              // Gradient border khi selected
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: DynamicThemeService.shared
                          .getSecondaryButtonGradientColors(),
                    )
                  : null,
            ),
            child: Container(
              margin: isSelected ? const EdgeInsets.all(2) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: AppColors.color231B1D,
                borderRadius: BorderRadius.circular(AppSizes.radiusL - 2),
              ),
              child: Center(
                child: Container(
                  width: aspectRatioModel.iconWidth + 46,
                  height: aspectRatioModel.iconHeight + 46,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          // Label
          Text(
            tr(aspectRatioModel.i18nKey),
            style: kTextSmallStyle.copyWith(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
