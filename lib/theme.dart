import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet "kertas & tinta" dengan satu aksen.
abstract final class AppColors {
  static const paper = Color(0xFFF4EFE6);
  static const card = Color(0xFFFFFCF7);
  static const ink = Color(0xFF1A1714);
  static const inkSoft = Color(0xFF45403A);
  static const muted = Color(0xFF8A8175);
  static const line = Color(0xFFE4DBCC);
  static const accent = Color(0xFFC8411F);
}

abstract final class AppText {
  /// Judul — Fraunces.
  static TextStyle headline(
    double size, {
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w600,
  }) => GoogleFonts.fraunces(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: 1.15,
    letterSpacing: size > 26 ? -0.8 : -0.2,
  );

  /// Bacaan panjang — Source Serif.
  static TextStyle body(double size, {Color color = AppColors.ink, FontStyle? style}) =>
      GoogleFonts.sourceSerif4(fontSize: size, color: color, height: 1.7, fontStyle: style);

  /// Label kecil huruf kapital.
  static TextStyle label({Color color = AppColors.muted}) =>
      GoogleFonts.ibmPlexSans(fontSize: 10.5, fontWeight: FontWeight.w600, letterSpacing: 1.4, color: color);

  static TextStyle ui(double size, {Color color = AppColors.ink, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.ibmPlexSans(fontSize: size, color: color, fontWeight: weight);
}

/// Bayangan berlapis: satu tipis dekat tepi, satu lembut yang jauh.
const softShadow = [
  BoxShadow(color: Color(0x0D3B2A12), blurRadius: 2, offset: Offset(0, 1)),
  BoxShadow(color: Color(0x143B2A12), blurRadius: 24, offset: Offset(0, 12), spreadRadius: -8),
];

ThemeData buildTheme() {
  final base = ThemeData(useMaterial3: true);
  final radius = BorderRadius.circular(14);
  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
    borderRadius: radius,
    borderSide: BorderSide(color: c, width: w),
  );

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.paper,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.accent)
        .copyWith(primary: AppColors.accent, surface: AppColors.paper, onSurface: AppColors.ink),
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.card,
      labelStyle: AppText.ui(14, color: AppColors.muted),
      hintStyle: AppText.ui(14, color: AppColors.muted),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.ink, 1.4),
      errorBorder: border(AppColors.accent),
      focusedErrorBorder: border(AppColors.accent, 1.4),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: const StadiumBorder(),
        textStyle: AppText.ui(14.5, weight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.ink,
      foregroundColor: AppColors.paper,
      shape: StadiumBorder(),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: AppText.headline(22),
    ),
    switchTheme: SwitchThemeData(
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? AppColors.accent : AppColors.line,
      ),
      thumbColor: const WidgetStatePropertyAll(Colors.white),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
  );
}
