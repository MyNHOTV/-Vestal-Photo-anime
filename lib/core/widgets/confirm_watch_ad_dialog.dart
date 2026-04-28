import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';

enum TypeImage {
  speedUp,
  limitToday,
  beingCreated,
  sessionExpired,
  watchAd,
  deleteImage,
}

extension TypeImageExtension on TypeImage {
  String get getImageBg {
    switch (this) {
      case TypeImage.speedUp:
        return 'img_speed_generate';
      case TypeImage.limitToday:
        return 'img_lock_limit';
      case TypeImage.beingCreated:
        return 'img_creating_image';
      case TypeImage.sessionExpired:
        return 'img_session_expire';
      case TypeImage.watchAd:
        return 'img_bg_watch_ads';
      case TypeImage.deleteImage:
        return 'img_delete_image';
    }
  }
}

class ConfirmWatchAdDialog extends StatelessWidget {
  ConfirmWatchAdDialog({
    super.key,
    required this.adCount,
    this.currentCount = 0,
    required this.onConfirm,
    required this.onCancel,
    required this.title,
    this.iconName,
    this.content,
    required this.typeImage,
    this.confirmText,
    this.cancelText,
  });

  final int adCount;
  final int currentCount;
  final VoidCallback onConfirm;
  VoidCallback? onCancel;
  final String? title;
  final String? iconName;
  final String? content;
  final TypeImage typeImage;
  final String? confirmText;
  final String? cancelText;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSizes.spacingM),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSizes.radiusXL),
        ),
        padding: const EdgeInsets.all(AppSizes.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 4,
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image:
                        AssetImage('assets/icons/${typeImage.getImageBg}.png'),
                    fit: BoxFit.fill,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacingM),

            // Title
            Text(
              title ?? tr('watch_video_to_save'),
              textAlign: TextAlign.center,
              style: kBricolageBoldStyle.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.spacingS),
            if (content != null)
              Text(
                content ?? tr('watch_video_to_save'),
                textAlign: TextAlign.center,
                style: kBricolageRegularStyle.copyWith(
                    color: AppColors.color434343, fontSize: 14),
              ),
            const SizedBox(height: AppSizes.spacingL),
            if (typeImage != TypeImage.deleteImage)
              // Watch video button
              AppPrimaryButton(
                borderRadius: BorderRadius.circular(12),
                title: confirmText ?? tr('watch_video'),
                onTap: () {
                  Navigator.pop(context, true);
                  onConfirm();
                },
              ),
            // const SizedBox(height: AppSizes.spacingS),
            if (typeImage != TypeImage.deleteImage)
              // Cancel button
              TextButton(
                onPressed: () {
                  if (onCancel != null) {
                    onCancel!();
                    return;
                  }
                  Navigator.pop(context);
                },
                child: Text(
                  cancelText ?? tr('cancel'),
                  style: kTextRegularStyle.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (typeImage == TypeImage.deleteImage)
              Row(
                children: [
                  Expanded(
                    child: AppPrimaryButton(
                      titleColor: AppColors.color111111,
                      color: AppColors.colorEAE7FE,
                      borderRadius: BorderRadius.circular(12),
                      title: cancelText ?? tr('cancel'),
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: AppPrimaryButton(
                      color: AppColors.colorF56363,
                      borderRadius: BorderRadius.circular(12),
                      title: confirmText ?? tr('detele'),
                      onTap: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  static Future<bool?> show({
    required BuildContext context,
    required int adCount,
    int currentCount = 0,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String? title,
    String? iconName,
    String? content,
    TypeImage? typeImage,
    String? confirmText,
    String? cancelText,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => ConfirmWatchAdDialog(
        adCount: adCount,
        currentCount: currentCount,
        onConfirm: onConfirm,
        onCancel: onCancel,
        title: title,
        iconName: iconName,
        content: content,
        typeImage: typeImage ?? TypeImage.speedUp,
        confirmText: confirmText,
        cancelText: cancelText,
      ),
    );
  }
}
