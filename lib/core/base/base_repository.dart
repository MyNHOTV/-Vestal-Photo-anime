import '../network/api_provider.dart';
import '../network/errors.dart';
import '../utils/either.dart';

/// Base Repository pattern
abstract class BaseRepository {
  /// Get API provider
  ApiProvider get api => ApiProvider.shared;

  /// Execute API call và trả về Either
  Future<Either<AppError, T>> execute<T>(Future<T> Function() action) async {
    try {
      final result = await action();
      return Right(result);
    } on AppError catch (e) {
      return Left(e);
    } catch (e) {
      return Left(AppError.unknown(message: e.toString()));
    }
  }

  /// Execute API call với callback style
  Future<void> executeWithCallbacks<T>({
    required Future<T> Function() action,
    required void Function(T data) onSuccess,
    required void Function(AppError error) onError,
  }) async {
    final result = await execute(action);
    result.fold(
      (error) => onError(error),
      (data) => onSuccess(data),
    );
  }
}
