import 'package:carousel_slider/carousel_slider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';
import 'package:flutter_quick_base/core/constants/app_fonts.dart';
import 'package:flutter_quick_base/core/routes/app_routes.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/network_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/style_selection_dialog.dart';
import 'package:flutter_quick_base/features/home/data/model/carousel_style_item_model.dart';
import 'package:flutter_quick_base/features/home/presentation/controller/home_controller.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:get/get.dart';

class _HomeHeaderContent extends StatefulWidget {
  final double height;
  final double topHeaderOpacity;
  final double topHeaderOffset;
  final double inputOpacity;
  final double inputScale;
  final double inputBottomOffset;
  final double inputFontSize;
  final double inputButtonWidth;
  final double gradientOpacity;
  final bool showTopHeader;
  final bool showInput;

  const _HomeHeaderContent({
    required this.height,
    this.topHeaderOpacity = 1.0,
    this.topHeaderOffset = 48.0,
    this.inputOpacity = 1.0,
    this.inputScale = 1.0,
    this.inputBottomOffset = 16.0,
    this.inputFontSize = 14.0,
    this.inputButtonWidth = 95.0,
    this.gradientOpacity = 0.7,
    this.showTopHeader = true,
    this.showInput = true,
  });

  @override
  State<_HomeHeaderContent> createState() => _HomeHeaderContentState();
}

class _HomeHeaderContentState extends State<_HomeHeaderContent> {
  final TextEditingController _promptController = TextEditingController();
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  int _currentCarouselIndex = 0;
  final HomeController _homeController = Get.find<HomeController>();

  // Lấy carousel items từ HomeController (bao gồm sliders từ API)
  List<CarouselStyleItemModel> get _carouselItems {
    final sliders = _homeController.sliders.toList();
    // Nếu chưa có sliders từ API, dùng default
    if (sliders.isEmpty) {
      return [
        CarouselStyleItemModel(
          id: 1,
          title: 'AI art',
          image: 'assets/image/slider_1.png',
        ),
        CarouselStyleItemModel(
          id: 2,
          title: 'AI art',
          image: 'assets/image/slider_2.png',
        ),
        CarouselStyleItemModel(
          id: 3,
          title: 'AI art',
          image: 'assets/image/slider_3.png',
        ),
      ];
    }
    return sliders;
  }

  // Tính số lượng items thực tế (bao gồm native ad ở vị trí thứ 2)
  int get _totalCarouselItems {
    final items = _carouselItems.length;
    return items;
  }

  // Kiểm tra xem index có phải là native ad không
  bool _isNativeAdIndex(int index) {
    return false;
  }

  CarouselStyleItemModel? _getCarouselItemAt(int index) {
    // Native ad đã bị disable, chỉ cần trả về item trực tiếp
    if (index >= 0 && index < _carouselItems.length) {
      return _carouselItems[index];
    }
    return null;
  }

