import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/services/dynamic_theme_service.dart';
import '../constants/app_colors.dart';

class AppProgressBar extends StatefulWidget {
  const AppProgressBar({
    super.key,
    required this.progress,
    this.height = 8.0,
    this.backgroundColor,
    this.gradient,
    this.barRadius,
    this.animationDuration = const Duration(milliseconds: 100),
  });

  /// Progress value từ 0.0 đến 1.0
  final double progress;

  /// Chiều cao của progress bar
  final double height;

  /// Màu nền của progress bar
  final Color? backgroundColor;

  /// Gradient cho progress bar (nếu không có sẽ dùng gradient mặc định)
  final LinearGradient? gradient;

  /// Border radius của progress bar
  final Radius? barRadius;

  /// Thời gian animation (nên match với step duration trong controller)
  final Duration animationDuration;

  /// Gradient mặc định của app
  static LinearGradient defaultGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: DynamicThemeService.shared.getSecondaryButtonGradientColors(),
  );

  /// Gradient 5 màu (giống button)
  static const LinearGradient extendedGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.colorA30049,
      AppColors.colorFF18BA,
      AppColors.colorE037B3,
      AppColors.colorAD01C3,
      AppColors.color600088,
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  @override
  State<AppProgressBar> createState() => _AppProgressBarState();
}

class _AppProgressBarState extends State<AppProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _previousProgress = widget.progress;
    if (widget.progress > 0) {
      _controller.value = widget.progress;
    }
  }

  @override
  void didUpdateWidget(AppProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _animation = Tween<double>(
        begin: _previousProgress,
        end: widget.progress.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
      _previousProgress = widget.progress;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finalGradient = widget.gradient ?? AppProgressBar.defaultGradient;
    final finalBackgroundColor = widget.backgroundColor ?? Colors.white;
    final finalBarRadius = widget.barRadius ?? const Radius.circular(4);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: finalBackgroundColor,
            borderRadius: BorderRadius.all(finalBarRadius),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: _animation.value,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: finalGradient,
                    borderRadius: BorderRadius.all(finalBarRadius),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
