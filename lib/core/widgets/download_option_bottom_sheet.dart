import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import '../constants/export_constants.dart';

/// Bottom sheet để chọn option download (với/không watermark)
class DownloadOptionBottomSheet {
  /// Hiển thị bottom sheet chọn option download
  static Future<void> show({
    required BuildContext context,
    required VoidCallback onWithWatermark,
    required VoidCallback onWithoutWatermark,
    String? withWatermarkTitle,
    String? withoutWatermarkTitle,
    bool? showWithWatermark,
    bool? showWithoutWatermark,
    String? headerTitle,
  }) {
    final resolvedWithWatermarkTitle =
        withWatermarkTitle ?? tr('save_with_watermark');
    final resolvedWithoutWatermarkTitle =
        withoutWatermarkTitle ?? tr('save_without_watermark');
    final resolvedShowWithWatermark = showWithWatermark ??
        (RemoteConfigService.shared.adsEnabled &&
            RemoteConfigService.shared.rewardSave1Enabled);
    final resolvedShowWithoutWatermark = showWithoutWatermark ??
        (RemoteConfigService.shared.adsEnabled &&
            RemoteConfigService.shared.rewardSave3Enabled);
    return showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSizes.radiusXL),
            topRight: Radius.circular(AppSizes.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header với title và cancel button
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacingM,
                vertical: AppSizes.spacingM,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    headerTitle ?? tr('save_to_device'),
                    style: kBricolageBoldStyle.copyWith(
                      color: AppColors.color121212,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const SvgIcon(
                        name: "ic_close",
                        height: 18,
                        width: 18,
                      )),
                ],
              ),
            ),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
              child: Divider(
                height: 0.2,
                thickness: 0.5,
                color: AppColors.divider,
              ),
            ),

            // Options
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacingM),
              child: Column(
                children: [
                  // Option 1: Save with watermark - FREE
                  if (resolvedShowWithWatermark)
                    _buildOptionCard(
                      context: context,
                      title: resolvedWithWatermarkTitle,
                      subtitle: tr('free'),
                      isHighlighted: false,
                      onTap: () {
                        Navigator.pop(context);
                        onWithWatermark();
                      },
                    ),
                  const SizedBox(height: AppSizes.spacingL),

                  // Option 2: Save without watermark - 1 ad
                  if (resolvedShowWithoutWatermark)
                    _buildOptionCard(
                      showBestChoice: true,
                      context: context,
                      title: resolvedWithoutWatermarkTitle,
                      subtitle: tr('watch_01_ad'),
                      isHighlighted: false,
                      onTap: () {
                        Navigator.pop(context);
                        onWithoutWatermark();
                      },
                    ),
                  const SizedBox(height: AppSizes.spacingXL),
                ],
              ),
            ),

            // Bottom padding for safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  static Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isHighlighted,
    required VoidCallback onTap,
    bool? showBestChoice = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            decoration: BoxDecoration(
              color: isHighlighted
                  ? AppColors.colorFFEEED // Light pink background
                  : AppColors.colorEAE7FE, // Light gray background
              border: Border.all(
                color: isHighlighted
                    ? DynamicThemeService.shared
                        .getPrimaryAccentColor() // Bright pink border
                    : AppColors.colorEAE7FE, // Gray border
                width: 1,
              ),
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: kBricolageBoldStyle.copyWith(
                          color: AppColors.color111111,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // const SizedBox(height: 4),
                      // Text(
                      //   subtitle,
                      //   style: kTextSmallStyle.copyWith(
                      //     color: AppColors.textSecondary,
                      //     fontSize: 12,
                      //   ),
                      // ),
                    ],
                  ),
                ),
                // Play button icon
                // Container(
                //   width: 40,
                //   height: 40,
                //   decoration: BoxDecoration(
                //     color: AppColors.surface,
                //     shape: BoxShape.circle,
                //   ),
                //   child: Icon(
                //     Icons.play_arrow,
                //     color: isHighlighted
                //         ? DynamicThemeService.shared
                //             .getPrimaryAccentColor() // Bright pink icon
                //         : AppColors.color595959, // Gray icon
                //     size: 24,
                //   ),
                // ),
              ],
            ),
          ),
          if (showBestChoice == true)
            Positioned(
                top: 0,
                right: 0,
                child: Container(
                  height: 32,
                  width: MediaQuery.of(context).size.width / 3.5,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(27),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.colorDED2F8,
                        AppColors.colorECB5FB,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      tr(
                        'best_choice',
                      ),
                      style: kBricolageBoldStyle.copyWith(
                          color: AppColors.color400FA7,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                )),
          if (showBestChoice == true)
            Positioned(
              top: -10,
              right: 5,
              child: Container(
                height: 20,
                width: 20,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    // color: Colors.yellow,
                    borderRadius: BorderRadius.circular(4),
                    image: DecorationImage(
                        image: AssetImage('assets/icons/img_watch_ads.png'))),
              ),
            ),
        ],
      ),
    );
  }
}
