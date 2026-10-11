import 'package:flutter/material.dart';

import '../core/store.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/bits.dart';
import '../widgets/cards.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key, required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bookmarks = BookmarksScope.of(context);
    final items = bookmarks.items;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tersimpan', style: AppType.display(44, color: p.ink, weight: FontWeight.w800, height: 1.05)),
                  const SizedBox(height: 4),
                  Text(
                    items.isEmpty
                        ? 'Bacaan untuk nanti akan muncul di sini.'
                        : '${items.length} artikel · bisa dibaca tanpa internet',
                    style: AppType.serif(16, color: p.muted, style: FontStyle.italic, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  const DoubleRule(),
                ],
              ),
            ),
          ),
          if (items.isEmpty)
            SliverToBoxAdapter(
              child: StateMessage(
                icon: Icons.bookmark_add_outlined,
                title: 'Belum ada yang disimpan',
                message: 'Ketuk ikon penanda di halaman artikel untuk menyimpannya ke sini.',
                actionLabel: 'Cari bacaan',
                onAction: onBrowse,
              ),
            )
          else
            SliverList.builder(
              itemCount: items.length,
              itemBuilder: (context, i) {
                final a = items[i];
                return Dismissible(
                  key: ValueKey('saved-${a.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                    padding: const EdgeInsets.only(right: 24),
                    alignment: Alignment.centerRight,
                    decoration: BoxDecoration(
                      color: p.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('HAPUS', style: AppType.mono(11, color: Colors.white, weight: FontWeight.w700)),
                        const SizedBox(width: 8),
                        const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ],
                    ),
                  ),
                  onDismissed: (_) {
                    final index = bookmarks.remove(a.id);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: const Text('Dihapus dari Tersimpan'),
                        action: SnackBarAction(
                          label: 'URUNGKAN',
                          onPressed: () => bookmarks.insert(index, a),
                        ),
                      ));
                  },
                  child: ArticleTile(article: a, heroTag: 'saved-${a.id}'),
                );
              },
            ),
          SliverToBoxAdapter(child: SizedBox(height: bottom + 110)),
        ],
      ),
    );
  }
}
