import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/cached_image_widget.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';

class StyleSelectionDialog extends StatelessWidget {
  const StyleSelectionDialog({
    super.key,
    required this.style,
    required this.onCancel,
    required this.onConfirm,
  });

  final ImageStyleModel style;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Dialog container (màu trắng)
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSizes.radiusXL),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSizes.spacingM,
                    left: AppSizes.spacingM,
                    right: AppSizes.spacingM,
                  ),
                  child: Text(
                    style.name,
                    textAlign: TextAlign.center,
                    style: kBricolageBoldStyle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Image preview
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSizes.radiusL),
                    child: AspectRatio(
                      aspectRatio: 3 / 4,
                      child: style.imageAsset != null
                          ? Image.asset(
                              style.imageAsset!,
                              fit: BoxFit.cover,
                            )
                          : style.imageUrl != null
                              ? Image.asset(
                                  style.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  color: AppColors.textSecondary,
                                  child: const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 48,
                                      color: AppColors.disableColorText,
                                    ),
                                  ),
                                ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.spacingM),

                // Question text
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
                  child: Text(
                    tr('use_style_to_generate'),
                    textAlign: TextAlign.center,
                    style: kBricolageBoldStyle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.spacingL),

                // Choose this style button với gradient
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: AppPrimaryButton(
                    onTap: () {
                      AnalyticsService.shared.actionChooseDialog();
                      onConfirm();
                    },
                    borderRadius: BorderRadius.circular(12),
                    title: tr('choose_this_style'),
                  ),
                ),
              ],
            ),
          ),

          // Close button ở góc ngoài
          Positioned(
            top: -36,
            right: 0,
            child: InkWell(
              onTap: onCancel,
              borderRadius: BorderRadius.circular(20),
              child: const SvgIcon(name: 'ic_close_dialog'),
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required ImageStyleModel style,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => StyleSelectionDialog(
        style: style,
        onCancel: onCancel,
        onConfirm: onConfirm,
      ),
    );
  }
}
