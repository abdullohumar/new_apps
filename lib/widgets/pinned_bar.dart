import 'package:flutter/material.dart';

import '../theme/palette.dart';

/// Baris yang menempel di atas saat digulir, dengan bayangan yang muncul
/// hanya ketika konten lewat di bawahnya.
class PinnedBar extends StatelessWidget {
  const PinnedBar({super.key, required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => SliverPersistentHeader(
        pinned: true,
        delegate: _Delegate(height: height, child: child, palette: context.palette),
      );
}

class _Delegate extends SliverPersistentHeaderDelegate {
  _Delegate({required this.height, required this.child, required this.palette});

  final double height;
  final Widget child;
  final Palette palette;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final stuck = shrinkOffset > 0 || overlapsContent;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: palette.paper,
        border: Border(
          bottom: BorderSide(color: stuck ? palette.rule : palette.paper.withValues(alpha: 0)),
        ),
        boxShadow: [
          if (stuck)
            BoxShadow(
              color: palette.shadow.withValues(alpha: (0.07 * palette.shadowStrength).clamp(0, 1)),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_Delegate old) => true;
}
