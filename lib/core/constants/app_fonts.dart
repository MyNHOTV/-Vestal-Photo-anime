import 'package:flutter/material.dart';
import 'package:flutter_quick_base/core/constants/app_colors.dart';

const kMyFont = 'SwissNowTrial';
const kBricolageGrotesqueFont = 'SwissNowTrial';

class AppFontWeights {
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight book = FontWeight.w400; // Book variant also uses w400
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

// Text styles
var kTextHeadingStyle = const TextStyle(
    fontFamily: kMyFont,
    fontSize: 16,
    fontWeight: AppFontWeights.semiBold, // w600
    color: AppColors.surface);

var kTextRegularStyle = TextStyle(
    fontFamily: kMyFont,
    fontSize: 14,
    fontWeight: AppFontWeights.regular, // w500
    color: AppColors.colorBlack.withOpacity(0.6));

var kTextMediumtStyle = const TextStyle(
    fontFamily: kMyFont,
    fontSize: 18,
    fontWeight: AppFontWeights.medium, // w500
    color: AppColors.surface);

const kTextSmallStyle = TextStyle(
    fontFamily: kMyFont,
    fontSize: 12,
    fontWeight: AppFontWeights.semiBold, // w600
    color: AppColors.surface);

const kTextDisableStyle = TextStyle(
    fontFamily: kMyFont,
    fontSize: 14,
    fontWeight: AppFontWeights.semiBold, // w600
    color: AppColors.disableColorText);

const kTextCriticalStyle = TextStyle(
    fontFamily: kMyFont,
    fontSize: 12,
    fontWeight: AppFontWeights.regular, // w400
    color: AppColors.error);

const kTextButtonStyle = TextStyle(
    fontFamily: kMyFont,
    fontSize: 14,
    fontWeight: AppFontWeights.semiBold, // w600
    color: AppColors.surface);

const kGradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        AppColors.colorA30049,
        AppColors.colorFF18BA,
        AppColors.colorE037B3,
        AppColors.colorAD01C3,
        AppColors.color600088,
      ],
      tileMode: TileMode.clamp,
      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
    ),
    borderRadius: BorderRadius.only(
      bottomLeft: Radius.circular(24),
      bottomRight: Radius.circular(24),
    ));

var kBricolageHeadingStyle = const TextStyle(
    fontFamily: kBricolageGrotesqueFont,
    fontSize: 16,
    fontWeight: AppFontWeights.semiBold, // w600
    color: AppColors.surface);

var kBricolageRegularStyle = const TextStyle(
    fontFamily: kBricolageGrotesqueFont,
    fontSize: 14,
    fontWeight: AppFontWeights.regular, // w400
    color: AppColors.surface);

var kBricolageBoldStyle = const TextStyle(
    fontFamily: kBricolageGrotesqueFont,
    fontSize: 14,
    fontWeight: AppFontWeights.bold, // w700
    color: AppColors.surface);
