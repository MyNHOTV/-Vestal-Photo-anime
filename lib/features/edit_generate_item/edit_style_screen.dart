import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/analytics_service.dart';
import 'package:flutter_quick_base/core/widgets/app_button.dart';
import 'package:flutter_quick_base/core/widgets/export_widgets.dart';
import 'package:flutter_quick_base/core/widgets/grid_background.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/controllers/image_generation_controller.dart';
import 'package:flutter_quick_base/features/image_generation/presentation/widget_new/generation_style_grid_widget.dart';
import 'package:get/get.dart';
import '../../../../core/constants/export_constants.dart';

class EditStyleScreen extends StatefulWidget {
  const EditStyleScreen({super.key});

  @override
  State<EditStyleScreen> createState() => _EditStyleScreenState();
}

class _EditStyleScreenState extends State<EditStyleScreen> {
  final ImageGenerationController controller =
      Get.find<ImageGenerationController>();
  int? _initialStyleId;
  int? _selectedStyleId;

  @override
  void initState() {
    super.initState();
    _initialStyleId = controller.selectedStyle.value?.id;
    _selectedStyleId = _initialStyleId;
  }

  bool get _hasChanged => _initialStyleId != _selectedStyleId;

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
                  title: tr('edit_your_style'),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).size.height / 6,
                    ),
                    child: Obx(() => GenerationStyleGridWidget(
                          styles: controller.imageStyles.value,
                          selectedStyleId: _selectedStyleId,
                          onStyleSelected: (style) {
                            setState(() {
                              _selectedStyleId = style.id;
                            });
                          },
                        )),
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
                        state: _selectedStyleId != null
                            ? StateButton.active
                            : StateButton.disable,
                        onTap: () {
                          if (_hasChanged && _selectedStyleId != null) {
                            AnalyticsService.shared.actionChangeStyle();
                            final style = controller.imageStyles.value
                                .firstWhere((s) => s.id == _selectedStyleId);
                            controller.selectStyle(style);
                          }
                          Get.back();
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
