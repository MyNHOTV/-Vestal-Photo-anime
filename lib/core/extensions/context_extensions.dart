import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/widgets/custom_toast.dart';
import '../services/permission_service.dart';
import '../widgets/custom_bottom_sheet.dart';
import '../widgets/custom_dialog.dart';

/// BuildContext extensions
extension ContextExtensions on BuildContext {
  /// Get theme
  ThemeData get theme => Theme.of(this);

  /// Get text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Get color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Get media query
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// Get screen size
  Size get screenSize => mediaQuery.size;

  /// Get screen width
  double get screenWidth => screenSize.width;

  /// Get screen height
  double get screenHeight => screenSize.height;

  /// Get padding
  EdgeInsets get padding => mediaQuery.padding;

  /// Get view padding
  EdgeInsets get viewPadding => mediaQuery.viewPadding;

  /// Get view insets
  EdgeInsets get viewInsets => mediaQuery.viewInsets;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => viewInsets.bottom > 0;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => padding;

  /// Show snackbar
  void showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message,
            style: textColor != null ? TextStyle(color: textColor) : null),
        duration: duration,
        backgroundColor: backgroundColor,
        action: action,
      ),
    );
  }

  /// Show error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: colorScheme.error,
      textColor: colorScheme.onError,
    );
  }

  /// Show success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(
      message,
      backgroundColor: colorScheme.primary,
      textColor: colorScheme.onPrimary,
    );
  }

  /// Show custom success toast
  void showSuccessToast(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    CustomToast.showSuccess(
      this,
      message: message,
      duration: duration,
    );
  }

  /// Show custom error toast
  void showErrorToast(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    CustomToast.showError(
      this,
      message: message,
      duration: duration,
    );
  }

  /// Show custom info toast
  void showInfoToast(String message,
      {Duration duration = const Duration(seconds: 3)}) {
    CustomToast.showInfo(
      this,
      message: message,
      duration: duration,
    );
  }

  /// Show custom toast với tùy chỉnh
  void showCustomToast({
    required String message,
    String? icon,
    Color? iconBackgroundColor,
    Color? backgroundColor,
    Color? textColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    CustomToast.show(
      this,
      message: message,
      icon: icon,
      iconBackgroundColor: iconBackgroundColor,
      backgroundColor: backgroundColor,
      textColor: textColor,
      duration: duration,
    );
  }

  /// Navigate to route
  Future<T?> navigateTo<T>(String route, {Object? arguments}) {
    return Navigator.of(this).pushNamed<T>(route, arguments: arguments);
  }

  /// Navigate and replace
  Future<T?> navigateReplacement<T>(String route, {Object? arguments}) {
    return Navigator.of(this)
        .pushReplacementNamed<T, T>(route, arguments: arguments);
  }

  /// Navigate and remove until
  Future<T?> navigateAndRemoveUntil<T>(String route) {
    return Navigator.of(this).pushNamedAndRemoveUntil<T>(
      route,
      (route) => false,
    );
  }

  /// Pop
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  /// Check if can pop
  bool get canPop => Navigator.of(this).canPop();

  /// Show custom dialog với 2 options
  Future<T?> showCustomDialog<T>({
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
    return CustomDialog.show<T>(
      context: this,
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
      barrierDismissible: barrierDismissible,
    );
  }

  /// Show custom bottom sheet với danh sách options
  Future<T?> showCustomBottomSheet<T>({
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
    return CustomBottomSheet.show<T>(
      context: this,
      title: title,
      options: options,
      closeText: closeText,
      onClose: onClose,
      backgroundColor: backgroundColor,
      optionBackgroundColor: optionBackgroundColor,
      optionTextColor: optionTextColor,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
    );
  }

  /// Kiểm tra quyền camera
  Future<bool> checkCameraPermission() async {
    return await PermissionService.shared.checkCameraPermission();
  }

  /// Request quyền camera
  Future<bool> requestCameraPermission() async {
    return await PermissionService.shared.requestCameraPermission();
  }

  /// Kiểm tra và request quyền camera
  Future<bool> checkAndRequestCameraPermission() async {
    return await PermissionService.shared.checkAndRequestCameraPermission();
  }

  /// Kiểm tra quyền thư viện ảnh
  Future<bool> checkLibraryPermission() async {
    return await PermissionService.shared.checkLibraryPermission();
  }

  /// Request quyền thư viện ảnh
  Future<bool> requestLibraryPermission() async {
    return await PermissionService.shared.requestLibraryPermission();
  }

  /// Kiểm tra và request quyền thư viện ảnh
  Future<bool> checkAndRequestLibraryPermission() async {
    return await PermissionService.shared.checkAndRequestLibraryPermission();
  }

  /// Kiểm tra cả camera và library permissions
  Future<Map<String, bool>> checkCameraAndLibraryPermissions() async {
    return await PermissionService.shared.checkCameraAndLibraryPermissions();
  }

  /// Request cả camera và library permissions
  Future<Map<String, bool>> requestCameraAndLibraryPermissions() async {
    return await PermissionService.shared.requestCameraAndLibraryPermissions();
  }
}
