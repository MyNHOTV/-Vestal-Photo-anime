import '../../../../core/network/errors.dart';
import '../../../../core/utils/either.dart';
import '../entities/generated_image.dart';

abstract class ImageGenerationRepository {
  Future<Either<AppError, GeneratedImage>> saveImageToHistory({
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

  Future<Either<AppError, List<GeneratedImage>>> getHistory({
    int offset,
    int limit,
  });

  Future<Either<AppError, List<GeneratedImage>>> getFavorites({
    int offset,
    int limit,
  });

  Future<Either<AppError, GeneratedImage>> toggleFavorite({
    required String id,
    required bool isFavorite,
  });

  Future<Either<AppError, void>> deleteImage(String id);
}
