import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/export_constants.dart';
import 'package:flutter_quick_base/core/widgets/app_icon.dart';
import 'package:flutter_quick_base/core/widgets/cached_image_widget.dart';

class ScannerLineImageWidget extends StatefulWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Color scannerColor;
  final double? lineHeight;
  final Duration duration;
  final Duration transitionDuration;
  final double? scannerOverflow;
  final BorderRadius? borderRadius;
  final double overlayOpacity;
  final double? cornerLength;
  final double? cornerWidth;

  const ScannerLineImageWidget({
    super.key,
    this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.scannerColor = AppColors.colorFF00AE,
    this.lineHeight,
    this.duration = const Duration(seconds: 3),
    this.transitionDuration = const Duration(milliseconds: 150),
    this.scannerOverflow,
    this.borderRadius,
    this.overlayOpacity = 0.3,
    this.cornerLength = 20.0,
    this.cornerWidth = 2.0,
  });

  @override
  State<ScannerLineImageWidget> createState() => _ScannerLineImageWidgetState();
}

class _ScannerLineImageWidgetState extends State<ScannerLineImageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isMovingDown = true;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.linear,
      ),
    );
    // //TODO: repeat animation forever down
    // _controller.repeat();

    //TODO: repeat animation  down and up
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isVisible = false;
        });
        Future.delayed(widget.transitionDuration, () {
          if (mounted) {
            setState(() {
              _isMovingDown = !_isMovingDown;
              _isVisible = true;
            });
            _controller.reset();
            _controller.forward();
          }
        });
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.imagePath ?? 'assets/icons/image_home_bg.jpg';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = widget.width ?? constraints.maxWidth;
        final height = widget.height ?? constraints.maxHeight;

        final actualHeight = height > 0 ? height : 200.0;
        final actualWidth = width > 0 ? width : constraints.maxWidth;

        final scannerOverflow = widget.scannerOverflow ?? (actualHeight * 0.03);
        final lineHeight =
            widget.lineHeight ?? (actualHeight * 0.01).clamp(1.0, 4.0);
        final imageSize = actualHeight;

        return SizedBox(
          width: actualWidth + scannerOverflow * 2,
          height: actualHeight + scannerOverflow * 2,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: scannerOverflow,
                left: scannerOverflow,
                right: scannerOverflow,
                bottom: scannerOverflow,
                child: ClipRRect(
                  borderRadius: widget.borderRadius ?? BorderRadius.zero,
                  child: Stack(
                    children: [
                      _buildImage(imagePath, actualWidth, actualHeight),

                      if (_isVisible)
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            final positionInImage = _isMovingDown
                                ? (_animation.value * imageSize)
                                : ((1.0 - _animation.value) * imageSize);
                            final scannedHeight = _isMovingDown
                                ? positionInImage
                                : (imageSize - positionInImage);

                            final overlayTop =
                                _isMovingDown ? 0.0 : positionInImage;

                            BorderRadius? overlayBorderRadius;
                            if (widget.borderRadius != null) {
                              final isAtTop = overlayTop < 1.0;
                              final isAtBottom = (overlayTop + scannedHeight) >=
                                  (imageSize - 1.0);
                              final isFullHeight =
                                  scannedHeight >= imageSize - 1.0;

                              if (isFullHeight) {
                                overlayBorderRadius = widget.borderRadius;
                              } else if (isAtTop && !isAtBottom) {
                                overlayBorderRadius = BorderRadius.only(
                                  topLeft: widget.borderRadius!.topLeft,
                                  topRight: widget.borderRadius!.topRight,
                                );
                              } else if (isAtBottom && !isAtTop) {
                                overlayBorderRadius = BorderRadius.only(
                                  bottomLeft: widget.borderRadius!.bottomLeft,
                                  bottomRight: widget.borderRadius!.bottomRight,
                                );
                              } else {
                                overlayBorderRadius = BorderRadius.zero;
                              }
                            }
                            return Positioned(
                              top: overlayTop,
                              left: 0,
                              right: 0,
                              height: scannedHeight.clamp(0.0, imageSize),
                              child: ClipRRect(
                                borderRadius:
                                    overlayBorderRadius ?? BorderRadius.zero,
                                clipBehavior: Clip.antiAlias,
                                child: Container(
                                  width: actualWidth,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      stops: const [0.0, 0.6, 1.0],
                                      colors: [
                                        widget.scannerColor.withOpacity(0.1),
                                        widget.scannerColor.withOpacity(
                                            widget.overlayOpacity * 0.6),
                                        widget.scannerColor
                                            .withOpacity(widget.overlayOpacity),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      // Corner brackets (L-shaped) ở 4 góc
                      // Top-left
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          width: widget.cornerLength,
                          height: widget.cornerLength,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(5)),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white,
                                width: widget.cornerWidth ?? 2.0,
                              ),
                              left: BorderSide(
                                color: Colors.white,
                                width: widget.cornerWidth ?? 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Top-right
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          width: widget.cornerLength,
                          height: widget.cornerLength,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(5)),
                            border: Border(
                              top: BorderSide(
                                color: Colors.white,
                                width: widget.cornerWidth ?? 2.0,
                              ),
                              right: BorderSide(
                                color: Colors.white,
                                width: widget.cornerWidth ?? 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom-left
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Container(
                          width: widget.cornerLength,
                          height: widget.cornerLength,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(5)),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white,
                                width: widget.cornerWidth ?? 2.0,
                              ),
                              left: BorderSide(
                                color: Colors.white,
                                width: widget.cornerWidth ?? 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Bottom-right
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          width: widget.cornerLength,
                          height: widget.cornerLength,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                                bottomRight: Radius.circular(5)),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.white,
                                width: widget.cornerWidth ?? 2.0,
                              ),
                              right: BorderSide(
                                color: Colors.white,
                                width: widget.cornerWidth ?? 2.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isVisible)
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    final position = _isMovingDown
                        ? scannerOverflow + (_animation.value * imageSize)
                        : scannerOverflow +
                            ((1.0 - _animation.value) * imageSize);
                    return Positioned(
                      top: position,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: lineHeight,
                        color: widget.scannerColor,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImage(String imagePath, double width, double height) {
    Widget imageWidget;

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Network image
      imageWidget = CachedImageWidget(
        imagePath: imagePath,
        width: width,
        height: height,
        fit: widget.fit,
      );
    } else if (imagePath.startsWith('assets/')) {
      // Asset image
      imageWidget = Image.asset(
        imagePath,
        width: width,
        height: height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) =>
            _buildDefaultImage(width, height),
      );
    } else {
      if (imagePath.isEmpty) {
        return _buildDefaultImage(width, height);
      }
      imageWidget = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
        child: Opacity(
          opacity: 0.8,
          child: CachedImageWidget(
            imagePath: imagePath,
            width: width,
            height: height,
            fit: widget.fit,
          ),
        ),
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultImage(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.color29171E,
        // border: Border.all(
        //   color: AppColors.color595959,
        // ),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.colorB0A6FA,
            AppColors.colorEAE7FE,
          ],
        ),
        borderRadius: widget.borderRadius ?? BorderRadius.zero,
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgIcon(name: 'ic_image_scanner'),
          ],
        ),
      ),
    );
  }
}
