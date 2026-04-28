enum HomeActionType {
  // 3 nút cố định
  colorize,
  timeSeason,
  profile,

  // Feature items
  restore,
  relight,
  faceSwap,
  moodChange,
  removeBackground,
  changeBackground,
  removeObject,
  expandImage,
  imageEnhancer,
}

class FeatureItemModel {
  final String id;
  final String icon;
  final String title;
  final HomeActionType actionType;
  final bool isComingSoon;
  final int? pageIndex; // Để phân chia vào các page

  FeatureItemModel({
    required this.id,
    required this.icon,
    required this.title,
    required this.actionType,
    this.isComingSoon = false,
    this.pageIndex,
  });

  factory FeatureItemModel.fromJson(Map<String, dynamic> json) {
    return FeatureItemModel(
      id: json['id']?.toString() ?? '',
      icon: json['icon']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      actionType: _parseActionType(json['actionType']?.toString() ?? ''),
      isComingSoon: json['isComingSoon'] == true,
      pageIndex: json['pageIndex'] is int
          ? json['pageIndex']
          : int.tryParse(json['pageIndex']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'icon': icon,
      'title': title,
      'actionType': actionType.name,
      'isComingSoon': isComingSoon,
      'pageIndex': pageIndex,
    };
  }

  static HomeActionType _parseActionType(String value) {
    return HomeActionType.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => HomeActionType.restore,
    );
  }
}
