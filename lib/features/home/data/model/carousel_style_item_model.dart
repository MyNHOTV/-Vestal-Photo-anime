class CarouselStyleItemModel {
  const CarouselStyleItemModel({
    required this.id,
    required this.title,
    required this.image,
  });

  final int id; // ID để query style từ danh sách
  final String title;
  final String image; // Asset path hoặc URL

  CarouselStyleItemModel copyWith({
    int? id,
    String? title,
    String? image,
  }) {
    return CarouselStyleItemModel(
      id: id ?? this.id,
      title: title ?? this.title,
      image: image ?? this.image,
    );
  }

  // Convert từ Map (nếu load từ remote config)
  factory CarouselStyleItemModel.fromMap(Map<String, dynamic> map) {
    return CarouselStyleItemModel(
      id: map['id'] is int
          ? map['id']
          : int.tryParse(map['id'].toString()) ?? 0,
      title: map['title']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'image': image,
    };
  }
}
