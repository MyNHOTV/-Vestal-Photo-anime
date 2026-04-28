class GeneratedImage {
  const GeneratedImage({
    required this.id,
    required this.prompt,
    required this.userPrompt,
    required this.imagePath,
    this.thumbnailPath,
    required this.createdAt,
    this.isFavorite,
    this.aspectRatio,
    this.styleId,
  });

  final String id;
  final String prompt;
  final String userPrompt;
  final String imagePath; // Có thể là URL, file path, hoặc base64 string
  final String? thumbnailPath;
  final DateTime createdAt;
  final bool? isFavorite;
  final String? aspectRatio;
  final int? styleId;

  /// Kiểm tra xem imagePath có phải là URL không
  bool get isUrl =>
      imagePath.startsWith('http://') || imagePath.startsWith('https://');

  /// Kiểm tra xem imagePath có phải là base64 không
  bool get isBase64 {
    if (imagePath.isEmpty) return false;
    // Base64 thường bắt đầu với data:image hoặc là chuỗi base64 thuần
    if (imagePath.startsWith('data:image/')) return true;
    // Kiểm tra nếu là chuỗi base64 hợp lệ (chỉ chứa base64 chars và có độ dài hợp lý)
    final base64Pattern = RegExp(r'^[A-Za-z0-9+/=]+$');
    return base64Pattern.hasMatch(imagePath) && imagePath.length > 100;
  }
}
