import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/feed.dart';
import '../core/models.dart';
import '../navigation.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/bits.dart';
import '../widgets/feed_sliver.dart';
import '../widgets/pinned_bar.dart';
import '../widgets/surfaces.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _api = NewsApi.instance;
  final _query = TextEditingController();
  final _focus = FocusNode();
  final _results = ArticleFeed(pageSize: 12);
  Timer? _debounce;
  String? _tag;

  late Future<List<NewsCategory>> _categories = _api.categories();
  late Future<List<Author>> _authors = _api.authors();
  late Future<List<MapEntry<String, int>>> _tags = _loadTags();

  bool get _searching => _query.text.trim().isNotEmpty || _tag != null;

  /// API tidak punya endpoint tag, jadi tag dihitung dari 50 artikel terbaru.
  Future<List<MapEntry<String, int>>> _loadTags() async {
    final page = await _api.articles(limit: 50);
    final counts = <String, int>{};
    for (final a in page.items) {
      for (final t in a.tags) {
        counts[t] = (counts[t] ?? 0) + 1;
      }
    }
    return counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _query.dispose();
    _focus.dispose();
    _results.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 420), _search);
  }

  void _search() {
    if (!_searching) return;
    _results
      ..search = _query.text.trim()
      ..tag = _tag;
    _results.refresh();
  }

  void _setTag(String? tag) {
    setState(() => _tag = tag);
    _search();
  }

  void _clear() {
    _query.clear();
    _focus.unfocus();
    setState(() => _tag = null);
  }

  Future<void> _refresh() async {
    if (_searching) return _results.refresh();
    setState(() {
      _categories = _api.categories();
      _authors = _api.authors();
      _tags = _loadTags();
    });
    try {
      await Future.wait<Object>([_categories, _authors, _tags]);
    } on ApiException catch (_) {/* error ditampilkan per bagian */}
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _refresh,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Jelajah', style: AppType.display(44, color: p.ink, weight: FontWeight.w800, height: 1.05)),
                    const SizedBox(height: 4),
                    Text('Telusuri rubrik, topik, dan para penulis.',
                        style: AppType.serif(16, color: p.muted, style: FontStyle.italic, height: 1.4)),
                  ],
                ),
              ),
            ),
            PinnedBar(height: _tag != null ? 118 : 76, child: _searchBar(p)),
            if (_searching) ...[
              SliverToBoxAdapter(
                child: ListenableBuilder(
                  listenable: _results,
                  builder: (context, _) => Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                    child: Text(
                      _results.page == 0 ? 'MENCARI…' : '${_results.total} HASIL',
                      style: AppType.mono(10.5, color: p.muted),
                    ),
                  ),
                ),
              ),
              FeedSliver(
                feed: _results,
                heroPrefix: 'explore',
                leadFirst: false,
                emptyTitle: 'Tidak ketemu',
                emptyMessage: 'Coba kata kunci lain, atau hapus filter topik.',
              ),
            ] else ...[
              const SliverToBoxAdapter(child: SectionHeader('Rubrik', eyebrow: 'Bagian')),
              _categoryGrid(p),
              const SliverToBoxAdapter(child: SectionHeader('Topik Hangat', eyebrow: 'Sering muncul')),
              SliverToBoxAdapter(child: _tagCloud(p)),
              const SliverToBoxAdapter(child: SectionHeader('Penulis', eyebrow: 'Meja redaksi')),
              SliverToBoxAdapter(child: _authorStrip(p)),
            ],
            SliverToBoxAdapter(child: SizedBox(height: bottom + 110)),
          ],
        ),
      ),
    );
  }

  Widget _searchBar(Palette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _focus.hasFocus ? p.ink : p.rule, width: 1.2),
              boxShadow: p.depth(0.6),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Icon(Icons.search_rounded, color: p.muted),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _query,
                    focusNode: _focus,
                    onChanged: _onChanged,
                    onSubmitted: (_) {
                      _debounce?.cancel();
                      _search();
                    },
                    onTap: () => setState(() {}),
                    textInputAction: TextInputAction.search,
                    style: AppType.sans(15.5, color: p.ink),
                    decoration: const InputDecoration(
                      hintText: 'Cari judul atau ringkasan…',
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                if (_searching)
                  IconButton(
                    tooltip: 'Bersihkan',
                    onPressed: _clear,
                    icon: Icon(Icons.close_rounded, color: p.muted, size: 20),
                  ),
              ],
            ),
          ),
          if (_tag != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ChoicePill(
                label: '#$_tag  ✕',
                selected: true,
                onTap: () => _setTag(null),
              ),
            ),
        ],
      ),
    );
  }

  Widget _categoryGrid(Palette p) {
    return FutureBuilder<List<NewsCategory>>(
      future: _categories,
      builder: (context, snap) {
        if (snap.hasError) {
          return SliverToBoxAdapter(
            child: StateMessage.error('${snap.error}', () => setState(() => _categories = _api.categories())),
          );
        }
        final items = snap.data;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              childAspectRatio: 0.92,
            ),
            itemCount: items?.length ?? 4,
            itemBuilder: (context, i) => items == null
                ? const Shimmer(child: SkeletonBox(height: 160, radius: 18))
                : _CategoryTile(category: items[i]),
          ),
        );
      },
    );
  }

  Widget _tagCloud(Palette p) {
    return FutureBuilder<List<MapEntry<String, int>>>(
      future: _tags,
      builder: (context, snap) {
        final tags = snap.data;
        if (tags == null) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Shimmer(child: SkeletonBox(height: 80, radius: 14)),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags.take(18))
                ChoicePill(
                  label: '#${t.key}',
                  count: t.value,
                  selected: false,
                  onTap: () => _setTag(t.key),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _authorStrip(Palette p) {
    return SizedBox(
      height: 196,
      child: FutureBuilder<List<Author>>(
        future: _authors,
        builder: (context, snap) {
          final items = snap.data;
          if (snap.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _authors = _api.authors()),
                child: const Text('Gagal memuat penulis — coba lagi'),
              ),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            itemCount: items?.length ?? 3,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, i) => items == null
                ? const Shimmer(child: SkeletonBox(width: 148, height: 170, radius: 18))
                : _AuthorCard(author: items[i]),
          );
        },
      ),
    );
  }
}

