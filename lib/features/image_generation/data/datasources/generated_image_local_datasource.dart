import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../../core/storage/local_storage_service.dart';
import '../models/generated_image_model.dart';

abstract class GeneratedImageLocalDataSource {
  Future<List<GeneratedImageModel>> cacheGeneratedImages({
    required List<String> imageUrls,
    required String prompt,
    required String userPrompt,
    int? created,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  });
  Future<GeneratedImageModel> saveImageToHistory({
    required String localPath,
    required String prompt,
    required String userPrompt,
    required DateTime createdAt,
    String? aspectRatio,
    int? styleId,
    String? existingId, // Nếu có thì update record cũ
  });

  Future<List<GeneratedImageModel>> getHistory({
    int offset,
    int limit,
  });

  Future<List<GeneratedImageModel>> getFavorites({
    int offset,
    int limit,
  });

  Future<GeneratedImageModel> toggleFavorite({
    required String id,
    required bool isFavorite,
  });

  Future<void> deleteImage(String id);

  Future<GeneratedImageModel?> getImageById(String id);
}

class GeneratedImageLocalDataSourceImpl
    implements GeneratedImageLocalDataSource {
  GeneratedImageLocalDataSourceImpl({
    required LocalStorageService storage,
  }) : _storage = storage;

  final LocalStorageService _storage;
  final Random _random = Random();

  static const _historyKey = 'generated_images_history';
  static const _favoriteKey = 'generated_images_favorites';
  static const _recordPrefix = 'generated_image_';

  @override
  Future<GeneratedImageModel> saveImageToHistory({
    required String localPath,
    required String prompt,
    required String userPrompt,
    required DateTime createdAt,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  }) async {
    GeneratedImageModel record;

    // Nếu có existingId (regenerate), update record cũ
    if (existingId != null) {
      final oldRecord = await _getRecord(existingId);
      if (oldRecord != null) {
        record = oldRecord.copyWith(
          imagePath: localPath,
          createdAt: createdAt,
          prompt: prompt,
          aspectRatio: aspectRatio ?? oldRecord.aspectRatio,
          styleId: styleId ?? oldRecord.styleId,
        );
      } else {
        // Nếu không tìm thấy record cũ, tạo mới
        final id = _generateId();
        record = GeneratedImageModel(
          id: id,
          prompt: prompt,
          userPrompt: userPrompt,
          imagePath: localPath,
          thumbnailPath: null,
          createdAt: createdAt,
          isFavorite: false,
          aspectRatio: aspectRatio,
          styleId: styleId,
        );
      }
    } else {
      // Tạo record mới
      final id = _generateId();
      record = GeneratedImageModel(
        id: id,
        prompt: prompt,
        userPrompt: userPrompt,
        imagePath: localPath,
        thumbnailPath: null,
        createdAt: createdAt,
        isFavorite: false,
        aspectRatio: aspectRatio,
        styleId: styleId,
      );
    }

    await _saveRecord(record);

    if (existingId == null) {
      await _updateHistory([record.id]);
    }

    return record;
  }

  @override
  Future<List<GeneratedImageModel>> cacheGeneratedImages({
    required List<String> imageUrls,
    required String prompt,
    required String userPrompt,
    int? created,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  }) async {
    final savedRecords = <GeneratedImageModel>[];
    final createdAt = created != null
        ? DateTime.fromMillisecondsSinceEpoch(created * 1000)
        : DateTime.now();

    for (var index = 0; index < imageUrls.length; index++) {
      final url = imageUrls[index];

      GeneratedImageModel record;

      // Nếu có existingId (regenerate), update record cũ
      if (existingId != null && index == 0) {
        // Lấy record cũ
        final oldRecord = await _getRecord(existingId);
        if (oldRecord != null) {
          record = oldRecord.copyWith(
            imagePath: url,
            // Chỉ update imagePath
            createdAt: createdAt,
            // Update thời gian tạo mới
            prompt: prompt,
            aspectRatio: aspectRatio ?? oldRecord.aspectRatio,
            styleId: styleId ?? oldRecord.styleId,
          );
        } else {
          // Nếu không tìm thấy record cũ, tạo mới
          final id = _generateId();
          record = GeneratedImageModel(
            id: id,
            prompt: prompt,
            userPrompt: userPrompt,
            imagePath: url,
            thumbnailPath: null,
            createdAt: createdAt,
            isFavorite: false,
            aspectRatio: aspectRatio,
            styleId: styleId,
          );
        }
      } else {
        // Tạo record mới (flow bình thường)
        final id = _generateId();
        record = GeneratedImageModel(
          id: id,
          prompt: prompt,
          userPrompt: userPrompt,
          imagePath: url,
          thumbnailPath: null,
          createdAt: createdAt,
          isFavorite: false,
          aspectRatio: aspectRatio,
          styleId: styleId,
        );
      }

      await _saveRecord(record);
      savedRecords.add(record);
    }
    if (existingId == null) {
      await _updateHistory(savedRecords.map((e) => e.id).toList());
    }
    return savedRecords;
  }

  @override
  Future<List<GeneratedImageModel>> getHistory({
    int offset = 0,
    int limit = 20,
  }) async {
    final ids = List<String>.from(
      _storage.get<List<dynamic>>(_historyKey, defaultValue: []) ?? const [],
    );
    final slice = ids.skip(offset).take(limit);
    final records = <GeneratedImageModel>[];
    final idsToRemove = <String>[];

    for (final id in slice) {
      final record = await _getRecord(id);
      if (record != null) {
        // Check xem file có tồn tại không (nếu không phải URL)
        // File trong thư mục app có thể kiểm tra được
        if (!record.isUrl) {
          final file = File(record.imagePath);
          final exists = await file.exists();
          if (!exists) {
            // File không tồn tại (user đã xóa bên ngoài app hoặc bị xóa)
            // Đánh dấu để xóa khỏi history
            idsToRemove.add(id);
            continue;
          }
        }
        records.add(record);
      }
    }

    // Xóa các record có file không tồn tại (bất đồng bộ để không block)
    for (final id in idsToRemove) {
      // Chỉ xóa khỏi history, không cần xóa file vì đã không tồn tại
      await _storage.delete('$_recordPrefix$id');
      await _removeFromHistory(id);
      await _updateFavorites(id: id, isFavorite: false);
    }

    return records;
  }

  @override
  Future<List<GeneratedImageModel>> getFavorites({
    int offset = 0,
    int limit = 20,
  }) async {
    final ids = List<String>.from(
      _storage.get<List<dynamic>>(_favoriteKey, defaultValue: []) ?? const [],
    );
    final slice = ids.skip(offset).take(limit);
    final records = <GeneratedImageModel>[];
    final idsToRemove = <String>[];

    for (final id in slice) {
      final record = await _getRecord(id);
      if (record != null) {
        // Check file tồn tại
        if (!record.isUrl) {
          final file = File(record.imagePath);
          if (!await file.exists()) {
            idsToRemove.add(id);
            continue;
          }
        }
        records.add(record);
      }
    }

    // Xóa các record không tồn tại
    for (final id in idsToRemove) {
      await _storage.delete('$_recordPrefix$id');
      await _updateFavorites(id: id, isFavorite: false);
    }

    return records;
  }

  @override
  Future<GeneratedImageModel> toggleFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    final record = await _getRecord(id);
    if (record == null) {
      throw Exception('Generated image $id not found');
    }

    final updated = record.copyWith(isFavorite: isFavorite);
    await _saveRecord(updated);
    await _updateFavorites(id: id, isFavorite: isFavorite);

    return updated;
  }

  @override
  Future<void> deleteImage(String id) async {
    final record = await _getRecord(id);
    if (record == null) return;

    await _storage.delete('$_recordPrefix$id');
    await _removeFromHistory(id);
    await _updateFavorites(id: id, isFavorite: false);

    // Xóa file trong thư mục app (KHÔNG phải gallery)
    // File trong gallery sẽ vẫn còn, nhưng đó là OK vì user đã có ảnh
    if (!kIsWeb && !record.isUrl) {
      try {
        final file = File(record.imagePath);
        if (await file.exists()) {
          await file.delete();
        }
        if (record.thumbnailPath != null) {
          final thumbFile = File(record.thumbnailPath!);
          if (await thumbFile.exists()) {
            await thumbFile.delete();
          }
        }
      } catch (e) {
        // Log error nhưng không throw, vì có thể file đã bị xóa
        print('Lỗi khi xóa file: $e');
      }
    }
  }

  @override
  Future<GeneratedImageModel?> getImageById(String id) async {
    return await _getRecord(id);
  }

  Future<void> _saveRecord(GeneratedImageModel record) async {
    await _storage.put('$_recordPrefix${record.id}', record.toMap());
  }

  Future<GeneratedImageModel?> _getRecord(String id) async {
    final data = _storage.get<Map<dynamic, dynamic>>('$_recordPrefix$id');
    if (data == null) return null;
    return GeneratedImageModel.fromMap(data);
  }

  Future<void> _updateHistory(List<String> newIds) async {
    final existing = List<String>.from(
      _storage.get<List<dynamic>>(_historyKey, defaultValue: []) ?? const [],
    );
    final updated = [
      ...newIds,
      ...existing.where((id) => !newIds.contains(id)),
    ];
    await _storage.put(_historyKey, updated);
  }

  Future<void> _removeFromHistory(String id) async {
    final existing = List<String>.from(
      _storage.get<List<dynamic>>(_historyKey, defaultValue: []) ?? const [],
    );
    final updated = existing.where((element) => element != id).toList();
    await _storage.put(_historyKey, updated);
  }

  Future<void> _updateFavorites({
    required String id,
    required bool isFavorite,
  }) async {
    final existing = List<String>.from(
      _storage.get<List<dynamic>>(_favoriteKey, defaultValue: []) ?? const [],
    );

    if (isFavorite) {
      if (!existing.contains(id)) {
        existing.insert(0, id);
      }
    } else {
      existing.removeWhere((element) => element == id);
    }

    await _storage.put(_favoriteKey, existing);
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(1 << 32).toRadixString(16);
    return '${timestamp}_$randomPart';
  }
}
