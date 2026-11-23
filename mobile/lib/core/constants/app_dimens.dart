import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppDimens {
  AppDimens._();

  // Padding & Spacing
  static const double p4 = 4.0;
  static const double p8 = 8.0;
  static const double p12 = 12.0;
  static const double p16 = 16.0;
  static const double p20 = 20.0;
  static const double p24 = 24.0;
  static const double p32 = 32.0;

  // Radius
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r16 = 16.0;
  static const double r20 = 20.0;
  static const double r24 = 24.0;
  static const double rFull = 999.0;

  // Subtle shadows
  static List<BoxShadow> get cardShadow => [
        const BoxShadow(
          color: Color(0x06000000),
          offset: Offset(0, 2),
          blurRadius: 8,
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        const BoxShadow(
          color: Color(0x0F000000),
          offset: Offset(0, 4),
          blurRadius: 16,
          spreadRadius: 0,
        ),
      ];

  // Standard Card Decoration
  static BoxDecoration cardDecoration({
    Color color = AppColors.surface,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: borderRadius ?? BorderRadius.circular(r16),
      border: border ?? Border.all(color: AppColors.border, width: 1.0),
      boxShadow: cardShadow,
    );
  }
}
