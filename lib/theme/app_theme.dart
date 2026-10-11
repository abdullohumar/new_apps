import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'palette.dart';
import 'type.dart';

ThemeData buildTheme(Brightness brightness) {
  final p = brightness == Brightness.dark ? Palette.dark : Palette.light;
  final base = ThemeData(brightness: brightness, useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: brightness,
  ).copyWith(
    primary: p.accent,
    onPrimary: Colors.white,
    surface: p.paper,
    onSurface: p.ink,
    error: const Color(0xFFC0321A),
  );
  final radius = BorderRadius.circular(14);

  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: p.paper,
    canvasColor: p.paper,
    extensions: [p],
    // google_fonts 9 memakai TextTheme dari `material_ui`, jadi cukup ambil
    // nama keluarganya (sekaligus memicu unduhan font).
    textTheme: base.textTheme.apply(
      fontFamily: GoogleFonts.ibmPlexSans().fontFamily,
      bodyColor: p.ink,
      displayColor: p.ink,
    ),
    splashFactory: InkRipple.splashFactory,
    dividerColor: p.rule,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: p.accent,
      selectionColor: p.accent.withValues(alpha: 0.25),
      selectionHandleColor: p.accent,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    }),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.ink,
      contentTextStyle: AppType.sans(14, color: p.paper),
      actionTextColor: p.accent,
      shape: RoundedRectangleBorder(borderRadius: radius),
      insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: p.ink,
        foregroundColor: p.paper,
        textStyle: AppType.sans(14, weight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        side: BorderSide(color: p.rule, width: 1.2),
        textStyle: AppType.sans(14, weight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: p.accent,
        textStyle: AppType.sans(14, weight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.paper,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: AppType.sans(14, color: p.muted),
      labelStyle: AppType.sans(14, color: p.muted),
      floatingLabelStyle: AppType.sans(14, color: p.accent),
      border: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: p.rule)),
      enabledBorder: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: p.rule)),
      focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: p.accent, width: 1.6)),
      errorBorder: OutlineInputBorder(
          borderRadius: radius, borderSide: BorderSide(color: scheme.error)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: scheme.error, width: 1.6)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      titleTextStyle: AppType.display(22, color: p.ink),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.white : p.muted),
      trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.paper),
      trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? p.accent : p.rule),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.card,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: p.rule),
      ),
      textStyle: AppType.sans(14, color: p.ink),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    cupertinoOverrideTheme: CupertinoThemeData(primaryColor: p.accent),
  );
}
