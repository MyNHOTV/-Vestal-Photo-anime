import 'package:flutter/material.dart';
import '../constants/export_constants.dart';

class CustomDialog extends StatelessWidget {
  const CustomDialog({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    required this.cancelText,
    required this.confirmText,
    required this.onCancel,
    required this.onConfirm,
    this.iconBackgroundColor,
    this.confirmButtonColor,
    this.confirmButtonGradient,
    this.isDestructive = false,
  });

  /// Icon hiển thị ở trên cùng
  final Widget icon;

  /// Tiêu đề chính
  final String title;

  /// Thông điệp phụ (optional)
  final String? message;

  /// Text nút Cancel
  final String cancelText;

  /// Text nút Confirm
  final String confirmText;

  /// Callback khi nhấn Cancel
  final VoidCallback onCancel;

  /// Callback khi nhấn Confirm
  final VoidCallback onConfirm;

  /// Màu nền của icon container (optional)
  final Color? iconBackgroundColor;

  /// Màu nền của nút confirm (nếu không dùng gradient)
  final Color? confirmButtonColor;

  /// Gradient cho nút confirm (optional, ưu tiên hơn confirmButtonColor)
  final List<Color>? confirmButtonGradient;

  /// Nếu true, sử dụng màu đỏ cho nút confirm (cho delete dialog)
  final bool isDestructive;

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
        padding: const EdgeInsets.only(
            top: AppSizes.spacingM,
            left: AppSizes.spacingM,
            right: AppSizes.spacingM),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon với background
            Center(child: icon),
            const SizedBox(height: AppSizes.spacingM),

            // Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: kTextMediumtStyle.copyWith(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            // Message (nếu có)
            if (message != null) ...[
              // const SizedBox(height: AppSizes.spacingS),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: kTextMediumtStyle.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],

            const SizedBox(height: AppSizes.spacingM),

            // Buttons
            Column(
              children: [
                // Confirm button
                _ConfirmButton(
                  text: confirmText,
                  onTap: onConfirm,
                  isDestructive: isDestructive,
                  buttonColor: confirmButtonColor,
                  gradient: confirmButtonGradient,
                ),
                const SizedBox(width: AppSizes.spacingM),
                // Cancel button
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.spacingM,
                    ),
                  ),
                  child: Text(
                    cancelText,
                    style: kTextRegularStyle.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Hiển thị dialog
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget icon,
    required String title,
    String? message,
    required String cancelText,
    required String confirmText,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    Color? iconBackgroundColor,
    Color? confirmButtonColor,
    List<Color>? confirmButtonGradient,
    bool isDestructive = false,
    bool barrierDismissible = true,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => CustomDialog(
        icon: icon,
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        onCancel: onCancel,
        onConfirm: onConfirm,
        iconBackgroundColor: iconBackgroundColor,
        confirmButtonColor: confirmButtonColor,
        confirmButtonGradient: confirmButtonGradient,
        isDestructive: isDestructive,
      ),
    );
  }
}

/// Nút Confirm với gradient hoặc màu đơn
class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.text,
    required this.onTap,
    this.isDestructive = false,
    this.buttonColor,
    this.gradient,
  });

  final String text;
  final VoidCallback onTap;
  final bool isDestructive;
  final Color? buttonColor;
  final List<Color>? gradient;

  @override
  Widget build(BuildContext context) {
    final Color defaultColor =
        isDestructive ? AppColors.colorFF4538 : AppColors.primary;

    final List<Color> defaultGradient = isDestructive
        ? [
            AppColors.colorFF5D52,
            AppColors.colorFF4538,
            AppColors.colorFF2E1F,
          ]
        : [
            AppColors.colorA30049,
            AppColors.colorFF18BA,
            AppColors.colorE037B3,
            AppColors.colorAD01C3,
            AppColors.color600088,
          ];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(1000),
      child: Container(
        height: AppSizes.buttonHeightM,
        decoration: BoxDecoration(
          gradient: gradient != null || buttonColor == null
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: gradient ?? defaultGradient,
                )
              : null,
          color: buttonColor ?? (gradient == null ? defaultColor : null),
          borderRadius: BorderRadius.circular(1000),
        ),
        child: Center(
          child: Text(
            text,
            style: kTextButtonStyle.copyWith(
              color: AppColors.surface,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
