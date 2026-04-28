import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class SvgIcon extends StatelessWidget {
  const SvgIcon(
      {super.key,
      required this.name,
      this.width,
      this.height,
      this.color,
      this.leftPadding});

  final String name;
  final double? width;
  final double? height;
  final Color? color;
  final double? leftPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftPadding ?? 0),
      child: SvgPicture.asset('assets/icons/$name.svg',
          width: width, height: height, color: color),
    );
  }
}

class AppImage extends StatelessWidget {
  const AppImage(
      {super.key, required this.name, this.width, this.height, this.fit});

  final String name;
  final double? width;
  final double? height;
  final BoxFit? fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/icons/$name.png',
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
    );
  }
}
