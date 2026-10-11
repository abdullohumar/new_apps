import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// Latar kertas dengan butiran halus — supaya layar tidak terasa plastik.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ColoredBox(
      color: p.paper,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(painter: _GrainPainter(p.ink, p.isDark)),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.color, this.dark);

  final Color color;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final count = (size.width * size.height / 55).round().clamp(0, 40000);
    final pts = Float32List(count * 2);
    for (var i = 0; i < pts.length; i++) {
      pts[i] = rnd.nextDouble() * (i.isEven ? size.width : size.height);
    }
    canvas.drawRawPoints(
      ui.PointMode.points,
      pts,
      Paint()
        ..color = color.withValues(alpha: dark ? 0.035 : 0.055)
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_GrainPainter old) =>
      old.color != color || old.dark != dark;
}

/// Mengecil sedikit saat ditekan — memberi rasa "fisik".
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.975,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}

/// Gambar jaringan dengan fade-in dan placeholder arsir ala cetakan.
class NetImage extends StatelessWidget {
  const NetImage(this.url,
      {super.key, this.fit = BoxFit.cover, this.alignment = Alignment.center});

  final String? url;
  final BoxFit fit;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final placeholder = _Hatch(color: context.palette.rule);
    if (url == null || url!.isEmpty) return placeholder;
    return Stack(
      fit: StackFit.expand,
      children: [
        placeholder,
        Image.network(
          url!,
          fit: fit,
          alignment: alignment,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, sync) => sync
              ? child
              : AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOut,
                  child: child,
                ),
          errorBuilder: (_, _, _) => placeholder,
        ),
      ],
    );
  }
}

class _Hatch extends StatelessWidget {
  const _Hatch({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: color.withValues(alpha: 0.35),
        child: CustomPaint(painter: _HatchPainter(color), child: const SizedBox.expand()),
      );
}

class _HatchPainter extends CustomPainter {
  _HatchPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 9) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.color != color;
}

class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final base = p.rule.withValues(alpha: 0.75);
    final hi = Color.lerp(p.rule, p.card, 0.85)!;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (rect) => LinearGradient(
          colors: [base, hi, base],
          stops: const [0.35, 0.5, 0.65],
          transform: _Slide(_c.value),
        ).createShader(rect),
        child: child,
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(bounds.width * (t * 2 - 1), 0, 0);
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, required this.height, this.radius = 6});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );
}
