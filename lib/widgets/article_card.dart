import 'package:flutter/material.dart';

import '../models/article.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// Baris artikel: teks di kiri, foto di kanan.
class ArticleCard extends StatelessWidget {
  const ArticleCard({super.key, required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: softShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CategoryLabel(article.category),
                      const SizedBox(height: 8),
                      Text(
                        article.title,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.headline(17),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${timeAgo(article.publishedAt)}  ·  ${compactNumber(article.views)} dibaca',
                        style: AppText.ui(12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox.square(dimension: 92, child: NetImage(article.thumbnailUrl)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Kartu besar untuk carousel "Pilihan Redaksi".
class FeaturedCard extends StatelessWidget {
  const FeaturedCard({super.key, required this.article, required this.onTap});

  final Article article;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x403B2A12), blurRadius: 30, offset: Offset(0, 16), spreadRadius: -12),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            NetImage(article.thumbnailUrl),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.35, 1],
                  colors: [Color(0x00000000), Color(0xDD000000)],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CategoryLabel(article.category, color: Colors.white),
                  const SizedBox(height: 10),
                  Text(
                    article.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.headline(24, color: Colors.white, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${article.author.name}  ·  ${timeAgo(article.publishedAt)}',
                    style: AppText.ui(12.5, color: Colors.white70),
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
