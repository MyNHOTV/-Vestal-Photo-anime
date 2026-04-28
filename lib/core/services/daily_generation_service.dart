import 'package:get/get.dart';
import 'package:flutter_quick_base/core/storage/local_storage_service.dart';

class DailyGenerationService extends GetxService {
  DailyGenerationService._internal();
  static final DailyGenerationService shared =
      DailyGenerationService._internal();

  static const String _dailyCountKey = 'daily_generation_count';
  static const String _lastGenerationDateKey = 'last_generation_date';
  static const int _dailyLimit = 2;

  final RxInt remainingGenerations = 2.obs;

  /// Khởi tạo và load dữ liệu
  Future<void> init() async {
    await _checkAndResetDailyCount();
  }

  /// Kiểm tra và reset count nếu đã qua ngày mới
  /// Sử dụng UTC để có chuẩn chung cho tất cả user, tránh vấn đề múi giờ
  Future<void> _checkAndResetDailyCount() async {
    final lastDate =
        LocalStorageService.shared.get<String>(_lastGenerationDateKey);
    // Dùng UTC để có chuẩn chung cho tất cả user
    final today = DateTime.now()
        .toUtc()
        .toIso8601String()
        .split('T')[0]; // YYYY-MM-DD (UTC)

    if (lastDate != today) {
      // Đã qua ngày mới, reset count
      await LocalStorageService.shared.put(_dailyCountKey, 0);
      await LocalStorageService.shared.put(_lastGenerationDateKey, today);
      remainingGenerations.value = _dailyLimit;
    } else {
      // Cùng ngày, load count hiện tại
      final count = LocalStorageService.shared.get<int>(_dailyCountKey) ?? 0;
      remainingGenerations.value = _dailyLimit - count;
    }
  }

  /// Kiểm tra còn lượt generate không
  bool get canGenerate => remainingGenerations.value > 0;

  /// Kiểm tra đã hết lượt chưa
  bool get hasReachedLimit => remainingGenerations.value <= 0;

  /// Sử dụng 1 lượt generate
  Future<bool> useGeneration() async {
    if (!canGenerate) return false;

    final count = LocalStorageService.shared.get<int>(_dailyCountKey) ?? 0;
    final newCount = count + 1;

    await LocalStorageService.shared.put(_dailyCountKey, newCount);
    // Dùng UTC để có chuẩn chung cho tất cả user
    await LocalStorageService.shared.put(_lastGenerationDateKey,
        DateTime.now().toUtc().toIso8601String().split('T')[0]);

    remainingGenerations.value = _dailyLimit - newCount;
    return true;
  }

  /// Thêm 1 lượt generate (từ reward ad)
  Future<void> addExtraGeneration() async {
    final count = LocalStorageService.shared.get<int>(_dailyCountKey) ?? 0;
    if (count > 0) {
      final newCount = count - 1;
      await LocalStorageService.shared.put(_dailyCountKey, newCount);
      remainingGenerations.value = _dailyLimit - newCount;
    }
  }

  /// Lấy số lượt còn lại
  int get remainingCount => remainingGenerations.value;

  /// Public method để check và reset (gọi từ controller)
  Future<void> checkAndResetDailyCount() async {
    await _checkAndResetDailyCount();
  }
}
