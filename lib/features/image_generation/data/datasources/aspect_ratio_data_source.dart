import '../model/aspect_ratio_model.dart';

/// Data source chứa danh sách aspect ratios
class AspectRatioDataSource {
  AspectRatioDataSource._();

  /// Lấy danh sách tất cả aspect ratios
  static List<AspectRatioModel> getAspectRatios() {
    return [
      const AspectRatioModel(
        id: 'square_1_1',
        aspectRatio: '1:1',
        i18nKey: 'ratio_1_1',
        iconWidth: 16,
        iconHeight: 16,
        isDefault: true,
      ),
      const AspectRatioModel(
        id: 'portrait_3_4',
        aspectRatio: '3:4',
        i18nKey: 'ratio_4_5',
        iconWidth: 16,
        iconHeight: 30,
      ),
      const AspectRatioModel(
        id: 'vertical_9_16',
        aspectRatio: '9:16',
        i18nKey: 'ratio_9_16',
        iconWidth: 18,
        iconHeight: 44,
      ),
      const AspectRatioModel(
        id: 'landscape_4_3',
        aspectRatio: '4:3',
        i18nKey: 'landscape_4_3',
        iconWidth: 30,
        iconHeight: 16,
      ),
      const AspectRatioModel(
        id: 'wide_16_9',
        aspectRatio: '16:9',
        i18nKey: 'wide_16_9',
        iconWidth: 44,
        iconHeight: 16,
      ),
    ];
  }

  /// Lấy aspect ratio mặc định
  static AspectRatioModel? getDefault() {
    return getAspectRatios().firstWhere(
      (ratio) => ratio.isDefault,
      orElse: () => getAspectRatios().first,
    );
  }

  /// Tìm aspect ratio theo value
  static AspectRatioModel? findByValue(String aspectRatio) {
    try {
      return getAspectRatios().firstWhere(
        (ratio) => ratio.aspectRatio == aspectRatio,
      );
    } catch (e) {
      return null;
    }
  }
}
