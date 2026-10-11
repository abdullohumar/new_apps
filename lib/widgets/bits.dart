import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import 'surfaces.dart';

/// Label rubrik: kotak warna kecil + nama huruf kapital.
class CategoryKicker extends StatelessWidget {
  const CategoryKicker(this.category, {super.key, this.size = 10.5, this.light = false});

  final CategoryRef category;
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final tone = light ? Colors.white : context.palette.tone(category.slug);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size * 0.7,
          height: size * 0.7,
          decoration: BoxDecoration(
            color: light ? context.palette.tone(category.slug) : tone,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: size * 0.6),
        Text(
          category.name.toUpperCase(),
          style: AppType.mono(size, color: tone, weight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// Garis ganda khas kepala surat kabar.
class DoubleRule extends StatelessWidget {
  const DoubleRule({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = context.palette.ink;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 2.5, color: ink),
        const SizedBox(height: 3),
        Container(height: 0.8, color: ink),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.eyebrow});

  final String title;
  final String? eyebrow;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) ...[
                  Text(eyebrow!.toUpperCase(),
                      style: AppType.mono(10, color: p.accent, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                ],
                Text(title, style: AppType.display(23, color: p.ink)),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class MetaLine extends StatelessWidget {
  const MetaLine(this.parts, {super.key, this.color, this.size = 11.5});

  final List<String> parts;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.palette.muted;
    final shown = parts.where((s) => s.isNotEmpty).toList();
    return Text(
      shown.join('  ·  '),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppType.sans(size, color: c, weight: FontWeight.w500),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar({super.key, required this.name, this.url, this.size = 32, this.ring});

  final String name;
  final String? url;
  final double size;
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = ColoredBox(
      color: p.tone(name.toLowerCase()),
      child: Center(
        child: Text(initials(name),
            style: AppType.sans(size * 0.36, color: Colors.white, weight: FontWeight.w700)),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: ring != null ? const EdgeInsets.all(2) : null,
      decoration: ring != null
          ? BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ring!, width: 1.5))
          : null,
      child: ClipOval(
        child: url == null
            ? fallback
            : Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => fallback),
      ),
    );
  }
}

class SortToggle extends StatelessWidget {
  const SortToggle({super.key, required this.value, required this.onChanged});

  final ArticleSort value;
  final ValueChanged<ArticleSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.rule),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (sort, label) in const [
            (ArticleSort.latest, 'Terbaru'),
            (ArticleSort.popular, 'Populer'),
          ])
            GestureDetector(
              onTap: () => onChanged(sort),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: sort == value ? p.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  label,
                  style: AppType.sans(12.5,
                      weight: FontWeight.w600,
                      color: sort == value ? p.paper : p.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Pil pilihan (rubrik, tag).
class ChoicePill extends StatelessWidget {
  const ChoicePill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
    this.count,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      scale: 0.94,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? p.ink : p.card,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: selected ? p.ink : p.rule),
          boxShadow: selected ? p.depth(0.5) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
            ],
            Text(label,
                style: AppType.sans(13,
                    weight: FontWeight.w600, color: selected ? p.paper : p.ink)),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text('$count',
                  style: AppType.mono(10, color: selected ? p.paper.withValues(alpha: 0.6) : p.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Tombol bulat. `glass` dipakai di atas foto.
class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.glass = false,
    this.active = false,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool glass;
  final bool active;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = active ? p.accent : (glass ? Colors.white : p.ink);
    Widget child = AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: glass ? Colors.black.withValues(alpha: 0.3) : p.card,
        border: Border.all(
            color: glass ? Colors.white.withValues(alpha: 0.25) : p.rule),
      ),
      child: Icon(icon, size: 20, color: fg),
    );
    if (glass) {
      child = ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: child,
        ),
      );
    }
    return Semantics(
      button: true,
      label: tooltip,
      child: Pressable(onTap: onTap, scale: 0.9, child: child),
    );
  }
}

class Ornament extends StatelessWidget {
  const Ornament({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final line = Expanded(child: Container(height: 0.8, color: p.rule));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(label ?? '✶', style: AppType.mono(11, color: p.muted)),
          ),
          line,
        ],
      ),
    );
  }
}

class StateMessage extends StatelessWidget {
  const StateMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  factory StateMessage.error(String message, VoidCallback onRetry) => StateMessage(
        icon: Icons.wifi_tethering_error_rounded,
        title: 'Gagal memuat',
        message: message,
        actionLabel: 'Coba lagi',
        onAction: onRetry,
      );

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dua lingkaran bertumpuk — memberi kedalaman tanpa ilustrasi.
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle, color: p.accent.withValues(alpha: 0.85)),
                  ),
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.card,
                    border: Border.all(color: p.ink, width: 1.4),
                  ),
                  child: Icon(icon, size: 30, color: p.ink),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(title, textAlign: TextAlign.center, style: AppType.display(21, color: p.ink)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: AppType.sans(14, color: p.muted, height: 1.5)),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
