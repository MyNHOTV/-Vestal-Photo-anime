import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:get/get.dart';

import '../constants/export_constants.dart';

class TextMoreWidget extends StatelessWidget {
  const TextMoreWidget({
    super.key,
    required this.onMoreStyleTap,
    this.title,
    this.seeMore,
  });

  final VoidCallback? onMoreStyleTap;
  final String? title;
  final String? seeMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title ?? tr("trending_styles"),
            style: kTextHeadingStyle,
          ),
          GestureDetector(
            onTap: () async {
              // Check network trước khi navigate
              if (Get.isRegistered<NetworkService>()) {
                final hasNetwork =
                    await NetworkService.to.checkNetworkForInAppFunction();
                if (!hasNetwork) {
                  debugPrint('🌐 No network, blocking text more widget');
                  return;
                }
                // Có mạng, tiếp tục navigate
                if (onMoreStyleTap != null) {
                  onMoreStyleTap!();
                }
              } else {
                // Fallback nếu NetworkService chưa sẵn sàng
                if (onMoreStyleTap != null) {
                  onMoreStyleTap!();
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: Colors.transparent,
              child: Text(
                seeMore ?? tr("see_more"),
                style: kTextRegularStyle.copyWith(
                  color: DynamicThemeService.shared.getPrimaryAccentColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
