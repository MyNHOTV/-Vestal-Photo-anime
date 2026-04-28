import '../core/network/api_provider.dart';
import '../core/network/errors.dart';

final core = _Core();

class _Core {
  Future<void> sampleGetSomething({
    required void Function(String) onSuccess,
    required void Function(AppError) onError,
  }) {
    return ApiProvider.shared.sampleAPI.getSomething(
      success: onSuccess,
      fail: onError,
    );
  }
}
