import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/export_constants.dart';
import '../../../core/widgets/custom_bottom_sheet.dart';

/// Bottom sheet để chọn size download ảnh
class DownloadSizeBottomSheet {
  /// Hiển thị bottom sheet chọn size download
  ///
  /// [onSizeSelected] - Callback khi chọn size
  ///   - size: 'small', 'medium', 'large'
  ///   - aspectRatio: '1:1', '3:4', '9:16', '4:3', '16:9'
  /// [aspectRatio] - Aspect ratio đã chọn từ màn trước (nếu null sẽ hiển thị tất cả)
  static Future<void> show({
    required BuildContext context,
    required Function(String size, String aspectRatio) onSizeSelected,
    String? aspectRatio, // Aspect ratio đã chọn từ màn trước
  }) {
    // Nếu có aspect ratio, chỉ hiển thị các size options cho aspect ratio đó
    if (aspectRatio != null) {
      return _showForAspectRatio(
        context: context,
        aspectRatio: aspectRatio,
        onSizeSelected: onSizeSelected,
      );
    }

    // Nếu không có aspect ratio, hiển thị tất cả (fallback)
    return CustomBottomSheet.show(
      closeText: tr('close'),
      context: context,
      title: tr('download_image'),
      options: [
        // Square (1:1)
        ..._buildAspectRatioGroup(
          context: context,
          title: tr('square_1_1'),
          aspectRatio: '1:1',
          sizes: [
            {'label': '${tr('small')} - 512 x 512px', 'size': 'small'},
            {'label': '${tr('medium')} - 768 x 768px', 'size': 'medium'},
            {'label': '${tr('large')} - 1024 x 1024px', 'size': 'large'},
          ],
          onSizeSelected: onSizeSelected,
        ),
        // Portrait (3:4)
        ..._buildAspectRatioGroup(
          context: context,
          title: tr('portrait_3_4'),
          aspectRatio: '3:4',
          sizes: [
            {'label': '${tr('small')} - 432 x 576px', 'size': 'small'},
            {'label': '${tr('medium')} - 648 x 864px', 'size': 'medium'},
            {'label': '${tr('large')} - 864 x 1152px', 'size': 'large'},
          ],
          onSizeSelected: onSizeSelected,
        ),
        // Vertical (9:16)
        ..._buildAspectRatioGroup(
          context: context,
          title: tr('vertical_9_16'),
          aspectRatio: '9:16',
          sizes: [
            {'label': '${tr('small')} - 378 × 672px', 'size': 'small'},
            {'label': '${tr('medium')} - 567 × 1008px', 'size': 'medium'},
            {'label': '${tr('large')} - 756 x 1344px', 'size': 'large'},
          ],
          onSizeSelected: onSizeSelected,
        ),
        // Landscape (4:3)
        ..._buildAspectRatioGroup(
          context: context,
          title: tr('landscape_4_3'),
          aspectRatio: '4:3',
          sizes: [
            {'label': '${tr('small')} - 576 × 432px', 'size': 'small'},
            {'label': '${tr('medium')} - 864 × 648px', 'size': 'medium'},
            {'label': '${tr('large')} - 1152 x 864px', 'size': 'large'},
          ],
          onSizeSelected: onSizeSelected,
        ),
        // Wide (16:9)
        ..._buildAspectRatioGroup(
          context: context,
          title: tr('wide_16_9'),
          aspectRatio: '16:9',
          sizes: [
            {'label': '${tr('small')} - 672 x 378px', 'size': 'small'},
            {'label': '${tr('medium')} - 1008 x 567px', 'size': 'medium'},
            {'label': '${tr('large')} - 1344 x 756px', 'size': 'large'},
          ],
          onSizeSelected: onSizeSelected,
        ),
      ],
    );
  }

  /// Hiển thị bottom sheet chỉ với các size options cho một aspect ratio cụ thể
  static Future<void> _showForAspectRatio({
    required BuildContext context,
    required String aspectRatio,
    required Function(String size, String aspectRatio) onSizeSelected,
  }) {
    // Lấy dimensions từ helper method
    final dimensionsMap = _getDimensionsForAspectRatio(aspectRatio);

    // Tạo danh sách options chỉ với 3 size: small, medium, large
    final options = [
      BottomSheetOption(
        title:
            '${tr('small')} - ${dimensionsMap['small']?['width']} x ${dimensionsMap['small']?['height']}px',
        subtitle: null,
        onTap: () {
          Navigator.pop(context);
          onSizeSelected('small', aspectRatio);
        },
      ),
      BottomSheetOption(
        title:
            '${tr('medium')} - ${dimensionsMap['medium']?['width']} x ${dimensionsMap['medium']?['height']}px',
        subtitle: null,
        onTap: () {
          Navigator.pop(context);
          onSizeSelected('medium', aspectRatio);
        },
      ),
      BottomSheetOption(
        title:
            '${tr('large')} - ${dimensionsMap['large']?['width']} x ${dimensionsMap['large']?['height']}px',
        subtitle: null,
        onTap: () {
          Navigator.pop(context);
          onSizeSelected('large', aspectRatio);
        },
      ),
    ];

    return CustomBottomSheet.show(
        context: context,
        title: tr('download_image'),
        closeText: tr('close'),
        options: options,
        optionBackgroundColor: AppColors.buttonDefaultColor,
        optionTextColor: AppColors.textPrimary);
  }

  /// Lấy dimensions cho một aspect ratio cụ thể
  static Map<String, Map<String, int>> _getDimensionsForAspectRatio(
      String aspectRatio) {
    final dimensionsMap = {
      '1:1': {
        'small': {'width': 512, 'height': 512},
        'medium': {'width': 768, 'height': 768},
        'large': {'width': 1024, 'height': 1024},
      },
      '3:4': {
        'small': {'width': 432, 'height': 576},
        'medium': {'width': 648, 'height': 864},
        'large': {'width': 864, 'height': 1152},
      },
      '9:16': {
        'small': {'width': 378, 'height': 672},
        'medium': {'width': 567, 'height': 1008},
        'large': {'width': 756, 'height': 1344},
      },
      '4:3': {
        'small': {'width': 576, 'height': 432},
        'medium': {'width': 864, 'height': 648},
        'large': {'width': 1152, 'height': 864},
      },
      '16:9': {
        'small': {'width': 672, 'height': 378},
        'medium': {'width': 1008, 'height': 567},
        'large': {'width': 1344, 'height': 756},
      },
    };

    return dimensionsMap[aspectRatio] ??
        {
          'small': {'width': 512, 'height': 512},
          'medium': {'width': 768, 'height': 768},
          'large': {'width': 1024, 'height': 1024},
        };
  }

  /// Tạo group options cho một aspect ratio
  static List<BottomSheetOption> _buildAspectRatioGroup({
    required String title,
    required String aspectRatio,
    required List<Map<String, String>> sizes,
    required Function(String size, String aspectRatio) onSizeSelected,
    required BuildContext context,
  }) {
    return sizes.map((sizeInfo) {
      return BottomSheetOption(
        title: sizeInfo['label']!,
        subtitle: title,
        onTap: () {
          Navigator.pop(context);
          onSizeSelected(sizeInfo['size']!, aspectRatio);
        },
      );
    }).toList();
  }
}
