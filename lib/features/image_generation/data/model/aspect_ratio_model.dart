/// Model cho aspect ratio option
class AspectRatioModel {
  const AspectRatioModel({
    required this.id,
    required this.aspectRatio,
    required this.i18nKey,
    required this.iconWidth,
    required this.iconHeight,
    this.isDefault = false,
  });

  /// ID của aspect ratio
  final String id;

  /// Aspect ratio value (ví dụ: "1:1", "3:4", "9:16")
  final String aspectRatio;

  /// Key trong i18n file (ví dụ: "ratio_1_1")
  final String i18nKey;

  /// Chiều rộng của icon (tỷ lệ)
  final double iconWidth;

  /// Chiều cao của icon (tỷ lệ)
  final double iconHeight;

  /// Có phải là default không
  final bool isDefault;

  /// Convert aspect ratio từ "1:1" sang "1x1" để gửi API
  String get sizeForApi {
    return aspectRatio.replaceAll(':', 'x');
  }
}
