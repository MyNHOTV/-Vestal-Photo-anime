import '../../../../core/network/errors.dart';
import '../../../../core/utils/either.dart';
import '../entities/generated_image.dart';
import '../repositories/image_generation_repository.dart';

abstract class ImageGenerationUsecase {
  Future<Either<AppError, GeneratedImage>> saveImageToHistoryAfterDownload({
    required String localPath,
    required String prompt,
    required String userPrompt,
    required DateTime createdAt,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  });

  Future<Either<AppError, List<GeneratedImage>>> generateImage({
    required String model,
    required String prompt,
    required String userPrompt,
    List<String>? imageUrls,
    String? size,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  });

  Future<Either<AppError, List<GeneratedImage>>> getGeneratedHistory({
    int offset = 0,
    int limit = 20,
  });

  Future<Either<AppError, List<GeneratedImage>>> getFavoriteGeneratedImages({
    int offset = 0,
    int limit = 20,
  });

  Future<Either<AppError, GeneratedImage>> toggleFavoriteGeneratedImage({
    required String id,
    required bool isFavorite,
  });

  Future<Either<AppError, void>> deleteGeneratedImage(String id);
}

class ImageGenerationUsecaseImpl implements ImageGenerationUsecase {
  ImageGenerationUsecaseImpl(this._repository);

  final ImageGenerationRepository _repository;

  @override
  Future<Either<AppError, GeneratedImage>> saveImageToHistoryAfterDownload({
    required String localPath,
    required String prompt,
    required String userPrompt,
    required DateTime createdAt,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  }) {
    return _repository.saveImageToHistory(
      localPath: localPath,
      prompt: prompt,
      userPrompt: userPrompt,
      createdAt: createdAt,
      aspectRatio: aspectRatio,
      styleId: styleId,
      existingId: existingId,
    );
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
  }) {
    return _repository.generateImage(
        model: model,
        prompt: prompt,
        userPrompt: userPrompt,
        imageUrls: imageUrls,
        size: size,
        aspectRatio: aspectRatio,
        styleId: styleId,
        existingId: existingId);
  }

  @override
  Future<Either<AppError, List<GeneratedImage>>> getGeneratedHistory({
    int offset = 0,
    int limit = 20,
  }) {
    return _repository.getHistory(offset: offset, limit: limit);
  }

  @override
  Future<Either<AppError, List<GeneratedImage>>> getFavoriteGeneratedImages({
    int offset = 0,
    int limit = 20,
  }) {
    return _repository.getFavorites(offset: offset, limit: limit);
  }

  @override
  Future<Either<AppError, GeneratedImage>> toggleFavoriteGeneratedImage({
    required String id,
    required bool isFavorite,
  }) {
    return _repository.toggleFavorite(id: id, isFavorite: isFavorite);
  }

  @override
  Future<Either<AppError, void>> deleteGeneratedImage(String id) {
    return _repository.deleteImage(id);
  }
}
