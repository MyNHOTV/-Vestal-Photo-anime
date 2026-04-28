import 'package:flutter/material.dart';
import '../../../../core/constants/export_constants.dart';

/// Widget hiển thị một item trong settings
class SettingsItemWidget extends StatelessWidget {
  const SettingsItemWidget({
    super.key,
    required this.title,
    this.icon,
    this.onTap,
    this.trailing,
  });

  final String title;
  final Widget? icon;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
        padding: const EdgeInsets.all(AppSizes.spacingM),
        decoration: BoxDecoration(
          color: AppColors.color231B1D,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          children: [
            // Icon
            if (icon != null) ...[
              icon!,
              const SizedBox(width: AppSizes.spacingM),
            ],
            // Title
            Expanded(
              child: Text(
                title,
                style: kTextRegularStyle.copyWith(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Trailing (arrow or custom widget)
            trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white.withOpacity(0.5),
                ),
          ],
        ),
      ),
    );
  }
}
