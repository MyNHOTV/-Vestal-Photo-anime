import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_quick_base/core/services/connectivity_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/services/style_asset_mapping_service.dart';
import 'package:flutter_quick_base/core/storage/local_storage_service.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_model.dart';
import 'package:flutter_quick_base/features/home/data/model/image_style_group_model.dart';
import 'package:flutter_quick_base/features/home/data/model/carousel_style_item_model.dart';

class HomeDataSource {
  // Keys cho local storage
  static const String _cachedStylesUrlKey = 'image_style_cloudfare_url';
  static const String _cachedGroupsUrlKey = 'image_style_groups_cloudfare_url';
  static const String _cachedStylesKey = 'image_style_cloudfare_styles';
  static const String _cachedGroupsKey = 'image_style_cloudfare_groups';
  static const String _cachedSlidersKey = 'image_style_cloudfare_sliders';

  // Flag để tránh fetch nhiều lần
  static bool _isFetching = false;
  static bool _isFetchingGroups = false;
  static bool _hasFetchedStylesOnce = false;
  static bool _hasFetchedGroupsOnce = false;

  // Method SYNC - load từ local storage (dùng khi cần ngay lập tức)
  static List<ImageStyleModel> getImageStyles() {
    // Thử load từ local storage trước
    final cachedStyles = _loadStylesFromLocal();
    if (cachedStyles.isNotEmpty) {
      return cachedStyles;
    }

    // Nếu chưa có cache, trả về default
    return _getDefaultStyles();
  }

  // ========== API 1: Fetch Styles (ĐỘC LẬP) ==========
  // Gọi image_style_cloudfare_v2 → parse {"styles": [...]}
  // Có thể gọi riêng: unawaited(HomeDataSource.fetchImageStyles())
  // Không phụ thuộc vào API 2, tự quản lý cache riêng
  static Future<List<ImageStyleModel>> fetchImageStyles() async {
    // Tránh fetch nhiều lần đồng thời
    if (_isFetching) {
      return _loadStylesFromLocal().isNotEmpty
          ? _loadStylesFromLocal()
          : _getDefaultStyles();
    }

    // Kiểm tra mạng
    if (!ConnectivityService.shared.isConnected) {
      final cached = _loadStylesFromLocal();
      return cached.isNotEmpty ? cached : _getDefaultStyles();
    }

    // Lấy URL từ Remote Config
    final raw = RemoteConfigService.shared.configRx['image_style_cloudfare_v2'];
    if (raw == null || raw.toString().isEmpty) {
      return _getDefaultStyles();
    }

    final currentUrl = raw.toString();
    final savedUrl =
        LocalStorageService.shared.get<String>(_cachedStylesUrlKey);

    // Check cache: nếu URL không đổi và đã fetch → dùng cache
    if (_hasFetchedStylesOnce && savedUrl == currentUrl) {
      final cached = _loadStylesFromLocal();
      if (cached.isNotEmpty) {
        print('✅ Using cached styles: ${cached.length}');
        return cached;
      }
    }

    // Fetch từ API
    _isFetching = true;
    try {
      print('📥 Fetching styles from: $currentUrl');
      final dio = Dio();
      final response = await dio.get(
        currentUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final jsonString =
            response.data is String ? response.data : jsonEncode(response.data);

        final styles = _parseStylesFromJson(jsonString);
        if (styles.isNotEmpty) {
          await _saveStylesToLocal(currentUrl, styles);
          _hasFetchedStylesOnce = true;
          print('✅ Fetched and cached ${styles.length} styles');
          return styles;
        }
      }
    } catch (e) {
      print('❌ Error fetching styles: $e');
      final cached = _loadStylesFromLocal();
      if (cached.isNotEmpty) return cached;
    } finally {
      _isFetching = false;
    }

    return _getDefaultStyles();
  }

  // Method để fetch khi mạng về (gọi từ connectivity listener)
  static Future<void> fetchWhenOnline() async {
    // Chỉ fetch nếu chưa fetch lần nào hoặc URL thay đổi
    if (!_hasFetchedStylesOnce || _shouldFetchAgain()) {
      await fetchImageStyles();
      await fetchImageStyleGroups();
    }
  }

  // Kiểm tra xem có cần fetch lại không (URL thay đổi)
  static bool _shouldFetchAgain() {
    final raw = RemoteConfigService.shared.configRx['image_style_cloudfare_v2'];
    if (raw == null || raw.toString().isEmpty) {
      return false;
    }

    final currentUrl = raw.toString();
    final savedUrl =
        LocalStorageService.shared.get<String>(_cachedStylesUrlKey);
    return savedUrl != currentUrl;
  }

