import 'package:get/get.dart';
import '../network/errors.dart';

/// Base Controller với loading và error state
abstract class BaseController extends GetxController {
  final RxBool isLoading = false.obs;
  final Rx<AppError?> error = Rx<AppError?>(null);

  /// Bắt đầu loading
  void startLoading() {
    isLoading.value = true;
    error.value = null;
  }

  /// Dừng loading
  void stopLoading() {
    isLoading.value = false;
  }

  /// Set error
  void setError(AppError? err) {
    error.value = err;
    isLoading.value = false;
  }

  /// Clear error
  void clearError() {
    error.value = null;
  }

  /// Wrapper để tự động quản lý loading state
  Future<T?> execute<T>(Future<T> Function() action) async {
    try {
      startLoading();
      final result = await action();
      stopLoading();
      return result;
    } catch (e) {
      final appError =
          e is AppError ? e : AppError.unknown(message: e.toString());
      setError(appError);
      return null;
    }
  }

  @override
  void onClose() {
    isLoading.close();
    error.close();
    super.onClose();
  }
}
