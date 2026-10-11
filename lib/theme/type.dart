import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Fraunces untuk judul, Source Serif untuk bacaan panjang,
/// IBM Plex Sans untuk UI, IBM Plex Mono untuk label & metadata.
abstract final class AppType {
  static TextStyle display(double size,
          {Color? color, FontWeight weight = FontWeight.w600, double? height}) =>
      GoogleFonts.fraunces(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.12,
        letterSpacing: size >= 28 ? -0.035 * size : -0.2,
      );

  static TextStyle serif(double size,
          {Color? color, FontStyle? style, double height = 1.7}) =>
      GoogleFonts.sourceSerif4(
        fontSize: size,
        color: color,
        fontStyle: style,
        height: height,
      );

  static TextStyle sans(double size,
          {Color? color,
          FontWeight weight = FontWeight.w400,
          double? height}) =>
      GoogleFonts.ibmPlexSans(
        fontSize: size,
        color: color,
        fontWeight: weight,
        height: height,
      );

  static TextStyle mono(double size,
          {Color? color, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        color: color,
        fontWeight: weight,
        letterSpacing: 0.9,
        height: 1.2,
      );
}
