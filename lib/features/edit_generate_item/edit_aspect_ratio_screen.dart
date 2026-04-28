import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/services/remote_config_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/collapsible_banner_ad_widget.dart';
import 'package:flutter_quick_base/core/widgets/export_widgets.dart';
import 'package:flutter_quick_base/core/widgets/grid_background.dart';
import 'package:flutter_quick_base/features/image_generation/data/datasources/aspect_ratio_data_source.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/widget_new/generation_ratio_grid_widget.dart';
import 'package:get/get.dart';
import '../../../../core/constants/export_constants.dart';

class EditAspectRatioScreen extends StatefulWidget {
  const EditAspectRatioScreen({super.key});

  @override
  State<EditAspectRatioScreen> createState() => _EditAspectRatioScreenState();
}

class _EditAspectRatioScreenState extends State<EditAspectRatioScreen> {
  final ImageGenerationController controller =
      Get.find<ImageGenerationController>();
  String _initialAspectRatio = '';
  String _selectedAspectRatio = '';

  @override
  void initState() {
    super.initState();
    _initialAspectRatio = controller.selectedAspectRatio.value;
    _selectedAspectRatio = _initialAspectRatio;
  }

  bool get _hasChanged => _initialAspectRatio != _selectedAspectRatio;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: false,
      backgroundColor: AppColors.colorBlack,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          const Positioned.fill(
            child: GridBackground(
              child: SizedBox.shrink(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SimpleAppBar(
                  title: tr('edit_your_aspect_ratio'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height / 6,
                      left: AppSizes.spacingM,
                      right: AppSizes.spacingM,
                    ),
                    child: GenerationRatioGridWidget(
                      styles: AspectRatioDataSource.getAspectRatios(),
                      aspectRatio: _selectedAspectRatio,
                      onStyleSelected: (style) {
                        setState(() {
                          _selectedAspectRatio = style.aspectRatio;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 20.0),
                      child: AppPrimaryButton(
                        title: tr('confirm'),
                        state: _hasChanged
                            ? StateButton.active
                            : StateButton.disable,
                        onTap: () {
                          if (_hasChanged) {
                            AnalyticsService.shared.actionChangeRatio();
                            controller.selectAspectRatio(_selectedAspectRatio);
                          }
                          Get.back();
                        },
                      ),
                    ),
                  ),
                ),
                Obx(() {
                  if (!RemoteConfigService.shared.bannerChangeRatioEnabled) {
                    return const SizedBox.shrink();
                  }
                  return const CollapsibleBannerAdWidget(
                    placement: 'banner_change_ratio',
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
