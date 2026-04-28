class ImageGenerationResponseModel {
  const ImageGenerationResponseModel({
    required this.imageUrls,
    required this.created,
    required this.revisedPrompts,
    this.usage,
    this.imageBase64s, // Base64 strings từ response (nếu có)
  });

  final List<String> imageUrls; // URLs từ response
  final List<String>? imageBase64s; // Base64 strings từ response (nếu có)
  final int? created;
  final List<String?> revisedPrompts;
  final Map<String, dynamic>? usage;
}
