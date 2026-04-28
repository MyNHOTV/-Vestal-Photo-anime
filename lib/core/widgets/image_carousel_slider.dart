import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

enum ImageSourceType { url, base64, file, asset }

class CarouselImageItem {
  final String source;
  final ImageSourceType sourceType;
  final String? label;
  final VoidCallback? onTap;

  CarouselImageItem({
    required this.source,
    required this.sourceType,
    this.label,
    this.onTap,
  });
}

enum IndicatorType { dots, line }

class ImageCarouselSlider extends StatefulWidget {
  final List<CarouselImageItem> images;
  final double height;
  final double? width;
  final EdgeInsets? itemPadding;
  final double borderRadius;
  final Function(int index)? onPageChanged;
  final bool showIndicator;
  final IndicatorType indicatorType;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final Duration animationDuration;
  final Widget? placeholderWidget;
  final Widget? errorWidget;
  final BoxFit imageFit;

  const ImageCarouselSlider({
    super.key,
    required this.images,
    this.height = 200,
    this.width,
    this.itemPadding,
    this.borderRadius = 12,
    this.onPageChanged,
    this.showIndicator = true,
    this.indicatorType = IndicatorType.dots,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.animationDuration = const Duration(milliseconds: 800),
    this.placeholderWidget,
    this.errorWidget,
    this.imageFit = BoxFit.cover,
  });

  @override
  State<ImageCarouselSlider> createState() => _ImageCarouselSliderState();
}

class _ImageCarouselSliderState extends State<ImageCarouselSlider> {
  late CarouselSliderController _carouselController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _carouselController = CarouselSliderController();
  }

  Widget _buildImageWidget(CarouselImageItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          color: Colors.grey[200],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: _getImageBySourceType(item),
        ),
      ),
    );
  }

  Widget _getImageBySourceType(CarouselImageItem item) {
    try {
      switch (item.sourceType) {
        case ImageSourceType.url:
          return CachedNetworkImage(
            imageUrl: item.source,
            fit: widget.imageFit,
            placeholder: (context, url) =>
                widget.placeholderWidget ?? _buildPlaceholder(),
            errorWidget: (context, url, error) =>
                widget.errorWidget ?? _buildErrorWidget(),
            maxWidthDiskCache: 2048,
            maxHeightDiskCache: 2048,
          );

        case ImageSourceType.base64:
          final imageBytes = base64Decode(item.source);
          return Image.memory(
            imageBytes,
            fit: widget.imageFit,
            errorBuilder: (context, error, stackTrace) =>
                widget.errorWidget ?? _buildErrorWidget(),
          );

        case ImageSourceType.file:
          final file = File(item.source);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: widget.imageFit,
              errorBuilder: (context, error, stackTrace) =>
                  widget.errorWidget ?? _buildErrorWidget(),
            );
          } else {
            return widget.errorWidget ?? _buildErrorWidget();
          }

        case ImageSourceType.asset:
          return Image.asset(
            item.source,
            fit: widget.imageFit,
            errorBuilder: (context, error, stackTrace) =>
                widget.errorWidget ?? _buildErrorWidget(),
          );
      }
    } catch (e) {
      return widget.errorWidget ?? _buildErrorWidget();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined,
            size: 48, color: Colors.grey),
      ),
    );
  }

  Widget _buildCarouselItem(CarouselImageItem item) {
    return Stack(
      children: [
        _buildImageWidget(item),
        if (item.label != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(widget.borderRadius),
                  bottomRight: Radius.circular(widget.borderRadius),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                item.label ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildIndicatorDots() {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.images.length,
        (index) => GestureDetector(
          onTap: () => _carouselController.animateToPage(index),
          child: Container(
            width: _currentIndex == index ? 28 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: _currentIndex == index
                  ? Colors.blue
                  : Colors.grey.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIndicatorLine() {
    if (widget.images.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(
          widget.images.length,
          (index) => Expanded(
            child: GestureDetector(
              onTap: () => _carouselController.animateToPage(index),
              child: Container(
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: _currentIndex == index
                      ? Colors.blue
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: const Center(child: Text('No images available')),
      );
    }

    return Column(
      children: [
        CarouselSlider(
          carouselController: _carouselController,
          options: CarouselOptions(
            height: widget.height,
            viewportFraction: 0.95,
            initialPage: 0,
            enableInfiniteScroll: widget.images.length > 1,
            autoPlay: widget.autoPlay && widget.images.length > 1,
            autoPlayInterval: widget.autoPlayInterval,
            autoPlayAnimationDuration: widget.animationDuration,
            onPageChanged: (index, reason) {
              setState(() {
                _currentIndex = index;
              });
              widget.onPageChanged?.call(index);
            },
            scrollDirection: Axis.horizontal,
          ),
          items: widget.images.map((item) {
            return Padding(
              padding: widget.itemPadding ??
                  const EdgeInsets.symmetric(horizontal: 4),
              child: _buildCarouselItem(item),
            );
          }).toList(),
        ),
        if (widget.showIndicator)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: widget.indicatorType == IndicatorType.dots
                ? _buildIndicatorDots()
                : _buildIndicatorLine(),
          ),
      ],
    );
  }
}
