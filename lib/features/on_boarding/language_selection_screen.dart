import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/storage/local_storage_service.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/native_ad_2_floor_wrapper.dart';
import 'package:get/get.dart';

// Model cho ngôn ngữ
class LanguageItem {
  final String code;
  final String name;
  final String? displayNameKey; // Key cho translation (nếu có)
  final String? icon;
  final String? emoji;
  final bool isSystemLanguage;

  const LanguageItem({
    required this.code,
    required this.name,
    this.displayNameKey,
    this.icon,
    this.emoji,
    this.isSystemLanguage = false,
  });

  // Get display name - ưu tiên translation key, sau đó là name
  String getDisplayName(BuildContext context) {
    try {
      if (displayNameKey != null) {
        return tr(displayNameKey!);
      }
      return name;
    } catch (e) {
      // Nếu translation fail, trả về name gốc
      return name;
    }
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedLanguage;
  late AnimationController _animationController;

  // Danh sách ngôn ngữ động
  final List<LanguageItem> _languages = [
    LanguageItem(
      code: 'system',
      name: tr('system_language'),
      displayNameKey: 'system_language',
      icon: 'ic_language_default',
      isSystemLanguage: true,
    ),
    LanguageItem(
      code: 'en',
      name: tr('english'),
      displayNameKey: 'english',
      emoji: '🇺🇸',
    ),
    LanguageItem(
      code: 'vi',
      name: tr('vietnamese'),
      displayNameKey: 'vietnamese',
      emoji: '🇻🇳',
    ),
    LanguageItem(
      code: 'hi',
      name: tr('hindi'),
      displayNameKey: 'hindi',
      emoji: '🇮🇳',
    ),
    LanguageItem(
      code: 'es',
      name: tr('spanish'),
      displayNameKey: 'spanish',
      emoji: '🇪🇸',
    ),
    LanguageItem(
      code: 'fr',
      name: tr('french'),
      displayNameKey: 'french',
      emoji: '🇫🇷',
    ),
    LanguageItem(
      code: 'pt',
      name: tr('portuguese'),
      displayNameKey: 'portuguese',
      emoji: '🇵🇹',
    ),
    LanguageItem(
      code: 'ja',
      name: tr('japanese'),
      displayNameKey: 'japanese',
      emoji: '🇯🇵',
    ),
    LanguageItem(
      code: 'ko',
      name: tr('korean'),
      displayNameKey: 'korean',
      emoji: '🇰🇷',
    ),
    LanguageItem(
      code: 'tr',
      name: tr('turkish'),
      displayNameKey: 'turkish',
      emoji: '🇹🇷',
    ),
    LanguageItem(
      code: 'de',
      name: tr('german'),
      displayNameKey: 'german',
      emoji: '🇩🇪',
    ),
    LanguageItem(
      code: 'hr',
      name: tr('croatian'),
      displayNameKey: 'croatian',
      emoji: '🇭🇷',
    ),
    LanguageItem(
      code: 'hu',
      name: tr('hungarian'),
      displayNameKey: 'hungarian',
      emoji: '🇭🇺',
    ),
    LanguageItem(
      code: 'id',
      name: tr('indonesian'),
      displayNameKey: 'indonesian',
      emoji: '🇮🇩',
    ),
    LanguageItem(
      code: 'it',
      name: tr('italian'),
      displayNameKey: 'italian',
      emoji: '🇮🇹',
    ),
    LanguageItem(
      code: 'ne',
      name: tr('nepali'),
      displayNameKey: 'nepali',
      emoji: '🇳🇵',
    ),
    LanguageItem(
      code: 'th',
      name: tr('thai'),
      displayNameKey: 'thai',
      emoji: '🇹🇭',
    ),
    LanguageItem(
      code: 'uk',
      name: tr('ukrainian'),
      displayNameKey: 'ukrainian',
      emoji: '🇺🇦',
    ),
    LanguageItem(
      code: 'zh',
      name: tr('chinese'),
      displayNameKey: 'chinese',
      emoji: '🇨🇳',
    ),
    LanguageItem(
      code: 'ar',
      name: tr('arabic'),
      displayNameKey: 'arabic',
      emoji: '🇸🇦',
    ),
  ];

  @override
  void initState() {
    super.initState();
    try {
      // Setup animation
      _animationController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );

      // Kiểm tra xem có phải từ onboarding không (từ Get.arguments)
      final args = Get.arguments as Map<String, dynamic>?;
      final isFromOnboarding = args?['isFromOnboarding'] as bool? ?? false;

      // Nếu không phải từ onboarding, load ngôn ngữ hiện tại
      if (!isFromOnboarding) {
        _loadCurrentLanguage();
      } else {
        // Set context cho NetworkService - luôn set languageSelection để không hiện popup mất mạng
        if (Get.isRegistered<NetworkService>()) {
          NetworkService.to.setNetworkContext(NetworkContext.languageSelection);
        }
      }

      AnalyticsService.shared.screenLanguageShow();
    } catch (e) {
      debugPrint('Error in initState: $e');
      // Vẫn tiếp tục, không crash app
    }
  }

