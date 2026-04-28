import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../constants/export_constants.dart';
import '../services/dynamic_theme_service.dart';

class GridBackground extends StatefulWidget {
  const GridBackground({super.key, this.child});

  final Widget? child;

  @override
  State<GridBackground> createState() => _GridBackgroundState();
}

class _GridBackgroundState extends State<GridBackground> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox.expand(
        child: DecoratedBox(
          decoration: BoxDecoration(
            image: DecorationImage(
              image:
                  AssetImage(DynamicThemeService.shared.getSplashScreenAsset()),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
