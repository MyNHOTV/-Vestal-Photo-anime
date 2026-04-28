class ImageStyleModel {
  const ImageStyleModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.imageAsset,
    this.isSelected = false,
  });

  final int id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? imageAsset;
  final bool isSelected;

  ImageStyleModel copyWith({
    int? id,
    String? name,
    String? description,
    String? imageUrl,
    String? imageAsset,
    bool? isSelected,
  }) {
    return ImageStyleModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      imageAsset: imageAsset ?? this.imageAsset,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
