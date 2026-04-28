/// String extensions
extension StringExtensions on String {
  /// Kiểm tra string có rỗng hoặc null không
  bool get isNullOrEmpty => isEmpty;

  /// Kiểm tra string có phải email không
  bool get isEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Kiểm tra string có phải phone number không
  bool get isPhone {
    final phoneRegex = RegExp(r'^(0|\+84)[0-9]{9,10}$');
    return phoneRegex.hasMatch(replaceAll(' ', ''));
  }

  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String get capitalizeWords {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize).join(' ');
  }

  /// Remove all whitespace
  String get removeWhitespace => replaceAll(RegExp(r'\s+'), '');

  /// Truncate string với ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}$ellipsis';
  }
}
