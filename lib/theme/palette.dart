import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Warna "kertas & tinta". Satu aksen (vermilion) supaya tidak ramai;
/// warna lain hanya dipakai sebagai penanda rubrik.
@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.rule,
    required this.accent,
    required this.shadow,
    required this.shadowStrength,
    required this.isDark,
  });

  final Color paper;
  final Color card;
  final Color ink;
  final Color inkSoft;
  final Color muted;
  final Color rule;
  final Color accent;
  final Color shadow;
  final double shadowStrength;
  final bool isDark;

  static const light = Palette(
    paper: Color(0xFFF1EBDF),
    card: Color(0xFFFBF8F2),
    ink: Color(0xFF17140F),
    inkSoft: Color(0xFF3C362E),
    muted: Color(0xFF7B7266),
    rule: Color(0xFFDCD2C2),
    accent: Color(0xFFD7401D),
    shadow: Color(0xFF3B2A12),
    shadowStrength: 1,
    isDark: false,
  );

  static const dark = Palette(
    paper: Color(0xFF13110E),
    card: Color(0xFF1D1A16),
    ink: Color(0xFFEFE8DC),
    inkSoft: Color(0xFFD3CABB),
    muted: Color(0xFF978D7E),
    rule: Color(0xFF302B24),
    accent: Color(0xFFF0582F),
    shadow: Color(0xFF000000),
    shadowStrength: 3,
    isDark: true,
  );

  /// Bayangan berlapis: satu tajam dekat tepi + satu lembut yang jauh.
  List<BoxShadow> depth([double level = 1]) => [
        BoxShadow(
          color: shadow.withValues(alpha: (0.05 * shadowStrength).clamp(0, 1)),
          blurRadius: 1.5,
          offset: const Offset(0, 1),
        ),
        BoxShadow(
          color: shadow
              .withValues(alpha: (0.08 * level * shadowStrength).clamp(0, 1)),
          blurRadius: 22 * level,
          offset: Offset(0, 10 * level),
          spreadRadius: -6,
        ),
      ];

  static const _tones = {
    'teknologi': Color(0xFF2F5BD3),
    'olahraga': Color(0xFF1E8752),
    'ekonomi': Color(0xFFBF7A10),
    'hiburan': Color(0xFFB2386F),
    'kesehatan': Color(0xFF128486),
    'otomotif': Color(0xFF8C4A26),
  };
  static const _fallback = [
    Color(0xFF4B5BA8),
    Color(0xFF7D6A1E),
    Color(0xFF6D3F8C),
    Color(0xFF2E7A6E),
  ];

  Color tone(String slug) {
    final base = _tones[slug] ??
        _fallback[slug.codeUnits.fold<int>(0, (a, b) => a + b) %
            _fallback.length];
    return isDark ? Color.lerp(base, Colors.white, 0.28)! : base;
  }

  @override
  Palette copyWith({Color? paper, Color? card, Color? ink, Color? accent}) =>
      Palette(
        paper: paper ?? this.paper,
        card: card ?? this.card,
        ink: ink ?? this.ink,
        inkSoft: inkSoft,
        muted: muted,
        rule: rule,
        accent: accent ?? this.accent,
        shadow: shadow,
        shadowStrength: shadowStrength,
        isDark: isDark,
      );

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    return Palette(
      paper: Color.lerp(paper, other.paper, t)!,
      card: Color.lerp(card, other.card, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkSoft: Color.lerp(inkSoft, other.inkSoft, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      rule: Color.lerp(rule, other.rule, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      shadowStrength: lerpDouble(shadowStrength, other.shadowStrength, t)!,
      isDark: t < 0.5 ? isDark : other.isDark,
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}
