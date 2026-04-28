import 'package:hive_flutter/hive_flutter.dart';

/// Service quản lý local storage sử dụng Hive
class LocalStorageService {
  LocalStorageService._internal();
  static final LocalStorageService shared = LocalStorageService._internal();

  Box? _box;
  bool _initialized = false;

  /// Khởi tạo Hive và mở box
  Future<void> init({String boxName = 'app_storage'}) async {
    if (_initialized) return;

    await Hive.initFlutter();
    _box = await Hive.openBox(boxName);
    _initialized = true;
  }

  /// Lưu giá trị
  Future<void> put(String key, dynamic value) async {
    _ensureInitialized();
    await _box!.put(key, value);
  }

  /// Lấy giá trị
  T? get<T>(String key, {T? defaultValue}) {
    _ensureInitialized();
    return _box!.get(key, defaultValue: defaultValue) as T?;
  }

  /// Xóa giá trị
  Future<void> delete(String key) async {
    _ensureInitialized();
    await _box!.delete(key);
  }

  /// Xóa tất cả
  Future<void> clear() async {
    _ensureInitialized();
    await _box!.clear();
  }

  /// Kiểm tra key có tồn tại
  bool containsKey(String key) {
    _ensureInitialized();
    return _box!.containsKey(key);
  }

  /// Lấy tất cả keys
  Iterable<String> get keys {
    _ensureInitialized();
    return _box!.keys.cast<String>();
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
          'LocalStorageService chưa được khởi tạo. Gọi init() trước.');
    }
  }
}