  // Parse JSON và order by id
  static List<ImageStyleModel> _parseStylesFromJson(String jsonString) {
    try {
      // Validate JSON string trước khi parse
      jsonString = jsonString.trim();
      if (jsonString.isEmpty) {
        print('❌ Empty JSON string in _parseStylesFromJson');
        return [];
      }

      // Kiểm tra xem có phải JSON hợp lệ không
      if (!jsonString.startsWith('{') && !jsonString.startsWith('[')) {
        print('❌ Invalid JSON format: does not start with { or [');
        print(
            'First 100 chars: ${jsonString.length > 100 ? jsonString.substring(0, 100) : jsonString}');
        return [];
      }

      final decoded = jsonDecode(jsonString);
      List<dynamic> stylesList;

      // Hỗ trợ cả array trực tiếp hoặc object có key 'data' hoặc 'styles'
      if (decoded is List) {
        stylesList = decoded;
        print('✅ Parsing styles from array, count: ${stylesList.length}');
      } else if (decoded is Map) {
        stylesList = decoded['data'] ?? decoded['styles'] ?? [];
        print('✅ Parsing styles from object, count: ${stylesList.length}');
      } else {
        print('❌ Invalid decoded type: ${decoded.runtimeType}');
        return [];
      }

      if (stylesList.isEmpty) {
        print('⚠️ Styles list is empty');
        return [];
      }

      // Convert to ImageStyleModel và order by id
      final List<ImageStyleModel> styles = stylesList
          .where((item) {
            if (item is! Map<String, dynamic>) {
              print(
                  '⚠️ Skipping invalid item (not a Map): ${item.runtimeType}');
              return false;
            }
            if (item['id'] == null) {
              print('⚠️ Skipping item without id: $item');
              return false;
            }
            return true;
          })
          .map((item) {
            try {
              final map = Map<String, dynamic>.from(item as Map);

              // Parse keyword và gán vào description (ưu tiên keyword, fallback về description)
              final description = map['keyword']?.toString() ??
                  map['description']?.toString() ??
                  '';

              return ImageStyleModel(
                id: map['id'] is int
                    ? map['id']
                    : int.tryParse(map['id'].toString()) ?? 0,
                name: map['name']?.toString() ?? '',
                description: description,
                imageUrl: _normalizeImageUrl(map['imageUrl']?.toString()),
                imageAsset: _normalizeImageAsset(
                  map['imageAsset']?.toString(),
                  map['imageUrl']?.toString(),
                ),
                isSelected: map['isSelected'] == true,
              );
            } catch (e) {
              print('❌ Error parsing style item: $e');
              print('Item: $item');
              return null;
            }
          })
          .whereType<ImageStyleModel>()
          .toList();

      // Order by id
      styles.sort((a, b) => a.id.compareTo(b.id));

      print('✅ Successfully parsed ${styles.length} styles');
      return styles;
    } catch (e, stackTrace) {
      print('❌ Error parsing image styles JSON: $e');
      if (e is FormatException) {
        print('FormatException details: ${e.message}');
        print('Source: ${e.source}');
        print('Offset: ${e.offset}');
        // Log context around error
        if (e.offset != null && jsonString.length > e.offset!) {
          final start = (e.offset! - 50).clamp(0, jsonString.length);
          final end = (e.offset! + 50).clamp(0, jsonString.length);
          print(
              'Context around error (offset ${e.offset}): ${jsonString.substring(start, end)}');
        }
      }
      print('Stack trace: $stackTrace');
      print('JSON length: ${jsonString.length}');
      print(
          'JSON preview (first 500 chars): ${jsonString.length > 500 ? jsonString.substring(0, 500) : jsonString}');
      return [];
    }
  }

