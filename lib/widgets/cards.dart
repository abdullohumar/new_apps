import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/models.dart';
import '../navigation.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import 'bits.dart';
import 'surfaces.dart';

BoxDecoration _cardDecoration(Palette p, {double radius = 18, double level = 1}) =>
    BoxDecoration(
      color: p.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: p.rule.withValues(alpha: 0.8), width: 0.8),
      boxShadow: p.depth(level),
    );

/// Baris artikel: teks di kiri, foto persegi di kanan.
class ArticleTile extends StatelessWidget {
  const ArticleTile({super.key, required this.article, required this.heroTag, this.rank});

  final Article article;
  final String heroTag;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = article;
    return Pressable(
      onTap: () => openArticle(context, a, heroTag: heroTag),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: _cardDecoration(p, radius: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryKicker(a.category, size: 9.5),
                    const SizedBox(height: 7),
                    Text(
                      a.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.display(16.5, color: p.ink, height: 1.22),
                    ),
                    const SizedBox(height: 9),
                    MetaLine([timeAgo(a.publishedAt), '${compact(a.views)} dibaca'], size: 11),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 96,
              height: 96,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Hero(tag: heroTag, child: NetImage(a.thumbnailUrl)),
                    ),
                  ),
                  if (rank != null)
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(7, 1, 7, 3),
                        decoration: BoxDecoration(
                          color: p.card,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: p.depth(0.4),
                        ),
                        child: Text(rank!.toString().padLeft(2, '0'),
                            style: AppType.display(15, color: p.ink, weight: FontWeight.w800)),
                      ),
                    ),
                  if (a.isBreaking)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: p.accent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu utama di puncak daftar: foto lebar, judul besar, ringkasan.
class LeadCard extends StatelessWidget {
  const LeadCard({super.key, required this.article, required this.heroTag, this.rank});

  final Article article;
  final String heroTag;
  final int? rank;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = article;
    return Pressable(
      scale: 0.985,
      onTap: () => openArticle(context, a, heroTag: heroTag),
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 10),
        decoration: _cardDecoration(p, radius: 20, level: 1.5),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(tag: heroTag, child: NetImage(a.thumbnailUrl)),
                  if (a.isBreaking || rank != null)
                    Positioned(
                      left: 12,
                      top: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: rank != null ? p.ink : p.accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          rank != null ? 'NO. 1 TERPOPULER' : 'TERKINI',
                          style: AppType.mono(9.5, color: Colors.white, weight: FontWeight.w700),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryKicker(a.category),
                  const SizedBox(height: 10),
                  Text(a.title, style: AppType.display(23, color: p.ink, height: 1.15)),
                  if (a.summary != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      a.summary!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.serif(14.5, color: p.inkSoft, height: 1.5),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Avatar(name: a.author.name, url: a.author.avatarUrl, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MetaLine([
                          a.author.name,
                          timeAgo(a.publishedAt),
                          '${compact(a.views)} dibaca',
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu kecil untuk daftar horizontal (artikel terkait).
class CompactCard extends StatelessWidget {
  const CompactCard({super.key, required this.article, required this.heroTag});

  final Article article;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = article;
    return Pressable(
      onTap: () => openArticle(context, a, heroTag: heroTag),
      child: Container(
        width: 224,
        margin: const EdgeInsets.only(right: 14, bottom: 18, top: 4),
        decoration: _cardDecoration(p, radius: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Hero(tag: heroTag, child: NetImage(a.thumbnailUrl)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryKicker(a.category, size: 9),
                  const SizedBox(height: 6),
                  Text(a.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.display(15, color: p.ink, height: 1.22)),
                  const SizedBox(height: 8),
                  MetaLine([timeAgo(a.publishedAt)], size: 10.5),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TileSkeleton extends StatelessWidget {
  const TileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: _cardDecoration(p, radius: 16),
      child: const Shimmer(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 70, height: 9),
                  SizedBox(height: 12),
                  SkeletonBox(height: 14),
                  SizedBox(height: 7),
                  SkeletonBox(width: 150, height: 14),
                  SizedBox(height: 14),
                  SkeletonBox(width: 110, height: 9),
                ],
              ),
            ),
            SizedBox(width: 14),
            SkeletonBox(width: 96, height: 96, radius: 12),
          ],
        ),
      ),
    );
  }
}
