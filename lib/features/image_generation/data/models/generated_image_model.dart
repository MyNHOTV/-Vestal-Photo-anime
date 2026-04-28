import 'dart:convert';
import 'dart:io';

import '../../domain/entities/generated_image.dart';

class GeneratedImageModel {
  const GeneratedImageModel({
    required this.id,
    required this.prompt,
    required this.userPrompt,
    required this.imagePath,
    this.thumbnailPath,
    required this.createdAt,
    this.isFavorite = false,
    this.aspectRatio,
    this.styleId,
  });

  final String id;
  final String prompt;
  final String userPrompt;
  final String imagePath; // Có thể là URL, file path, hoặc base64 string
  final String? thumbnailPath;
  final DateTime createdAt;
  final bool isFavorite;
  final String? aspectRatio;
  final int? styleId;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'prompt': prompt,
      'userPrompt': userPrompt,
      'imagePath': imagePath,
      'thumbnailPath': thumbnailPath,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isFavorite': isFavorite,
      'aspectRatio': aspectRatio,
      'styleId': styleId,
    };
  }

  GeneratedImageModel copyWith({
    String? id,
    String? prompt,
    String? userPrompt,
    String? imagePath,
    String? thumbnailPath,
    DateTime? createdAt,
    bool? isFavorite,
    String? aspectRatio,
    int? styleId,
  }) {
    return GeneratedImageModel(
      id: id ?? this.id,
      prompt: prompt ?? this.prompt,
      userPrompt: userPrompt ?? this.userPrompt,
      imagePath: imagePath ?? this.imagePath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      styleId: styleId ?? this.styleId,
    );
  }

  GeneratedImage toEntity() {
    return GeneratedImage(
      id: id,
      prompt: prompt,
      userPrompt: userPrompt,
      imagePath: imagePath,
      thumbnailPath: (thumbnailPath != null && thumbnailPath!.isNotEmpty)
          ? thumbnailPath
          : null,
      createdAt: createdAt,
      isFavorite: isFavorite,
      aspectRatio: aspectRatio,
      styleId: styleId,
    );
  }

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

  bool get hasImageFile {
    if (isUrl) return true; // URL luôn available
    if (isBase64) return true; // Base64 luôn available
    return File(imagePath).existsSync();
  }

  static GeneratedImageModel fromMap(Map<dynamic, dynamic> map) {
    return GeneratedImageModel(
      id: map['id'] as String,
      prompt: map['prompt'] as String? ?? '',
      userPrompt: map['userPrompt'] as String? ?? '',
      imagePath: map['imagePath'] as String,
      thumbnailPath: map['thumbnailPath'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        (map['createdAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
      ),
      isFavorite: map['isFavorite'] as bool? ?? false,
      aspectRatio: map['aspectRatio'] as String?,
      styleId: map['styleId'] as int?,
    );
  }
}