  // Helper để normalize imageUrl - nếu là asset path thì trả về null
  static String? _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    // Nếu là asset path, không dùng làm imageUrl
    if (url.startsWith('assets/')) return null;
    // Chỉ trả về nếu là URL thực sự
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    return null;
  }

  // Helper để normalize imageAsset - ưu tiên imageAsset, fallback về imageUrl nếu là asset path
  static String? _normalizeImageAsset(String? imageAsset, String? imageUrl) {
    // Nếu đã có imageAsset thì dùng
    if (imageAsset != null && imageAsset.isNotEmpty) {
      return imageAsset;
    }
    // Nếu imageUrl là asset path thì dùng làm imageAsset
    if (imageUrl != null && imageUrl.startsWith('assets/')) {
      return imageUrl;
    }
    return null;
  }

  // Lưu URL và styles vào local storage
  static Future<void> _saveStylesToLocal(
    String url,
    List<ImageStyleModel> styles,
  ) async {
    try {
      // Lưu URL
      await LocalStorageService.shared.put(_cachedStylesUrlKey, url);

      // Convert styles sang JSON để lưu
      final stylesJson = styles
          .map((style) => {
                'id': style.id,
                'name': style.name,
                'description': style.description,
                'imageUrl': style.imageUrl,
                'imageAsset': style.imageAsset,
                'isSelected': style.isSelected,
              })
          .toList();

      await LocalStorageService.shared.put(_cachedStylesKey, stylesJson);
      print('✅ Saved image styles to local storage');
    } catch (e) {
      print('Error saving image styles to local storage: $e');
    }
  }

  // Load styles từ local storage
  static List<ImageStyleModel> _loadStylesFromLocal() {
    try {
      final stylesJson = LocalStorageService.shared.get<List<dynamic>>(
        _cachedStylesKey,
      );

      if (stylesJson == null || stylesJson.isEmpty) {
        return [];
      }

      final List<ImageStyleModel> styles = stylesJson.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        return ImageStyleModel(
          id: map['id'] is int
              ? map['id']
              : int.tryParse(map['id'].toString()) ?? 0,
          name: map['name']?.toString() ?? '',
          description: map['description']?.toString() ?? '',
          imageUrl: map['imageUrl']?.toString(),
          imageAsset: map['imageAsset']?.toString(),
          isSelected: map['isSelected'] == true,
        );
      }).toList();

      // Order by id (đảm bảo)
      styles.sort((a, b) => a.id.compareTo(b.id));

      return styles;
    } catch (e) {
      print('Error loading image styles from local storage: $e');
      return [];
    }
  }

  // Parse sliders từ JSON
  // Chỉ parse slider data với styleId, không map styles (có thể query sau)
  static List<CarouselStyleItemModel> _parseSlidersFromJson(String jsonString) {
    print('🔄 _parseSlidersFromJson called');
    try {
      // Validate JSON string trước khi parse
      jsonString = jsonString.trim();
      if (jsonString.isEmpty) {
        print('❌ Empty JSON string in _parseSlidersFromJson');
        return [];
      }

      print('📄 Decoding JSON for sliders, length: ${jsonString.length}');
      final decoded = jsonDecode(jsonString);
      final mappingService = StyleAssetMappingService.shared;

      if (decoded is Map) {
        print('📋 JSON is Map, keys: ${decoded.keys.toList()}');
        print('📋 Has sliders key: ${decoded.containsKey('sliders')}');

        if (decoded['sliders'] != null) {
          final slidersList = decoded['sliders'] as List<dynamic>;
          print('✅ Parsing sliders from JSON, count: ${slidersList.length}');

          return slidersList
              .map((item) {
                try {
                  if (item is! Map<String, dynamic>) {
                    print(
                        '⚠️ Skipping invalid slider (not a Map): ${item.runtimeType}');
                    return null;
                  }

                  final map = Map<String, dynamic>.from(item);
                  final sliderId = map['id'] is int
                      ? map['id']
                      : int.tryParse(map['id'].toString()) ?? 0;
                  final styleId = map['styleId'] is int
                      ? map['styleId']
                      : int.tryParse(map['styleId'].toString()) ?? 0;

                  // Ưu tiên imageUrl từ remote config, fallback về local assets nếu không có
                  final imageUrl = map['imageUrl']?.toString();
                  final image = mappingService.getSliderAssetPath(
                        sliderId,
                        imageUrl: imageUrl,
                      ) ??
                      '';

                  return CarouselStyleItemModel(
                    id: styleId, // Dùng styleId làm id để query style sau
                    title: '', // Có thể lấy từ style nếu cần
                    image: image,
                  );
                } catch (e) {
                  print('❌ Error parsing slider item: $e');
                  print('Item: $item');
                  return null;
                }
              })
              .whereType<CarouselStyleItemModel>()
              .toList();
        } else {
          print('⚠️ sliders key is null');
        }
      } else {
        print('⚠️ JSON is not a Map, type: ${decoded.runtimeType}');
      }

      print('⚠️ No sliders found in JSON');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error parsing sliders JSON: $e');
      if (e is FormatException) {
        print('FormatException details: ${e.message}');
        print('Source: ${e.source}');
        print('Offset: ${e.offset}');
        // Log context around error
        if (e.offset != null && jsonString.length > e.offset!) {
          final start = (e.offset! - 50).clamp(0, jsonString.length);
          final end = (e.offset! + 50).clamp(0, jsonString.length);
          print(
              'Context around error (offset ${e.offset}): ${jsonString.substring(start, end)}');
        }
      }
      print('Stack trace: $stackTrace');
      print('JSON length: ${jsonString.length}');
      print(
          'JSON preview (first 500 chars): ${jsonString.length > 500 ? jsonString.substring(0, 500) : jsonString}');
      return [];
    }
  }

  // Lưu sliders vào local storage
  static Future<void> _saveSlidersToLocal(
    List<CarouselStyleItemModel> sliders,
  ) async {
    try {
      final slidersJson = sliders
          .map((slider) => {
                'id': slider.id,
                'title': slider.title,
                'image': slider.image,
              })
          .toList();

      await LocalStorageService.shared.put(_cachedSlidersKey, slidersJson);
      print('✅ Saved sliders to local storage');
    } catch (e) {
      print('Error saving sliders to local storage: $e');
    }
  }

  // Load sliders từ local storage
  static List<CarouselStyleItemModel> getSliders() {
    try {
      final slidersJson =
          LocalStorageService.shared.get<List<dynamic>>(_cachedSlidersKey);

      if (slidersJson == null || slidersJson.isEmpty) {
        return [];
      }

      return slidersJson
          .map((json) => CarouselStyleItemModel.fromMap(
                Map<String, dynamic>.from(json as Map),
              ))
          .toList();
    } catch (e) {
      print('Error loading sliders from local storage: $e');
      return [];
    }
  }

  // Clear cache (có thể dùng khi cần force refresh)
  static Future<void> clearCache() async {
    try {
      await LocalStorageService.shared.delete(_cachedStylesUrlKey);
      await LocalStorageService.shared.delete(_cachedGroupsUrlKey);
      await LocalStorageService.shared.delete(_cachedStylesKey);
      await LocalStorageService.shared.delete(_cachedGroupsKey);
      await LocalStorageService.shared.delete(_cachedSlidersKey);
      _hasFetchedStylesOnce = false;
      _hasFetchedGroupsOnce = false;
      print('✅ Cleared image styles, groups and sliders cache');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  // Reset fetch flag (dùng khi muốn force fetch lại)
  static void resetFetchFlag() {
    _hasFetchedStylesOnce = false;
    _hasFetchedGroupsOnce = false;
  }

  static String? _getIconForGroupName(String groupName) {
    final name = groupName.toLowerCase().trim();

    // Map các tên group sang icon tương ứng
    if (name.contains('trending')) {
      return 'img_icon_trending';
    } else if (name.contains('dreamy') || name.contains('fantasy')) {
      return 'img_icon_dream_fancy';
    } else if (name.contains('cute')) {
      return 'img_icon_cute';
    } else if (name.contains('life') && name.contains('style')) {
      return 'img_icon_life_style';
    } else if (name.contains('action')) {
      return 'img_icon_action';
    }

    return 'img_icon_life_style';
  }

  static List<ImageStyleModel> _getDefaultStyles() {
    return [
      ImageStyleModel(
        id: 1,
        name: 'Hoodie Pulling',
        description: 'top-down angle, face looking up, cute expression',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Hoodie%20Pulling.png',
        imageAsset: 'assets/image/category_trending/style_hoodie_pulling.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 2,
        name: 'Soft Knit Doll',
        description: 'knitted wool texture, visible yarn fibers',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Soft%20Knit%20Doll.png',
        imageAsset: 'assets/image/category_trending/style_soft_knit_doll.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 3,
        name: 'Zootopia',
        description: 'Nick and Judy, side-by-side framing',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Zootopia.png',
        imageAsset: 'assets/image/category_trending/style_zootopia.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 4,
        name: 'Zootopia Couple',
        description:
            'girl with Judy-style bunny ears (sky blue), boy with Nick-style fox ears (orange)',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Zootopia%20Couple.png',
        imageAsset: 'assets/image/category_trending/style_zootopia_couple.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 5,
        name: 'Winter',
        description: 'falling snow, scarf, cold atmosphere',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Winter.png',
        imageAsset: 'assets/image/category_trending/style_winter.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 6,
        name: 'Figure Anime',
        description: 'anime figure model, box packaging, promotional poster',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Figure%20Anime.png',
        imageAsset: 'assets/image/category_trending/style_figure_anime.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 7,
        name: 'Exhibition',
        description: 'person looking at their own displayed artwork',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Exhibition.png',
        imageAsset: 'assets/image/category_trending/style_exhibition.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 8,
        name: 'Disney Princess',
        description: 'modern fairy-tale princess',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Disney%20Princess.png',
        imageAsset: 'assets/image/category_trending/style_disney_princess.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 9,
        name: 'Anime 3D',
        description: 'cel-shaded 3D, vibrant colors, crisp outlines, depth',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Anime%203D.png',
        imageAsset: 'assets/image/category_trending/style_anime_3d.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 10,
        name: 'Ghibli',
        description: 'hand-drawn anime, soft colors, dreamy lighting',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Ghibli.png',
        imageAsset: 'assets/image/category_dreamy_fantasy/style_ghibli.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 11,
        name: 'Ghibli Winter',
        description:
            'snowy townscape, warm light vs cold tones, cozy atmosphere',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Ghibli%20Winter.png',
        imageAsset:
            'assets/image/category_dreamy_fantasy/style_ghibli_winter.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 12,
        name: 'Ghibli Spring',
        description: 'cherry blossoms, bright pastel colors, gentle sunlight',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Ghibli%20Spring.png',
        imageAsset:
            'assets/image/category_dreamy_fantasy/style_ghibli_spring.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 13,
        name: 'Kyoto Animation',
        description: 'glossy anime style, expressive eyes, vibrant lighting',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Kyoto%20Animation.png',
        imageAsset:
            'assets/image/category_dreamy_fantasy/style_kyoto_animation.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 14,
        name: 'Shoujo',
        description: 'delicate lines, sparkly eyes, romantic mood',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Shoujo.png',
        imageAsset: 'assets/image/category_dreamy_fantasy/style_shoujo.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 15,
        name: 'Webtoon Look',
        description: 'clean outlines, soft shading, modern casual fashion',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Webtoon%20Look.png',
        imageAsset:
            'assets/image/category_dreamy_fantasy/style_webtoon_look.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 16,
        name: 'Pastel Art',
        description: 'pastel palette, low contrast, soft textures',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Pastel%20Art.png',
        imageAsset: 'assets/image/category_dreamy_fantasy/style_pastel_art.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 17,
        name: 'Water Color Art',
        description: 'watercolor wash, paper texture, loose edges',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Water%20Color%20Art.png',
        imageAsset:
            'assets/image/category_dreamy_fantasy/style_water_color_art.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 18,
        name: 'Mystical',
        description: 'fantasy glow, magical particles, ethereal atmosphere',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Mystical.png',
        imageAsset: 'assets/image/category_dreamy_fantasy/style_mystical.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 19,
        name: 'Sakura Bloom',
        description: 'cherry blossom petals, spring breeze',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Sakura%20Bloom.png',
        imageAsset:
            'assets/image/category_dreamy_fantasy/style_sakura_bloom.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 20,
        name: 'Idol Pop',
        description: 'stage lighting, colorful spotlight',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Idol%20Pop.png',
        imageAsset: 'assets/image/category_dreamy_fantasy/style_idol_pop.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 21,
        name: 'Kawaii',
        description: 'cute proportions, pastel colors, playful expression',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Kawaii.png',
        imageAsset: 'assets/image/category_cute/style_kawaii.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 22,
        name: 'Chibi',
        description:
            'super-deformed proportions, big head small body, cute pose',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Chibi.png',
        imageAsset: 'assets/image/category_cute/style_chibi.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 23,
        name: 'Kemonomimi',
        description: 'cat ears, soft fur accents, anime character',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Kemonomimi.png',
        imageAsset: 'assets/image/category_cute/style_kemonomimi.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 24,
        name: 'Fox Girl',
        description: 'fox ears, fluffy tail, sly expression',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Fox%20Girl.png',
        imageAsset: 'assets/image/category_cute/style_fox_girl.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 25,
        name: 'Kitsune Spirit',
        description:
            'mystical fox spirit, 9 tails, glowing aura, traditional folklore',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Kitsune%20Spirit.png',
        imageAsset: 'assets/image/category_cute/style_kitsune_spirit.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 26,
        name: 'Bunny Muse',
        description: 'bunny ears, charming pose',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Bunny%20Muse.png',
        imageAsset: 'assets/image/category_cute/style_bunny_muse.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 27,
        name: 'Y2K Glow',
        description: 'glossy highlights, neon pastels, early 2000s pop',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Y2K%20Glow.png',
        imageAsset: 'assets/image/category_cute/style_y2k_glow.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 28,
        name: 'Lofi',
        description: 'warm tones, grain texture, casual mood',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Lofi.png',
        imageAsset: 'assets/image/category_life_style/style_lofi.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 29,
        name: 'Ghibli Lovers',
        description: 'romantic scene, soft colors, dreamy lighting',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Ghibli%20Lovers.png',
        imageAsset: 'assets/image/category_life_style/style_ghibli_lovers.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 30,
        name: 'Youth Romance',
        description: 'soft emotions, gentle lighting, tender atmosphere',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Youth%20Romance.png',
        imageAsset: 'assets/image/category_life_style/style_youth_romance.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 31,
        name: 'Soft Life',
        description: 'cozy lifestyle, calm mood, pastel palette',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Soft%20Life.png',
        imageAsset: 'assets/image/category_life_style/style_soft_life.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 32,
        name: 'High School',
        description: 'school uniform, campus setting, youthful vibe',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/High%20School.png',
        imageAsset: 'assets/image/category_life_style/style_high_school.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 33,
        name: 'Cozy Life',
        description: 'warm interior, blankets & tea, relaxed atmosphere',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Cozy%20Life.png',
        imageAsset: 'assets/image/category_life_style/style_cozy_life.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 34,
        name: 'Shounen Action',
        description: 'dynamic motion, dramatic lighting, power effects',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Shounen%20Action.png',
        imageAsset: 'assets/image/category_action/style_shounen_action.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 35,
        name: 'Naruto',
        description: 'ninja outfit, headband, chakra energy',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Naruto.png',
        imageAsset: 'assets/image/category_action/style_naruto.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 36,
        name: 'Luffy',
        description: 'straw hat, carefree expression, adventure vibe',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Luffy.png',
        imageAsset: 'assets/image/category_action/style_luffy.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 37,
        name: 'Ninja',
        description: 'stealth outfit, fast movement, shadow action',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Ninja.png',
        imageAsset: 'assets/image/category_action/style_ninja.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 38,
        name: 'Hero',
        description: 'confident pose, dramatic lighting, heroic stance',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Hero.png',
        imageAsset: 'assets/image/category_action/style_hero.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 39,
        name: 'Cool Guy',
        description: 'aloof expression, stylish outfit, relaxed confidence',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Cool%20Guy.png',
        imageAsset: 'assets/image/category_action/style_cool_guy.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 40,
        name: 'Secret Agent',
        description: 'suit & tie, covert mission, stealth tension',
        imageUrl:
            'https://cdn.zi003.imgly.store/style-update/Secret%20Agent.png',
        imageAsset: 'assets/image/category_action/style_secret_agent.png',
        isSelected: false,
      ),
      ImageStyleModel(
        id: 41,
        name: 'Cyberpunk',
        description: 'neon lights, futuristic city, tech augmentation',
        imageUrl: 'https://cdn.zi003.imgly.store/style-update/Cyberpunk.png',
        imageAsset: 'assets/image/category_action/style_cyberpunk.png',
        isSelected: false,
      ),
    ];
  }

  // ========== Methods cho Style Groups ==========

  // Method SYNC - load groups từ local storage
  static List<ImageStyleGroupModel> getImageStyleGroups() {
    // Thử load từ local storage trước
    final cachedGroups = _loadStyleGroupsFromLocal();
    if (cachedGroups.isNotEmpty) {
      return cachedGroups;
    }

    // Nếu chưa có cache, trả về default
    return _getDefaultStyleGroups();
  }

  // ========== API 2: Fetch Categories & Sliders (ĐỘC LẬP) ==========
  // Gọi image_style_groups_cloudfare → parse {"categories": [...], "sliders": [...]}
  // Có thể gọi riêng: unawaited(HomeDataSource.fetchImageStyleGroups())
  // Không phụ thuộc vào API 1, tự quản lý cache riêng
  static Future<List<ImageStyleGroupModel>> fetchImageStyleGroups() async {
    // Tránh fetch nhiều lần đồng thời
    if (_isFetchingGroups) {
      return _loadStyleGroupsFromLocal().isNotEmpty
          ? _loadStyleGroupsFromLocal()
          : _getDefaultStyleGroups();
    }

    // Kiểm tra mạng
    if (!ConnectivityService.shared.isConnected) {
      final cached = _loadStyleGroupsFromLocal();
      return cached.isNotEmpty ? cached : _getDefaultStyleGroups();
    }

    // Lấy URL từ Remote Config
    final rawGroupsUrl =
        RemoteConfigService.shared.configRx['image_style_groups_cloudfare'];
    if (rawGroupsUrl == null || rawGroupsUrl.toString().isEmpty) {
      return _getDefaultStyleGroups();
    }

    final currentUrl = rawGroupsUrl.toString();
    final savedUrl =
        LocalStorageService.shared.get<String>(_cachedGroupsUrlKey);

    // Check cache: nếu URL không đổi và đã fetch → dùng cache
    if (_hasFetchedGroupsOnce && savedUrl == currentUrl) {
      final cached = _loadStyleGroupsFromLocal();
      if (cached.isNotEmpty) {
        print('✅ Using cached categories: ${cached.length}');
        return cached;
      }
    }

    // Fetch từ API
    _isFetchingGroups = true;
    try {
      print('📥 Fetching categories & sliders from: $currentUrl');
      final dio = Dio();
      final response = await dio.get(
        currentUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final jsonString =
            response.data is String ? response.data : jsonEncode(response.data);

        // Parse categories
        final categories = _parseStyleGroupsFromJson(jsonString);

        // Parse sliders
        final sliders = _parseSlidersFromJson(jsonString);
        if (sliders.isNotEmpty) {
          await _saveSlidersToLocal(sliders);
        }

        if (categories.isNotEmpty) {
          await _saveStyleGroupsToLocal(currentUrl, categories);
          _hasFetchedGroupsOnce = true;
          print(
              '✅ Fetched and cached ${categories.length} categories, ${sliders.length} sliders');
          return categories;
        } else {
          print(
              '⚠️ No valid categories found after parsing, using default groups');
        }
      }
    } catch (e) {
      print('❌ Error fetching categories & sliders: $e');
      final cached = _loadStyleGroupsFromLocal();
      if (cached.isNotEmpty) return cached;
    } finally {
      _isFetchingGroups = false;
    }

    return _getDefaultStyleGroups();
  }

  // Parse JSON groups
  // Parse categories với styleIds và map với styles thực tế
  static List<ImageStyleGroupModel> _parseStyleGroupsFromJson(
      String jsonString) {
    try {
      // Validate JSON string trước khi parse
      jsonString = jsonString.trim();
      if (jsonString.isEmpty) {
        print('❌ Empty JSON string in _parseStyleGroupsFromJson');
        return [];
      }

      // Kiểm tra xem có phải JSON hợp lệ không
      if (!jsonString.startsWith('{') && !jsonString.startsWith('[')) {
        print('❌ Invalid JSON format: does not start with { or [');
        print(
            'First 100 chars: ${jsonString.length > 100 ? jsonString.substring(0, 100) : jsonString}');
        return [];
      }

      print('📄 Decoding JSON for categories, length: ${jsonString.length}');
      final decoded = jsonDecode(jsonString);

      // Lấy tất cả styles có sẵn để map với styleIds
      final allStyles = getImageStyles();
      print('📋 Available styles count: ${allStyles.length}');

      // Hỗ trợ format mới với categories
      if (decoded is Map) {
        print('📋 JSON is Map, keys: ${decoded.keys.toList()}');
        print('📋 Has categories key: ${decoded.containsKey('categories')}');

        if (decoded['categories'] != null) {
          final categoriesList = decoded['categories'] as List<dynamic>;
          print(
              '✅ Parsing categories from JSON, count: ${categoriesList.length}');

          final result = categoriesList
              .map((item) {
                try {
                  if (item is! Map<String, dynamic>) {
                    print(
                        '⚠️ Skipping invalid category (not a Map): ${item.runtimeType}');
                    return null;
                  }

                  final categoryMap = Map<String, dynamic>.from(item);
                  final categoryName = categoryMap['name']?.toString() ?? '';
                  final categoryId = categoryMap['id'] is int
                      ? categoryMap['id'] as int
                      : int.tryParse(categoryMap['id'].toString()) ?? 0;

                  // Parse styleIds và map với styles thực tế
                  List<ImageStyleModel> mappedStyles = [];
                  if (categoryMap['styleIds'] != null) {
                    try {
                      final styleIdsRaw = categoryMap['styleIds'];
                      List<int> styleIds = [];

                      if (styleIdsRaw is List) {
                        styleIds = styleIdsRaw
                            .map((id) {
                              if (id is int) return id;
                              if (id is String) return int.tryParse(id) ?? 0;
                              return int.tryParse(id.toString()) ?? 0;
                            })
                            .where((id) => id > 0)
                            .toList();
                      }

                      print(
                          '📋 Category "$categoryName" has ${styleIds.length} styleIds: $styleIds');

                      // Map styleIds với styles thực tế
                      mappedStyles = styleIds
                          .map((styleId) {
                            final style = allStyles.firstWhere(
                              (style) => style.id == styleId,
                              orElse: () => ImageStyleModel(
                                id: styleId,
                                name: 'Unknown',
                                description: '',
                              ),
                            );

                            // Nếu style không hợp lệ thì return null (sẽ filter sau)
                            if (style.id <= 0 || style.name == 'Unknown') {
                              return null;
                            }

                            // Nếu style đã có imageAsset rồi thì giữ nguyên
                            if (style.imageAsset != null &&
                                style.imageAsset!.isNotEmpty) {
                              return style;
                            }

                            // Nếu chưa có imageAsset, map từ service
                            final mappingService =
                                StyleAssetMappingService.shared;
                            final mappedAsset =
                                mappingService.getStyleAssetPath(
                              style.name,
                              categoryName,
                            );

                            // Tạo style mới với imageAsset đã map (có thể null nếu không map được)
                            return ImageStyleModel(
                              id: style.id,
                              name: style.name,
                              description: style.description,
                              imageUrl: style.imageUrl,
                              imageAsset: mappedAsset, // Có thể null
                              isSelected: style.isSelected,
                            );
                          })
                          .whereType<ImageStyleModel>() // Filter null values
                          .where((style) =>
                              style.id > 0 && style.name != 'Unknown')
                          .toList();

                      print(
                          '✅ Category "$categoryName" mapped ${mappedStyles.length} styles from ${styleIds.length} styleIds');
                    } catch (e) {
                      print(
                          '⚠️ Error parsing styleIds for category $categoryName: $e');
                    }
                  }

                  // Chỉ trả về group nếu có styles
                  if (mappedStyles.isEmpty) {
                    print(
                        '⚠️ Category "$categoryName" has no valid styles, skipping');
                    return null;
                  }

                  return ImageStyleGroupModel(
                    id: categoryId,
                    name: categoryName,
                    icon: categoryMap['icon']?.toString(),
                    styles: mappedStyles,
                  );
                } catch (e, stackTrace) {
                  print('❌ Error parsing category item: $e');
                  print('Stack trace: $stackTrace');
                  print('Item: $item');
                  return null;
                }
              })
              .whereType<ImageStyleGroupModel>()
              .toList();

          print(
              '✅ Parsed ${result.length} categories successfully (filtered out empty groups)');
          return result;
        } else {
          print('⚠️ categories key is null or empty');
        }
      } else {
        print('⚠️ JSON is not a Map, type: ${decoded.runtimeType}');
      }

      // Fallback: format cũ với groups (backward compatible)
      if (decoded is Map && decoded['groups'] != null) {
        print('✅ Parsing groups from JSON (old format)');
        final groupsList = decoded['groups'] as List<dynamic>;
        return groupsList
            .map((item) {
              try {
                return ImageStyleGroupModel.fromJson(
                  item as Map<String, dynamic>,
                  allStyles: null, // Không map styles
                );
              } catch (e) {
                print('❌ Error parsing group item: $e');
                return null;
              }
            })
            .whereType<ImageStyleGroupModel>()
            .toList();
      }

      // Fallback: format cũ (array of styles)
      if (decoded is List) {
        print('✅ Parsing styles array (old format)');
        final styles = _parseStylesFromJson(jsonString);
        return [
          ImageStyleGroupModel(
            id: 1,
            name: 'All',
            styles: styles,
          ),
        ];
      }

      print('⚠️ No valid format found in JSON');
      return [];
    } catch (e, stackTrace) {
      print('❌ Error in _parseStyleGroupsFromJson: $e');
      print('Stack trace: $stackTrace');
      if (e is FormatException) {
        print('FormatException details: ${e.message}');
        print('Source: ${e.source}');
        print('Offset: ${e.offset}');
        // Log context around error
        if (e.offset != null && jsonString.length > e.offset!) {
          final start = (e.offset! - 50).clamp(0, jsonString.length);
          final end = (e.offset! + 50).clamp(0, jsonString.length);
          print(
              'Context around error (offset ${e.offset}): ${jsonString.substring(start, end)}');
        }
      }
      print('Stack trace: $stackTrace');
      print('JSON length: ${jsonString.length}');
      print(
          'JSON preview (first 500 chars): ${jsonString.length > 500 ? jsonString.substring(0, 500) : jsonString}');
      return [];
    }
  }

  // Lưu groups vào local storage
  static Future<void> _saveStyleGroupsToLocal(
    String url,
    List<ImageStyleGroupModel> groups,
  ) async {
    try {
      // Lưu URL
      await LocalStorageService.shared.put(_cachedGroupsUrlKey, url);

      // Convert groups sang JSON để lưu
      final groupsJson = groups
          .map((group) => {
                'id': group.id,
                'name': group.name,
                'icon': group.icon,
                'styles': group.styles
                    .map((style) => {
                          'id': style.id,
                          'name': style.name,
                          'description': style.description,
                          'imageUrl': style.imageUrl,
                          'imageAsset': style.imageAsset,
                          'isSelected': style.isSelected,
                        })
                    .toList(),
              })
          .toList();

      await LocalStorageService.shared.put(_cachedGroupsKey, groupsJson);
      print('✅ Saved image style groups to local storage');
    } catch (e) {
      print('Error saving style groups to local storage: $e');
    }
  }

  // Load groups từ local storage
  static List<ImageStyleGroupModel> _loadStyleGroupsFromLocal() {
    try {
      final groupsJson =
          LocalStorageService.shared.get<List<dynamic>>(_cachedGroupsKey);

      if (groupsJson == null || groupsJson.isEmpty) {
        return [];
      }

      return groupsJson.map((json) {
        final map = Map<String, dynamic>.from(json as Map);
        final groupName = map['name']?.toString() ?? '';
        final iconFromStorage = map['icon']?.toString();
        return ImageStyleGroupModel(
          id: map['id'] is int
              ? map['id']
              : int.tryParse(map['id'].toString()) ?? 0,
          name: map['name']?.toString() ?? '',
          icon: (iconFromStorage?.isNotEmpty == true)
              ? iconFromStorage
              : _getIconForGroupName(groupName),
          styles: (map['styles'] as List<dynamic>?)?.map((item) {
                final styleMap = Map<String, dynamic>.from(item as Map);
                return ImageStyleModel(
                  id: styleMap['id'] is int
                      ? styleMap['id']
                      : int.tryParse(styleMap['id'].toString()) ?? 0,
                  name: styleMap['name']?.toString() ?? '',
                  description: styleMap['description']?.toString() ?? '',
                  imageUrl: styleMap['imageUrl']?.toString(),
                  imageAsset: styleMap['imageAsset']?.toString(),
                  isSelected: styleMap['isSelected'] == true,
                );
              }).toList() ??
              [],
        );
      }).toList();
    } catch (e) {
      print('Error loading style groups from local storage: $e');
      return [];
    }
  }

  // Default style groups
  static List<ImageStyleGroupModel> _getDefaultStyleGroups() {
    final defaultStyles = _getDefaultStyles();

    // Trending
    final trendingStyles = [
      if (defaultStyles.length > 0) defaultStyles[0], // Kawaii
      if (defaultStyles.length > 1) defaultStyles[1], // Chibi
      if (defaultStyles.length > 2) defaultStyles[2], // Shoujo
      if (defaultStyles.length > 3) defaultStyles[3], // Shounen Action
      if (defaultStyles.length > 4) defaultStyles[4], // Isekai Fantasy
      if (defaultStyles.length > 5) defaultStyles[5], // Cyberpunk
      if (defaultStyles.length > 6) defaultStyles[6], // Soft Life
      if (defaultStyles.length > 7) defaultStyles[7], // Gothic
      if (defaultStyles.length > 8) defaultStyles[8], // Moe Idol
    ];

    // Dreamy Fantasy
    final dreamyFantasyStyles = [
      if (defaultStyles.length > 17) defaultStyles[17], // Ghibli Studio
      if (defaultStyles.length > 2) defaultStyles[2], // Shoujo
      if (defaultStyles.length > 11) defaultStyles[11], // Mystical
      if (defaultStyles.length > 15) defaultStyles[15], // Webtoon Style
      if (defaultStyles.length > 0) defaultStyles[0], // Kawaii
      if (defaultStyles.length > 1) defaultStyles[1], // Chibi
      if (defaultStyles.length > 6) defaultStyles[6], // Soft Life
      if (defaultStyles.length > 8) defaultStyles[8], // Moe Idol
      if (defaultStyles.length > 13) defaultStyles[13], // Mahou Shoujo
      if (defaultStyles.length > 14) defaultStyles[14], // Kemonomimi
      if (defaultStyles.length > 19) defaultStyles[19], // Kyoto Animation
    ];

    // Cute
    final cuteStyles = [
      if (defaultStyles.length > 0) defaultStyles[0], // Kawaii
      if (defaultStyles.length > 1) defaultStyles[1], // Chibi
      if (defaultStyles.length > 8) defaultStyles[8], // Moe Idol
      if (defaultStyles.length > 14) defaultStyles[14], // Kemonomimi
      if (defaultStyles.length > 13) defaultStyles[13], // Mahou Shoujo
      if (defaultStyles.length > 6) defaultStyles[6], // Soft Life
      if (defaultStyles.length > 2) defaultStyles[2], // Shoujo
      if (defaultStyles.length > 16) defaultStyles[16], // Trendy Fashion
      if (defaultStyles.length > 0)
        defaultStyles[0], // Kawaii (duplicate for demo)
    ];

    // Life style
    final lifestyleStyles = [
      if (defaultStyles.length > 6) defaultStyles[6], // Soft Life
      if (defaultStyles.length > 17) defaultStyles[17], // Ghibli Studio
      if (defaultStyles.length > 16) defaultStyles[16], // Trendy Fashion
      if (defaultStyles.length > 10) defaultStyles[10], // Vintage
      if (defaultStyles.length > 0) defaultStyles[0], // Kawaii
      if (defaultStyles.length > 1) defaultStyles[1], // Chibi
      if (defaultStyles.length > 2) defaultStyles[2], // Shoujo
      if (defaultStyles.length > 15) defaultStyles[15], // Webtoon Style
      if (defaultStyles.length > 19) defaultStyles[19], // Kyoto Animation
    ];

    // Action
    final actionStyles = [
      if (defaultStyles.length > 3) defaultStyles[3], // Shounen Action
      if (defaultStyles.length > 5) defaultStyles[5], // Cyberpunk
      if (defaultStyles.length > 12) defaultStyles[12], // Sports
      if (defaultStyles.length > 4) defaultStyles[4], // Isekai Fantasy
      if (defaultStyles.length > 7) defaultStyles[7], // Gothic
      if (defaultStyles.length > 11) defaultStyles[11], // Synthwave
      if (defaultStyles.length > 18) defaultStyles[18], // Makoto Shinkai
      if (defaultStyles.length > 3)
        defaultStyles[3], // Shounen Action (duplicate)
    ];

    return [
      ImageStyleGroupModel(
        id: 1,
        name: 'Trending',
        icon: 'img_icon_trending',
        styles: trendingStyles,
      ),
      ImageStyleGroupModel(
        id: 2,
        name: 'Dreamy Fantasy',
        icon: 'img_icon_dream_fancy',
        styles: dreamyFantasyStyles,
      ),
      ImageStyleGroupModel(
        id: 3,
        name: 'Cute',
        icon: 'img_icon_cute',
        styles: cuteStyles,
      ),
      ImageStyleGroupModel(
        id: 4,
        name: 'Life style',
        icon: 'img_icon_life_style',
        styles: lifestyleStyles,
      ),
      ImageStyleGroupModel(
        id: 5,
        name: 'Action',
        icon: 'img_icon_action',
        styles: actionStyles,
      ),
    ];
  }
}
