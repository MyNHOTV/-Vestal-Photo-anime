import 'package:intl/intl.dart';

/// String extensions for number formatting
extension StringNumberExtensions on String {
  /// Format string số với thousand separator (dấu chấm)
  /// Ví dụ: "2500" -> "2.500"
  /// Trả về string gốc nếu không phải số hợp lệ
  String get formatNumber {
    try {
      final number = double.parse(this);
      final formatter = NumberFormat('#,###', 'vi_VN');
      return formatter.format(number);
    } catch (e) {
      return this; // Trả về string gốc nếu không parse được
    }
  }

  /// Format string số với thousand separator và số thập phân
  /// Ví dụ: "2500.5" -> "2.500,5" (với decimals = 1)
  String formatNumberWithDecimals(int decimals) {
    try {
      final number = double.parse(this);
      final pattern = '#,###${decimals > 0 ? '.${'0' * decimals}' : ''}';
      final formatter = NumberFormat(pattern, 'vi_VN');
      return formatter.format(number);
    } catch (e) {
      return this;
    }
  }

  /// Format string số thành currency (VND)
  /// Ví dụ: "2500" -> "2.500 ₫"
  String get formatCurrency {
    try {
      final number = double.parse(this);
      final formatter = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: 0,
      );
      return formatter.format(number);
    } catch (e) {
      return this;
    }
  }

  /// Format string số thành currency với số thập phân
  /// Ví dụ: "2500.5" -> "2.500,5 ₫" (với decimals = 1)
  String formatCurrencyWithDecimals(int decimals) {
    try {
      final number = double.parse(this);
      final formatter = NumberFormat.currency(
        locale: 'vi_VN',
        symbol: '₫',
        decimalDigits: decimals,
      );
      return formatter.format(number);
    } catch (e) {
      return this;
    }
  }

  /// Kiểm tra string có phải số hợp lệ không
  bool get isNumeric {
    if (isEmpty) return false;
    return double.tryParse(this) != null;
  }

  /// Parse string thành int, trả về null nếu không hợp lệ
  int? get toIntOrNull => int.tryParse(this);

  /// Parse string thành double, trả về null nếu không hợp lệ
  double? get toDoubleOrNull => double.tryParse(this);
}

/// Number extensions (nếu cần dùng cho num)
extension NumberExtensions on num {
  /// Format số với thousand separator (dấu chấm)
  /// Ví dụ: 2500 -> "2.500"
  String get formatNumber {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(this);
  }

  /// Format số với thousand separator và số thập phân
  String formatNumberWithDecimals(int decimals) {
    final pattern = '#,###${decimals > 0 ? '.${'0' * decimals}' : ''}';
    final formatter = NumberFormat(pattern, 'vi_VN');
    return formatter.format(this);
  }

  /// Format số thành currency (VND)
  String get formatCurrency {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
      decimalDigits: 0,
    );
    return formatter.format(this);
  }
}
