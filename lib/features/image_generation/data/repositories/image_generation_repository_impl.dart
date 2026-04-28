import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../../core/network/errors.dart';
import '../../../../core/utils/either.dart';
import '../../domain/entities/generated_image.dart';
import '../../domain/repositories/image_generation_repository.dart';
import '../datasources/generated_image_local_datasource.dart';
import '../datasources/image_generation_remote_datasource.dart';
import '../models/generated_image_model.dart';

class ImageGenerationRepositoryImpl implements ImageGenerationRepository {
  ImageGenerationRepositoryImpl({
    required ImageGenerationRemoteDataSource remoteDataSource,
    required GeneratedImageLocalDataSource localDataSource,
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource;

  final ImageGenerationRemoteDataSource _remoteDataSource;
  final GeneratedImageLocalDataSource _localDataSource;

  @override
  Future<Either<AppError, GeneratedImage>> saveImageToHistory({
    required String localPath,
    required String prompt,
    required String userPrompt,
    required DateTime createdAt,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  }) async {
    try {
      final record = await _localDataSource.saveImageToHistory(
        localPath: localPath,
        prompt: prompt,
        userPrompt: userPrompt,
        createdAt: createdAt,
        aspectRatio: aspectRatio,
        styleId: styleId,
        existingId: existingId,
      );
      return Right(record.toEntity());
    } catch (e) {
      return Left(
          AppError.unknown(message: 'Failed to save image to history: $e'));
    }
  }

  @override
  Future<Either<AppError, List<GeneratedImage>>> generateImage({
    required String model,
    required String prompt,
    required String userPrompt,
    List<String>? imageUrls,
    String? size,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  }) async {
    final result = await _remoteDataSource.generateImage(
      model: model,
      prompt: prompt,
      userPrompt: userPrompt,
      imageUrls: imageUrls,
      size: size,
      aspectRatio: aspectRatio,
      styleId: styleId,
      existingId: existingId,
    );

    return await result.fold<Future<Either<AppError, List<GeneratedImage>>>>(
      (error) async => Left(error),
      (responseModel) async {
        // Flag để fake convert URL sang base64 (để test)
        // Set thành true để test với base64, false để dùng URL thật
        const bool fakeConvertToBase64 =
            true; // TODO: Có thể move vào config hoặc remote config

        final List<String> imagePaths = [];

        // Ưu tiên dùng base64 nếu có
        if (responseModel.imageBase64s != null &&
            responseModel.imageBase64s!.isNotEmpty) {
          imagePaths.addAll(responseModel.imageBase64s!);
        } else if (responseModel.imageUrls.isNotEmpty) {
          // Nếu không có base64, dùng URLs
          if (fakeConvertToBase64) {
            // Fake convert URL sang base64 để test
            for (final url in responseModel.imageUrls) {
              try {
                final base64String = await _convertUrlToBase64(url);
                imagePaths.add(base64String);
              } catch (e) {
                print('Lỗi khi fake convert URL sang base64: $e');
                // Fallback về URL nếu convert lỗi
                imagePaths.add(url);
              }
            }
          } else {
            imagePaths.addAll(responseModel.imageUrls);
          }
        }

        final images = imagePaths.map((imagePath) {
          final tempId =
              'temp_${DateTime.now().millisecondsSinceEpoch}_${imagePaths.indexOf(imagePath)}';
          return GeneratedImage(
            id: tempId,
            prompt: prompt,
            userPrompt: userPrompt,
            imagePath: imagePath,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
                (responseModel.created ??
                        DateTime.now().millisecondsSinceEpoch ~/ 1000) *
                    1000),
            aspectRatio: aspectRatio,
            styleId: styleId,
          );
        }).toList();

        return Right(images);
      },
    );
  }

  /// Helper method để fake convert URL sang base64 (để test)
  Future<String> _convertUrlToBase64(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      final imageBytes = response.data;
      if (imageBytes == null) {
        throw Exception('Không thể download ảnh từ URL');
      }
      // Convert bytes sang base64
      return base64Encode(imageBytes);
    } catch (e) {
      print('Lỗi khi convert URL sang base64: $e');
      rethrow;
    }
  }

  @override
  Future<Either<AppError, List<GeneratedImage>>> getHistory({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final records =
          await _localDataSource.getHistory(offset: offset, limit: limit);
      return Right(_toEntities(records));
    } catch (e) {
      return Left(AppError.unknown(message: 'Failed to load history: $e'));
    }
  }

  @override
  Future<Either<AppError, List<GeneratedImage>>> getFavorites({
    int offset = 0,
    int limit = 20,
  }) async {
    try {
      final records =
          await _localDataSource.getFavorites(offset: offset, limit: limit);
      return Right(_toEntities(records));
    } catch (e) {
      return Left(AppError.unknown(message: 'Failed to load favorites: $e'));
    }
  }

  @override
  Future<Either<AppError, GeneratedImage>> toggleFavorite({
    required String id,
    required bool isFavorite,
  }) async {
    try {
      final record = await _localDataSource.toggleFavorite(
        id: id,
        isFavorite: isFavorite,
      );
      return Right(record.toEntity());
    } catch (e) {
      return Left(AppError.unknown(message: 'Failed to update favorite: $e'));
    }
  }

  @override
  Future<Either<AppError, void>> deleteImage(String id) async {
    try {
      await _localDataSource.deleteImage(id);
      return const Right(null);
    } catch (e) {
      return Left(AppError.unknown(message: 'Failed to delete image: $e'));
    }
  }

  List<GeneratedImage> _toEntities(List<GeneratedImageModel> models) {
    return models.map((model) => model.toEntity()).toList();
  }
}
