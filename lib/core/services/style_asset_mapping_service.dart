/// Service để map style name và category với asset path
/// Ưu tiên remote config (imageUrl), chỉ fallback về local assets nếu không có
class StyleAssetMappingService {
  StyleAssetMappingService._internal();
  static final StyleAssetMappingService shared =
      StyleAssetMappingService._internal();

  // Map category name với folder name (case-insensitive)
  static const Map<String, String> _categoryFolderMap = {
    'Trending': 'category_trending',
    'Dreamy Fantasy': 'category_dreamy_fantasy',
    'Cute': 'category_cute',
    'Life Style': 'category_life_style',
    'Lifestyle': 'category_life_style',
    'Life style': 'category_life_style', // Thêm variant
    'Action': 'category_action',
  };

  // Map style name với file name (nếu có tên khác)
  // Thêm các style mới từ remote config
  static const Map<String, String> _styleNameMap = {
    'Ghibli':
        'ghibli', // Thêm mapping cho "Ghibli" (không phải "Ghibli Studio")
    'Ghibli Studio': 'ghibli',
    'Makoto Shinkai': 'makoto_shinkai',
    'Kyoto Animation': 'kyoto_animation',
    'Webtoon Style': 'webtoon_look',
    'Webtoon Look': 'webtoon_look',
    'Trendy Fashion': 'trendy_fashion',
    'Soft Life': 'soft_life',
    'Moe Idol': 'moe_idol',
    'Mahou Shoujo': 'mahou_shoujo',
    'Kemonomimi': 'kemonomimi',
    'Synthwave': 'synthwave',
    'Sports': 'sports',
    'Vintage': 'vintage',
    'Gothic': 'gothic',
    'Isekai Fantasy': 'isekai_fantasy',
    'Shounen Action': 'shounen_action',
    'Shoujo': 'shoujo',
    'Chibi': 'chibi',
    'Kawaii': 'kawaii',
    'Cyberpunk': 'cyberpunk',
    'Cool Guy': 'cool_guy',
    'Hero': 'hero',
    'Luffy': 'luffy',
    'Naruto': 'naruto',
    'Ninja': 'ninja',
    'Secret Agent': 'secret_agent',
    'Bunny Muse': 'bunny_muse',
    'Fox Girl': 'fox_girl',
    'Hoodie Pulling': 'hoodie_pulling',
    'Kitsune Spirit': 'kitsune_spirit',
    'Sakura Bloom': 'sakura_bloom',
    'Y2K Glow': 'y2k_glow',
    'Ghibli Spring': 'ghibli_spring',
    'Ghibli Winter': 'ghibli_winter',
    'Idol Pop': 'idol_pop',
    'Mystical': 'mystical',
    'Pastel Art': 'pastel_art',
    'Water Color Art': 'water_color_art',
    'Water Color': 'water_color_art',
    'Cozy Life': 'cozy_life',
    'Ghibli Lovers': 'ghibli_lovers',
    'High School': 'high_school',
    'Lofi': 'lofi',
    'Youth Romance': 'youth_romance',
    'Zootopia Couple': 'zootopia_couple',
    'Anime 3D': 'anime_3d',
    'Disney Princess': 'disney_princess',
    'Exhibition': 'exhibition',
    'Figure Anime': 'figure_anime',
    'Soft Knit Doll': 'soft_knit_doll',
    'Winter': 'winter',
    'Zootopia': 'zootopia',
  };

  /// Normalize style name thành file name (case-insensitive)
  String _normalizeStyleName(String styleName) {
    // Trim whitespace
    final trimmed = styleName.trim();
    if (trimmed.isEmpty) return 'unknown';

    // Kiểm tra trong map trước (case-insensitive)
    final normalizedKey = trimmed.toLowerCase();
    for (final entry in _styleNameMap.entries) {
      if (entry.key.toLowerCase() == normalizedKey) {
        return entry.value;
      }
    }

    // Convert to lowercase, replace spaces and special chars with underscores
    // Giữ lại số và chữ cái, chỉ thay thế khoảng trắng và ký tự đặc biệt
    return trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'),
            '') // Remove special chars nhưng giữ dấu gạch ngang
        .replaceAll(RegExp(r'[\s_-]+'),
            '_') // Replace spaces, underscores, hyphens với single underscore
        .replaceAll(
            RegExp(r'^_+|_+$'), '') // Remove leading/trailing underscores
        .trim();
  }

  /// Lấy folder name từ category name (case-insensitive)
  String _getCategoryFolderName(String categoryName) {
    final trimmed = categoryName.trim();
    if (trimmed.isEmpty) return 'category_trending';

    // Kiểm tra exact match trước
    if (_categoryFolderMap.containsKey(trimmed)) {
      return _categoryFolderMap[trimmed]!;
    }

    // Kiểm tra case-insensitive
    final normalizedKey = trimmed.toLowerCase();
    for (final entry in _categoryFolderMap.entries) {
      if (entry.key.toLowerCase() == normalizedKey) {
        return entry.value;
      }
    }

    // Fallback: normalize category name
    final normalized = trimmed
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(RegExp(r'[\s_-]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    return 'category_$normalized';
  }

  /// Tìm asset path cho style dựa trên category
  /// Chỉ dùng khi không có imageUrl và imageAsset từ remote config
  String? getStyleAssetPath(String styleName, String categoryName) {
    if (styleName.isEmpty) return null;

    final folderName = _getCategoryFolderName(categoryName);
    final normalizedName = _normalizeStyleName(styleName);

    if (normalizedName.isEmpty || normalizedName == 'unknown') {
      return null;
    }

    return 'assets/image/$folderName/style_$normalizedName.png';
  }

  /// Lấy asset path cho slider
  /// Ưu tiên imageUrl từ remote config, chỉ dùng local nếu không có
  String? getSliderAssetPath(int sliderId, {String? imageUrl}) {
    // Ưu tiên imageUrl từ remote config
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return imageUrl;
    }

    // Fallback về local asset cho slider 1, 2, 3
    if (sliderId >= 1 && sliderId <= 3) {
      return 'assets/image/slider_$sliderId.jpg';
    }

    return null;
  }
}
