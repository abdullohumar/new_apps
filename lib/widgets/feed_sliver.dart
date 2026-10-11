import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/feed.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import 'bits.dart';
import 'cards.dart';

/// Sliver daftar artikel dengan muat-otomatis saat mendekati akhir.
class FeedSliver extends StatelessWidget {
  const FeedSliver({
    super.key,
    required this.feed,
    required this.heroPrefix,
    this.leadFirst = true,
    this.emptyTitle = 'Belum ada kabar',
    this.emptyMessage = 'Tidak ada artikel yang cocok di sini.',
  });

  final ArticleFeed feed;
  final String heroPrefix;
  final bool leadFirst;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: feed,
      builder: (context, _) {
        final items = feed.items;
        if (items.isEmpty) {
          final Widget child;
          if (feed.error != null) {
            child = StateMessage.error(feed.error!, feed.retry);
          } else if (feed.loading || feed.hasNext) {
            child = const Column(children: [
              TileSkeleton(),
              TileSkeleton(),
              TileSkeleton(),
              TileSkeleton(),
            ]);
          } else {
            child = StateMessage(
              icon: Icons.inbox_outlined,
              title: emptyTitle,
              message: emptyMessage,
            );
          }
          return SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: KeyedSubtree(key: ValueKey(child.runtimeType), child: child),
            ),
          );
        }

        final ranked = feed.sort == ArticleSort.popular;
        return SliverList.builder(
          itemCount: items.length + 1,
          itemBuilder: (context, i) {
            if (i >= items.length - 3) {
              WidgetsBinding.instance.addPostFrameCallback((_) => feed.loadMore());
            }
            if (i == items.length) return _Footer(feed: feed);
            final a = items[i];
            final tag = '$heroPrefix-${a.id}';
            final rank = ranked ? i + 1 : null;
            if (i == 0 && leadFirst) {
              return LeadCard(article: a, heroTag: tag, rank: rank);
            }
            return ArticleTile(article: a, heroTag: tag, rank: rank);
          },
        );
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.feed});

  final ArticleFeed feed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (feed.error != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(feed.error!,
                textAlign: TextAlign.center, style: AppType.sans(13, color: p.muted)),
            TextButton(onPressed: feed.retry, child: const Text('Coba lagi')),
          ],
        ),
      );
    }
    if (feed.hasNext || feed.loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    return Ornament(label: 'SELESAI · ${feed.total} ARTIKEL');
  }
}