  void _loadCurrentLanguage() {
    try {
      // Lấy ngôn ngữ từ storage hoặc từ context.locale
      final savedLanguage =
          LocalStorageService.shared.get<String>('selected_language');

      if (savedLanguage != null) {
        // Nếu có ngôn ngữ đã lưu, dùng nó
        _selectedLanguage = savedLanguage;
      } else {
        // Nếu không có, lấy từ context.locale hiện tại
        final currentLocale = context.locale;
        final currentLanguageCode = currentLocale.languageCode;

        // Kiểm tra xem ngôn ngữ hiện tại có trong danh sách không
        final languageExists =
            _languages.any((lang) => lang.code == currentLanguageCode);
        if (languageExists) {
          _selectedLanguage = currentLanguageCode;
        } else {
          // Kiểm tra xem có phải system language không
          try {
            final deviceLocale = Get.deviceLocale;
            if (deviceLocale != null &&
                deviceLocale.languageCode == currentLanguageCode) {
              _selectedLanguage = 'system';
            } else {
              _selectedLanguage = 'en';
            }
          } catch (e) {
            _selectedLanguage = 'en';
          }
        }
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error loading current language: $e');
      _selectedLanguage = null;
    }
  }

  void _selectLanguage(String languageCode) {
    try {
      _animationController.forward(from: 0);
      setState(() {
        _selectedLanguage = languageCode;
      });
    } catch (e) {
      debugPrint('Error selecting language: $e');
      // Vẫn set selected language dù animation fail
      setState(() {
        _selectedLanguage = languageCode;
      });
    }
  }

  Future<void> _confirmSelection() async {
    final args = Get.arguments as Map<String, dynamic>?;
    final isFromOnboarding = args?['isFromOnboarding'] as bool? ?? false;
    if (!isFromOnboarding) {
      final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
      if (!hasNet) return;
    }
    if (_selectedLanguage == null) return;

    try {
      final languageCode = _selectedLanguage!;

      // Lưu ngôn ngữ với try-catch
      try {
        await LocalStorageService.shared.put('selected_language', languageCode);
      } catch (e) {
        debugPrint('Error saving language to storage: $e');
        // Vẫn tiếp tục dù không lưu được
      }

      Locale newLocale;
      if (languageCode == 'system') {
        try {
          final deviceLocale = Get.deviceLocale;

          if (deviceLocale != null) {
            try {
              final deviceLanguageCode = deviceLocale.languageCode;
              final supportedLocales = context.supportedLocales;
              final matchedLocale = supportedLocales.firstWhere(
                (locale) => locale.languageCode == deviceLanguageCode,
                orElse: () => const Locale('en'),
              );
              newLocale = matchedLocale;
            } catch (e) {
              debugPrint('Error matching device locale: $e');
              newLocale = const Locale('en');
            }
          } else {
            newLocale = const Locale('en');
          }
        } catch (e) {
          debugPrint('Error getting device locale: $e');
          newLocale = const Locale('en');
        }
      } else {
        newLocale = Locale(languageCode);
      }

      try {
        await context.setLocale(newLocale);
        Get.updateLocale(newLocale);
        await Future.delayed(const Duration(milliseconds: 200));
        if (mounted) {
          // Kiểm tra xem có phải từ onboarding không
          final args = Get.arguments as Map<String, dynamic>?;
          final isFromOnboarding = args?['isFromOnboarding'] as bool? ?? false;

          if (isFromOnboarding) {
            Get.offAllNamed(AppRoutes.onboarding);
          } else {
            Get.back();
          }
        }
      } catch (e, stack) {
        debugPrint('Error setting locale: $e');
        debugPrint('Stack trace: $stack');
        try {
          await context.setLocale(const Locale('en'));
          Get.updateLocale(const Locale('en'));
          if (mounted) {
            final args = Get.arguments as Map<String, dynamic>?;
            final isFromOnboarding =
                args?['isFromOnboarding'] as bool? ?? false;

            if (isFromOnboarding) {
              Get.offAllNamed(AppRoutes.onboarding);
            } else {
              Get.back();
            }
          }
        } catch (fallbackError) {
          debugPrint('Error in fallback locale setting: $fallbackError');
          // Cuối cùng, vẫn navigate để không bị kẹt
          if (mounted) {
            try {
              final args = Get.arguments as Map<String, dynamic>?;
              final isFromOnboarding =
                  args?['isFromOnboarding'] as bool? ?? false;

              if (isFromOnboarding) {
                Get.offAllNamed(AppRoutes.onboarding);
              } else {
                Get.back();
              }
            } catch (navError) {
              debugPrint('Error navigating: $navError');
            }
          }
        }
      }

      try {
        AnalyticsService.shared.actionConfirmLanguage();
      } catch (e) {
        debugPrint('Error logging analytics: $e');
        // Không crash nếu analytics fail
      }
    } catch (e, stack) {
      debugPrint('Unexpected error in _confirmSelection: $e');
      debugPrint('Stack trace: $stack');
      if (mounted) {
        try {
          final args = Get.arguments as Map<String, dynamic>?;
          final isFromOnboarding = args?['isFromOnboarding'] as bool? ?? false;

          if (isFromOnboarding) {
            Get.offAllNamed(AppRoutes.onboarding);
          } else {
            Get.back();
          }
        } catch (navError) {
          debugPrint('Error in final navigation: $navError');
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = Get.arguments as Map<String, dynamic>?;
    final isFromOnboarding = args?['isFromOnboarding'] as bool? ?? false;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
        if (!hasNet) return;

        if (isFromOnboarding) {
          // Exit app or do nothing if it's first screen relative to onboarding
          return;
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Stack(
          children: [
            // const Positioned.fill(
            //   child: GridBackground(
            //     child: SizedBox.shrink(),
            //   ),
            // ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.only(
                        top: AppSizes.spacingL,
                        left: AppSizes.spacingM,
                        right: AppSizes.spacingM),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (!isFromOnboarding)
                              GestureDetector(
                                onTap: () async {
                                  final hasNet = await NetworkService.to
                                      .checkNetworkForInAppFunction();
                                  if (!hasNet) return;
                                  Get.back();
                                },
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 12.0),
                                  child: SvgIcon(
                                    name: 'ic_arrow_left',
                                    width: 24,
                                    height: 24,
                                    color: AppColors.color121212,
                                  ),
                                ),
                              ),
                            Text(
                              tr('choose_language'),
                              style: kBricolageBoldStyle.copyWith(
                                  fontSize: 18, color: AppColors.color121212),
                            ),
                          ],
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _selectedLanguage != null
                              ? GestureDetector(
                                  onTap: _confirmSelection,
                                  child: Container(
                                    color: Colors.transparent,
                                    padding: const EdgeInsets.only(
                                        left: 16.0, right: 8.0, top: 8),
                                    child: SvgIcon(
                                      name: 'ic_check',
                                      height: 16,
                                      color: AppColors.color400FA7,
                                    ),
                                  ),
                                )
                              : const SizedBox(
                                  key: ValueKey('empty'),
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacingM),
                  // Language list
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.only(
                        left: AppSizes.spacingM,
                        right: AppSizes.spacingM,
                        bottom: MediaQuery.of(context).size.height / 7,
                      ),
                      itemCount: _languages.length,
                      itemBuilder: (context, index) {
                        final language = _languages[index];
                        return _buildLanguageItem(language);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: Obx(() {
          // Ẩn native ad nếu mất mạng
          if (Get.isRegistered<NetworkService>()) {
            if (!NetworkService.to.isConnected.value) {
              return const SizedBox.shrink();
            }
          }

          if (!RemoteConfigService.shared.adsEnabled) {
            return const SizedBox.shrink();
          }
          return _selectedLanguage != null
              ? NativeAd2FloorWrapper(
                  factoryId: 'native_medium_image_top_2',
                  key: const Key('2f_native_language_select'),
                  primaryUniqueKey: '2f_native_language_select',
                  fallbackUniqueKey: 'native_language_select',
                  enable2Floor: RemoteConfigService
                      .shared.nativeLanguageSelect2FloorEnabled,
                  buttonColor: DynamicThemeService.shared.getActiveColorADS(),
                  // adBackgroundColor:
                  //     DynamicThemeService.shared.getActiveColor(),
                )
              : NativeAd2FloorWrapper(
                  factoryId: 'native_medium_image_top_2',
                  key: const Key('2f_native_language'),
                  primaryUniqueKey: '2f_native_language',
                  fallbackUniqueKey: 'native_language',
                  enable2Floor:
                      RemoteConfigService.shared.nativeLanguage2FloorEnabled,
                  buttonColor: AppColors.colorA9A9A9,
                  // adBackgroundColor:
                  //     DynamicThemeService.shared.getActiveColor(),
                );
        }),
      ),
    );
  }

  Widget _buildLanguageItem(LanguageItem language) {
    final isSelected = _selectedLanguage == language.code;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: AppSizes.spacingS),
      padding: const EdgeInsets.all(AppSizes.spacingM),
      decoration: BoxDecoration(
        color: AppColors.colorF4F5F52,
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        border: Border.all(
          color: isSelected
              ? DynamicThemeService.shared.getActiveColor()
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          try {
            print(language.code);
            _selectLanguage(language.code);
          } catch (e) {
            debugPrint('Error in language item tap: $e');
          }
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusL),
        child: Row(
          children: [
            if (language.icon != null)
              SvgIcon(
                name: language.icon ?? 'ic_language_default',
                color: DynamicThemeService.shared.getPrimaryAccentColor(),
              )
            else if (language.emoji != null)
              Text(language.emoji!, style: const TextStyle(fontSize: 24))
            else
              const SizedBox(width: 24),
            const SizedBox(width: AppSizes.spacingM),
            Expanded(
              child: Text(
                language.getDisplayName(context),
                style: kBricolageBoldStyle.copyWith(
                  color: AppColors.color121212,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return ScaleTransition(
                  scale: animation,
                  child: child,
                );
              },
              child: isSelected
                  ? Icon(
                      Icons.radio_button_checked,
                      key: ValueKey('check_${language.code}'),
                      color: DynamicThemeService.shared.getActiveColor(),
                      size: 24,
                    )
                  : Icon(
                      Icons.radio_button_unchecked,
                      key: ValueKey('uncheck_${language.code}'),
                      color: AppColors.disableColorText,
                      size: 24,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
