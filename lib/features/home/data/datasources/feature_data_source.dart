import 'package:flutter_quick_base/features/home/data/model/home_action_type.dart';

class FeatureItemModel {
  final String icon;
  final String title;
  final HomeActionType actionType;
  final bool isComingSoon;
  final int pageIndex; // Để phân chia vào các page

  FeatureItemModel({
    required this.icon,
    required this.title,
    required this.actionType,
    this.isComingSoon = false,
    required this.pageIndex,
  });
}

class FeatureDataSource {
  // Method đơn giản - trả về list features
  static List<FeatureItemModel> getFeatures() {
    return [
      // Page 0
      FeatureItemModel(
        icon: 'ic_restore',
        title: 'Restore',
        actionType: HomeActionType.restore,
        isComingSoon: false,
        pageIndex: 0,
      ),
      FeatureItemModel(
        icon: 'ic_relight',
        title: 'Relight',
        actionType: HomeActionType.relight,
        isComingSoon: false,
        pageIndex: 0,
      ),
      FeatureItemModel(
        icon: 'ic_face_swap',
        title: 'Face Swap',
        actionType: HomeActionType.faceSwap,
        isComingSoon: true,
        pageIndex: 0,
      ),
      FeatureItemModel(
        icon: 'ic_mood_change',
        title: 'Mood change',
        actionType: HomeActionType.moodChange,
        isComingSoon: false,
        pageIndex: 0,
      ),
      FeatureItemModel(
        icon: 'ic_remove_background',
        title: 'Remove Backgrou...',
        actionType: HomeActionType.removeBackground,
        isComingSoon: true,
        pageIndex: 0,
      ),
      FeatureItemModel(
        icon: 'ic_change_background',
        title: 'Change Background',
        actionType: HomeActionType.changeBackground,
        isComingSoon: false,
        pageIndex: 0,
      ),
      // Page 1
      FeatureItemModel(
        icon: 'ic_remove_object',
        title: 'Remove object',
        actionType: HomeActionType.removeObject,
        isComingSoon: true,
        pageIndex: 1,
      ),
      FeatureItemModel(
        icon: 'ic_expand_image',
        title: 'Expand Image',
        actionType: HomeActionType.expandImage,
        isComingSoon: true,
        pageIndex: 1,
      ),
      FeatureItemModel(
        icon: 'ic_image_enhancer',
        title: 'Image Enhancer',
        actionType: HomeActionType.imageEnhancer,
        isComingSoon: false,
        pageIndex: 1,
      ),
    ];
  }
}
