import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/store.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/surfaces.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'saved_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _index = widget.initialIndex;

  void _go(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(0);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          extendBody: true,
          body: PaperBackground(
            child: IndexedStack(
              index: _index,
              children: [
                const HomeScreen(),
                const ExploreScreen(),
                SavedScreen(onBrowse: () => _go(1)),
              ],
            ),
          ),
          bottomNavigationBar: _FloatingNav(index: _index, onChanged: _go),
        ),
      ),
    );
  }
}

class _FloatingNav extends StatelessWidget {
  const _FloatingNav({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  static const _items = [
    (Icons.newspaper_outlined, Icons.newspaper_rounded, 'Beranda'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Jelajah'),
    (Icons.bookmark_outline_rounded, Icons.bookmark_rounded, 'Tersimpan'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final saved = BookmarksScope.of(context).length;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: p.shadow.withValues(alpha: (0.16 * p.shadowStrength).clamp(0, 1)),
                blurRadius: 30,
                offset: const Offset(0, 14),
                spreadRadius: -8,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 64,
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: p.card.withValues(alpha: 0.82),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: p.rule.withValues(alpha: 0.9)),
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        flex: i == index ? 5 : 3,
                        child: Pressable(
                          scale: 0.92,
                          onTap: () => onChanged(i),
                          child: _NavItem(
                            icon: i == index ? _items[i].$2 : _items[i].$1,
                            label: _items[i].$3,
                            selected: i == index,
                            badge: i == 2 && saved > 0 ? saved : null,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, this.badge});

  final IconData icon;
  final String label;
  final bool selected;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? p.ink : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Badge(
              isLabelVisible: badge != null && !selected,
              backgroundColor: p.accent,
              label: Text('${badge ?? ''}'),
              child: Icon(icon, size: 22, color: selected ? p.paper : p.muted),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                  softWrap: false,
                  style: AppType.sans(13.5, color: p.paper, weight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
