import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import '../constants/export_constants.dart';

/// Custom bottom sheet với header và danh sách options
///
/// Ví dụ sử dụng:
///
/// 1. Bottom sheet "Download Image" với các options:
/// ```dart
/// context.showCustomBottomSheet(
///   title: "Download Image",
///   options: [
///     BottomSheetOption(
///       title: "Small - 600 x 600px",
///       onTap: () {
///         Navigator.pop(context);
///         // Download small size
///       },
///     ),
///     BottomSheetOption(
///       title: "Medium - 800 x 800px",
///       onTap: () {
///         Navigator.pop(context);
///         // Download medium size
///       },
///     ),
///     BottomSheetOption(
///       title: "Large - 1024 x 1024px",
///       onTap: () {
///         Navigator.pop(context);
///         // Download large size
///       },
///     ),
///   ],
/// );
/// ```
class CustomBottomSheet extends StatelessWidget {
  const CustomBottomSheet({
    super.key,
    required this.title,
    required this.options,
    this.closeText,
    this.onClose,
    this.backgroundColor,
    this.optionBackgroundColor,
    this.optionTextColor,
  });

  /// Tiêu đề của bottom sheet
  final String title;

  /// Danh sách các options
  final List<BottomSheetOption> options;

  /// Text nút close (mặc định "Close")
  final String? closeText;

  /// Callback khi nhấn close
  final VoidCallback? onClose;

  /// Màu nền của bottom sheet
  final Color? backgroundColor;

  /// Màu nền của mỗi option
  final Color? optionBackgroundColor;

  /// Màu text của mỗi option
  final Color? optionTextColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSizes.radiusXL),
          topRight: Radius.circular(AppSizes.radiusXL),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacingM,
              vertical: AppSizes.spacingM,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title
                Text(
                  title,
                  style: kTextHeadingStyle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                // Close button
                TextButton(
                  onPressed: onClose ?? () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    closeText ?? tr('close'),
                    style: kTextRegularStyle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
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

          // Options list
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacingM),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map(
                    (option) => Padding(
                      padding: EdgeInsets.only(
                        bottom: option == options.last ? 0 : AppSizes.spacingM,
                      ),
                      child: _OptionItem(
                        option: option,
                        backgroundColor: optionBackgroundColor,
                        textColor: optionTextColor,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Hiển thị bottom sheet
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required List<BottomSheetOption> options,
    String? closeText,
    VoidCallback? onClose,
    Color? backgroundColor,
    Color? optionBackgroundColor,
    Color? optionTextColor,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomBottomSheet(
        title: title,
        options: options,
        closeText: closeText,
        onClose: onClose,
        backgroundColor: backgroundColor,
        optionBackgroundColor: optionBackgroundColor,
        optionTextColor: optionTextColor,
      ),
    );
  }
}

/// Option item trong bottom sheet
class BottomSheetOption {
  const BottomSheetOption({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.icon,
    this.isEnabled = true,
  });

  /// Tiêu đề của option
  final String title;

  /// Phụ đề (optional)
  final String? subtitle;

  /// Icon (optional)
  final Widget? icon;

  /// Callback khi nhấn vào option
  final VoidCallback onTap;

  /// Có enabled hay không
  final bool isEnabled;
}

/// Widget hiển thị một option item
class _OptionItem extends StatelessWidget {
  const _OptionItem({
    required this.option,
    this.backgroundColor,
    this.textColor,
  });

  final BottomSheetOption option;
  final Color? backgroundColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final defaultBackgroundColor =
        backgroundColor ?? AppColors.colorFFEEED; // Light pink background
    final defaultTextColor = textColor ??
        DynamicThemeService.shared.getPrimaryAccentColor(); // Pink/magenta text

    return InkWell(
      onTap: option.isEnabled ? option.onTap : null,
      borderRadius: BorderRadius.circular(AppSizes.radiusL),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacingL,
          vertical: AppSizes.spacingM,
        ),
        decoration: BoxDecoration(
          color: defaultBackgroundColor,
          borderRadius: BorderRadius.circular(AppSizes.radiusL),
        ),
        child: Row(
          children: [
            // Icon (nếu có)
            if (option.icon != null) ...[
              option.icon!,
              const SizedBox(width: AppSizes.spacingM),
            ],

            // Title và subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    option.title,
                    style: kTextRegularStyle.copyWith(
                      color: option.isEnabled
                          ? defaultTextColor
                          : AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (option.subtitle != null) ...[
                    const SizedBox(height: AppSizes.spacingXS),
                    Text(
                      option.subtitle!,
                      style: kTextSmallStyle.copyWith(
                        color: option.isEnabled
                            ? defaultTextColor.withOpacity(0.7)
                            : AppColors.textSecondary.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
