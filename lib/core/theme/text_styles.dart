import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle display(bool isDark, {double size = 40}) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
        letterSpacing: 1.0,
      );

  static TextStyle headline(bool isDark, {double size = 24}) =>
      GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
        letterSpacing: 0.5,
      );

  static TextStyle title(bool isDark, {double size = 16}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textDarkPrimary : AppColors.textLightPrimary,
      );

  static TextStyle body(bool isDark, {double size = 14}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w400,
        color:
            isDark ? AppColors.textDarkSecondary : AppColors.textLightSecondary,
      );

  static TextStyle label(bool isDark, {double size = 12}) =>
      GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textDarkMuted : AppColors.textLightMuted,
      );

  static TextStyle orange({double size = 14}) => GoogleFonts.rajdhani(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryOrange,
        letterSpacing: 0.5,
      );

  static TextStyle button({double size = 15}) => GoogleFonts.inter(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: Colors.white,
        letterSpacing: 0.3,
      );
}