/// Kartu rubrik dengan "kertas" berwarna yang mengintip di belakangnya.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final NewsCategory category;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final tone = p.tone(category.slug);
    return Pressable(
      onTap: () => openCategory(context, category, description: category.description),
      child: Stack(
        children: [
          Positioned.fill(
            left: 7,
            top: 7,
            child: DecoratedBox(
              decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(18)),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 7, bottom: 7),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.ink, width: 1.3),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.articleCount.toString().padLeft(2, '0'),
                        style: AppType.display(34, color: tone, weight: FontWeight.w800, height: 1)),
                    const Spacer(),
                    Icon(Icons.arrow_outward_rounded, size: 20, color: p.ink),
                  ],
                ),
                Text('ARTIKEL', style: AppType.mono(8.5, color: p.muted)),
                const Spacer(),
                Text(category.name, style: AppType.display(19, color: p.ink, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  category.description ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.sans(11.5, color: p.muted, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard({required this.author});

  final Author author;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: () => openAuthor(context, author),
      child: Container(
        width: 148,
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.rule.withValues(alpha: 0.8), width: 0.8),
          boxShadow: p.depth(),
        ),
        child: Column(
          children: [
            Avatar(name: author.name, url: author.avatarUrl, size: 62, ring: p.tone(author.name.toLowerCase())),
            const SizedBox(height: 12),
            Text(author.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppType.display(15, color: p.ink, height: 1.15)),
            const Spacer(),
            Text('${author.articleCount} TULISAN', style: AppType.mono(9.5, color: p.muted)),
          ],
        ),
      ),
    );
  }
}