  void _onTryNowTap() async {
    final hasNet = await NetworkService.to.checkNetworkForInAppFunction();
    if (!hasNet) return;

    // Bỏ qua nếu đang ở native ad
    if (_isNativeAdIndex(_currentCarouselIndex)) {
      return;
    }

    // Lấy carousel item hiện tại
    final currentItem = _getCarouselItemAt(_currentCarouselIndex);
    if (currentItem == null) {
      return;
    }

    // Query style từ HomeController
    final homeController = Get.find<HomeController>();
    final style = homeController.imageStyles.firstWhereOrNull(
      (style) => style.id == currentItem.id,
    );

    if (style == null) {
      // Nếu không tìm thấy style, có thể show error hoặc return
      return;
    }

    // Show dialog
    if (!mounted) return;

    StyleSelectionDialog.show(
      context: context,
      style: style,
      onCancel: () {
        Navigator.of(context).pop();
      },
      onConfirm: () {
        Navigator.of(context).pop();
        // Set selected style và navigate to generate
        homeController.selectedStyle.value = style;
        final genController = Get.find<ImageGenerationController>();
        genController.selectStyle(style);
        genController.setPreviousRoute('home');
        AnalyticsService.shared.styleClick(style.name);

        Get.toNamed(AppRoutes.uploadImage, arguments: style);
      },
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: widget.height,
      width: double.infinity,
      decoration: const BoxDecoration(
          // borderRadius: BorderRadius.only(
          //   bottomLeft: Radius.circular(40),
          //   bottomRight: Radius.circular(40),
          // ),
          ),
      child: ClipRRect(
        // borderRadius: const BorderRadius.only(
        //   bottomLeft: Radius.circular(40),
        //   bottomRight: Radius.circular(40),
        // ),
        child: Stack(
          children: [
            Container(
              height: MediaQuery.of(context).size.height / 4.5,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icons/image_home_bg_header.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            // Title "AI art" ở trên cùng
            Column(
              children: [
                SafeArea(
                  top: false,
                  bottom: false,
                  child: Stack(
                    children: [
                      // Carousel slider là phần chính
                      CarouselSlider.builder(
                        carouselController: _carouselController,
                        itemCount: _totalCarouselItems,
                        itemBuilder: (context, index, realIndex) {
                          // Carousel item bình thường
                          final item = _getCarouselItemAt(index);
                          if (item == null) {
                            return const SizedBox.shrink();
                          }

                          // Kiểm tra xem image là URL hay asset
                          final isUrl = item.image.startsWith('http://') ||
                              item.image.startsWith('https://');

                          return Stack(
                            children: [
                              // Main background image của carousel
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  // borderRadius: BorderRadius.circular(12),
                                  image: isUrl
                                      ? null
                                      : DecorationImage(
                                          image: AssetImage(item.image),
                                          fit: BoxFit.cover,
                                        ),
                                  color: isUrl ? Colors.grey[200] : null,
                                ),
                                child: isUrl
                                    ? ClipRRect(
                                        child: Image.network(
                                          item.image,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Container(
                                              color: Colors.grey[300],
                                              child: const Center(
                                                child: Icon(Icons.error),
                                              ),
                                            );
                                          },
                                        ),
                                      )
                                    : null,
                              ),
                            ],
                          );
                        },
                        options: CarouselOptions(
                          height: widget.height -
                              MediaQuery.of(context).size.height / 8,
                          viewportFraction: 1.0,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 5),
                          autoPlayAnimationDuration:
                              const Duration(milliseconds: 1000),
                          autoPlayCurve: Curves.fastOutSlowIn,
                          enlargeCenterPage: false,
                          onPageChanged: (index, reason) {
                            setState(() {
                              _currentCarouselIndex = index;
                            });
                          },
                        ),
                      ),
                      if (!_isNativeAdIndex(_currentCarouselIndex))
                        Positioned(
                          bottom: 0,
                          right: 0,
                          left: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.51),
                                  Colors.white
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  width: 64,
                                  height: 6,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final total = _totalCarouselItems == 0
                                          ? 1
                                          : _totalCarouselItems;
                                      final segmentWidth =
                                          constraints.maxWidth / total;
                                      final leftOffset =
                                          segmentWidth * _currentCarouselIndex;

                                      return Stack(
                                        children: [
                                          // Thanh xám cố định
                                          Container(
                                            width: constraints.maxWidth,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(100),
                                              color: AppColors.colorE0E2E5,
                                            ),
                                          ),
                                          // Ô tím di chuyển theo index (độ rộng cố định = 1 segment)
                                          Positioned(
                                            left: leftOffset,
                                            child: Container(
                                              width: segmentWidth,
                                              height: 6,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF796AF7),
                                                    Color(0xFF9B6CF4),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                                AppPrimaryButton(
                                    width: 95,
                                    height: 32,
                                    customContent: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 2,
                                        ),
                                        Flexible(
                                          child: Text(
                                            tr('try_now'),
                                            style: kBricolageBoldStyle.copyWith(
                                                fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 2,
                                        ),
                                        const SvgIcon(name: 'ic_play_sound'),
                                      ],
                                    ),
                                    onTap: _onTryNowTap),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Obx(() => Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: List.generate(
                //         _totalCarouselItems,
                //         (index) => AnimatedSize(
                //           key: ValueKey('dot_$index'),
                //           duration: const Duration(milliseconds: 300),
                //           curve: Curves.easeInOut,
                //           child: Container(
                //             width: _currentCarouselIndex == index ? 16 : 8,
                //             height: 8,
                //             margin: const EdgeInsets.symmetric(horizontal: 4),
                //             decoration: BoxDecoration(
                //               shape: _currentCarouselIndex == index
                //                   ? BoxShape.rectangle
                //                   : BoxShape.circle,
                //               borderRadius: _currentCarouselIndex == index
                //                   ? BorderRadius.circular(4)
                //                   : null,
                //               gradient: _currentCarouselIndex == index
                //                   ? const LinearGradient(
                //                       begin: Alignment.topLeft,
                //                       end: Alignment.bottomRight,
                //                       colors: [
                //                         AppColors.color727885,
                //                         AppColors.color727885,
                //                       ],
                //                     )
                //                   : const LinearGradient(
                //                       begin: Alignment.topLeft,
                //                       end: Alignment.bottomRight,
                //                       colors: [
                //                         AppColors.colorD7DAE1,
                //                         AppColors.colorD7DAE1,
                //                       ],
                //                     ),
                //             ),
                //           ),
                //         ),
                //       ),
                //     )),
              ],
            ),
            // Carousel slider với overlay images - bắt đầu từ dưới title
          ],
        ),
      ),
    );
  }
}

// HomeHeaderWidget sử dụng _HomeHeaderContent với giá trị mặc định
class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({
    super.key,
    this.onTapToGenerate,
    required this.height,
  });

  final VoidCallback? onTapToGenerate;
  final double height;

  @override
  Widget build(BuildContext context) {
    return _HomeHeaderContent(
      height: height,
      showTopHeader: true,
      showInput: false, // Bỏ input field
    );
  }
}

// SliverHomeHeader sử dụng _HomeHeaderContent với animation
class SliverHomeHeader extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;

  SliverHomeHeader({
    required this.minHeight,
    required this.maxHeight,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final progress = (shrinkOffset / maxExtent).clamp(0.0, 1.0);
    final currentHeight =
        (maxExtent - shrinkOffset).clamp(minExtent, maxExtent);

    // Tính toán các giá trị animation
    final topHeaderOpacity = (10 - progress * 1.8).clamp(0.0, 1.0);
    final topHeaderOffset = 48 * (2 - progress * 1.5).clamp(0.0, 1.0);

    final inputOpacity =
        progress < 0.8 ? (1 - progress * 1.5).clamp(0.0, 1.0) : 0.0;
    final inputScale = (10 - progress * 0.4).clamp(0.6, 1.0);
    final inputBottomOffset = 16 + (progress * 1);
    final inputFontSize = 14 * (1 - progress * 0.2).clamp(0.8, 1.0);
    final inputButtonWidth = 95.0;

    final gradientOpacity = 0.7 * (1 - progress * 0.5);
    final showTopHeader = true; // progress < 0.9;
    final showInput = true; // progress < 0.8;

    // Sử dụng _HomeHeaderContent với animation parameters
    return _HomeHeaderContent(
      height: currentHeight,
      topHeaderOpacity: topHeaderOpacity,
      topHeaderOffset: topHeaderOffset,
      inputOpacity: inputOpacity,
      inputScale: inputScale,
      inputBottomOffset: inputBottomOffset,
      inputFontSize: inputFontSize,
      inputButtonWidth: inputButtonWidth,
      gradientOpacity: gradientOpacity,
      showTopHeader: showTopHeader,
      showInput: showInput,
    );
  }

  @override
  bool shouldRebuild(SliverHomeHeader oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight;
  }
}
