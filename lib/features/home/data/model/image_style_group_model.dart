import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';

class ImageStyleGroupModel {
  const ImageStyleGroupModel({
    required this.id,
    required this.name,
    required this.styles,
    this.icon,
  });

  final int id;
  final String name;
  final String? icon;
  final List<ImageStyleModel> styles;

  factory ImageStyleGroupModel.fromJson(
    Map<String, dynamic> json, {
    List<ImageStyleModel>? allStyles, // Thêm parameter để map styleIds
  }) {
    List<ImageStyleModel> styles = [];

    // Hỗ trợ cả styleIds (mảng số) và styles (mảng objects) - backward compatible
    if (json['styleIds'] != null && allStyles != null) {
      // Map styleIds sang full style objects
      final styleIds = (json['styleIds'] as List<dynamic>)
          .map((id) => id is int ? id : int.tryParse(id.toString()) ?? 0)
          .toList();

      styles = styleIds
          .map((id) {
            try {
              return allStyles.firstWhere(
                (style) => style.id == id,
              );
            } catch (e) {
              // Style không tìm thấy, bỏ qua
              return null;
            }
          })
          .whereType<ImageStyleModel>() // Bỏ qua null values
          .toList();
    } else if (json['styles'] != null) {
      // Format cũ: full style objects (backward compatible)
      styles = (json['styles'] as List<dynamic>?)?.map((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return ImageStyleModel(
              id: map['id'] is int
                  ? map['id']
                  : int.tryParse(map['id'].toString()) ?? 0,
              name: map['name']?.toString() ?? '',
              description: map['description']?.toString() ?? '',
              imageUrl: map['imageUrl']?.toString(),
              imageAsset: map['imageAsset']?.toString(),
              isSelected: map['isSelected'] == true,
            );
          }).toList() ??
          [];
    }

    return ImageStyleGroupModel(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      icon: json['icon']?.toString(),
      styles: styles,
    );
  }

  ImageStyleGroupModel copyWith({
    int? id,
    String? name,
    String? icon,
    List<ImageStyleModel>? styles,
  }) {
    return ImageStyleGroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      styles: styles ?? this.styles,
    );
  }
}
