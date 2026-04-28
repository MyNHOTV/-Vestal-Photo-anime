import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/constants/app_sizes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/card_widget/style_card_widget.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';
import 'package:get/get.dart';

class StyleGroupSectionWidget extends StatelessWidget {
  const StyleGroupSectionWidget({
    super.key,
    required this.groupName,
    required this.styles,
    this.icon,
    this.onStyleSelected,
    this.onSeeAllTap,
    this.maxItems = 6,
    this.isLayoutType1,
  });

  final String groupName;
  final List<ImageStyleModel> styles;
  final String? icon;
  final Function(ImageStyleModel)? onStyleSelected;
  final VoidCallback? onSeeAllTap;
  final int maxItems;
  final bool? isLayoutType1;

  @override
  Widget build(BuildContext context) {
    final displayStyles = styles.take(maxItems).toList();

    if (displayStyles.isEmpty) {
      return const SizedBox.shrink();
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final double cardHeight = screenHeight * 0.25;
    final double layout1Width = screenWidth / 2.5;
    final double layout2Width = screenWidth / 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
              left: AppSizes.radiusL,
              right: AppSizes.radiusL,
              bottom: AppSizes.radiusS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null) ...[
                    // Kiểm tra xem icon là PNG hay SVG
                    icon!.endsWith('.png') || icon!.startsWith('img_icon_')
                        ? AppImage(
                            name: icon!,
                            width: 20,
                            height: 20,
                          )
                        : SvgIcon(
                            name: icon!,
                            width: 20,
                            height: 20,
                            color: DynamicThemeService.shared
                                .getPrimaryAccentColor(),
                          ),
                    const SizedBox(width: AppSizes.spacingS),
                  ],
                  Text(
                    groupName,
                    style: kBricolageHeadingStyle.copyWith(
                        color: AppColors.color111111,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              // Button "All >"
              GestureDetector(
                onTap: () async {
                  if (Get.isRegistered<NetworkService>()) {
                    final hasNetwork =
                        await NetworkService.to.checkNetworkForInAppFunction();
                    if (!hasNetwork) {
                      debugPrint('🌐 No network, blocking see all');
                      return;
                    }
                  }
                  AnalyticsService.shared.actionAllClick(groupName);
                  onSeeAllTap?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      Text(
                        tr('all'),
                        style: kBricolageHeadingStyle.copyWith(
                          color: AppColors.color727885,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const SvgIcon(
                          name: 'ic_foward',
                          width: 10,
                          height: 10,
                          color: AppColors.color727885),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Horizontal scrollable list
        SizedBox(
          height: cardHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
            itemCount: displayStyles.length,
            itemBuilder: (context, index) {
              final style = displayStyles[index];
              // Xen kẽ layout: index chẵn = layout type 1, index lẻ = layout type 2

              return StyleCardWidget(
                style: style,
                isLayoutType1: isLayoutType1 ?? true,
                cardWidth: isLayoutType1 ?? true ? layout1Width : layout2Width,
                cardHeight: cardHeight,
                onStyleSelected: onStyleSelected,
              );
              ;
            },
          ),
        ),
        const SizedBox(height: AppSizes.spacingM),
      ],
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
