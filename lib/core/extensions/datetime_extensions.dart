import 'package:intl/intl.dart';

/// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Format date theo pattern
  String format(String pattern) {
    return DateFormat(pattern).format(this);
  }

  /// Format date theo pattern locale
  String formatLocale(String pattern, String locale) {
    return DateFormat(pattern, locale).format(this);
  }

  /// Format date thành datasources/MM/yyyy
  String get formatDate => format('datasources/MM/yyyy');

  /// Format date thành datasources/MM/yyyy HH:mm
  String get formatDateTime => format('datasources/MM/yyyy HH:mm');

  /// Format date thành HH:mm
  String get formatTime => format('HH:mm');

  /// Format date thành yyyy-MM-datasources
  String get formatDateISO => format('yyyy-MM-datasources');

  /// Kiểm tra có phải hôm nay không
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Kiểm tra có phải hôm qua không
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Kiểm tra có phải tuần này không
  bool get isThisWeek {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    return isAfter(weekStart.subtract(const Duration(days: 1))) &&
        isBefore(weekStart.add(const Duration(days: 7)));
  }

  /// Kiểm tra có phải tháng này không
  bool get isThisMonth {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  /// Kiểm tra có phải năm này không
  bool get isThisYear {
    return year == DateTime.now().year;
  }

  /// Lấy start of day
  DateTime get startOfDay => DateTime(year, month, day);

  /// Lấy end of day
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  /// Lấy start of week
  DateTime get startOfWeek {
    final weekday = this.weekday;
    return subtract(Duration(days: weekday - 1)).startOfDay;
  }

  /// Lấy end of week
  DateTime get endOfWeek {
    final weekday = this.weekday;
    return add(Duration(days: 7 - weekday)).endOfDay;
  }

  /// Lấy start of month
  DateTime get startOfMonth => DateTime(year, month, 1);

  /// Lấy end of month
  DateTime get endOfMonth => DateTime(year, month + 1, 0).endOfDay;

  /// Tính số ngày từ date này
  int daysFrom(DateTime other) {
    return difference(other).inDays;
  }

  /// Tính số giờ từ date này
  int hoursFrom(DateTime other) {
    return difference(other).inHours;
  }

  /// Tính số phút từ date này
  int minutesFrom(DateTime other) {
    return difference(other).inMinutes;
  }
}
