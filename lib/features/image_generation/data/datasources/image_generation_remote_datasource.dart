import 'package:flutter/foundation.dart';
import '../../../../core/network/base_client.dart';
import '../../../../core/network/errors.dart';
import '../../../../core/services/app_check_service.dart';
import '../../../../core/utils/either.dart';
import '../models/image_generation_response_model.dart';

abstract class ImageGenerationRemoteDataSource {
  Future<Either<AppError, ImageGenerationResponseModel>> generateImage({
    required String model,
    required String prompt,
    required String userPrompt,
    List<String>? imageUrls,
    String? size,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  });
}

class ImageGenerationRemoteDataSourceImpl extends BaseClient
    implements ImageGenerationRemoteDataSource {
  ImageGenerationRemoteDataSourceImpl({required super.apiService});

  @override
  Future<Either<AppError, ImageGenerationResponseModel>> generateImage({
    required String model,
    required String prompt,
    required String userPrompt,
    List<String>? imageUrls,
    String? size,
    String? aspectRatio,
    int? styleId,
    String? existingId,
  }) async {
    final body = <String, dynamic>{
      'model': model,
      'prompt': prompt,
    };

    // Thêm field image nếu có imageUrls từ Firebase
    if (imageUrls != null && imageUrls.isNotEmpty) {
      body['image'] = imageUrls;
    }

    // Thêm field size nếu có
    if (size != null && size.isNotEmpty) {
      body['size'] = size;
    }

    final path = kDebugMode
        ? '/images/generations'
        : '/firebase/appcheck/images/generations';

    // Lấy App Check token và tạo headers
    final headers = <String, String>{};
    if (!kDebugMode) {
      final appCheckToken = await AppCheckService.shared.getToken();
      if (appCheckToken != null) {
        // TODO: Replace with your Firebase project ID
        headers['X-Firebase-ProjectID'] = '';
        headers['X-Firebase-AppCheck'] = appCheckToken;
      }
    }
    return appApiService.client.requestApi<ImageGenerationResponseModel>(
      path: path,
      method: HttpMethod.post,
      body: body,
      headers: headers.isNotEmpty ? headers : null,
      parser: (data) => _parseBytes(data),
      onError: (_) {},
    );
  }

  ImageGenerationResponseModel _parseBytes(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw AppError.unknown(message: 'Invalid response payload');
    }

    final items = data['data'];
    final urls = <String>[];
    final base64s = <String>[];
    final prompts = <String?>[];

    if (items is List) {
      for (final item in items) {
        if (item is! Map<String, dynamic>) {
          prompts.add(null);
          continue;
        }

        prompts.add(item['revised_prompt'] as String?);

        // Ưu tiên check base64 trước (b64_json hoặc base64)
        final b64Json = item['b64_json'] as String?;
        final base64 = item['base64'] as String?;

        if ((b64Json != null && b64Json.isNotEmpty) ||
            (base64 != null && base64.isNotEmpty)) {
          // Backend trả về base64
          final base64String = b64Json ?? base64!;
          base64s.add(base64String);
        } else {
          // Backend trả về URL
          final url = item['url'] as String?;
          if (url != null && url.isNotEmpty) {
            urls.add(url);
          }
        }
      }
    } else {
      prompts.add(null);
    }

    final createdValue = data['created'];
    final created = createdValue is int ? createdValue : null;

    final usage = data['usage'];
    final usageMap =
        usage is Map<String, dynamic> ? Map<String, dynamic>.from(usage) : null;

    return ImageGenerationResponseModel(
      imageUrls: urls,
      imageBase64s: base64s.isNotEmpty ? base64s : null,
      created: created,
      revisedPrompts: prompts,
      usage: usageMap,
    );
  }
}
