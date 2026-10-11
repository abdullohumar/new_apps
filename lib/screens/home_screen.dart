import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/feed.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../navigation.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/bits.dart';
import '../widgets/feed_sliver.dart';
import '../widgets/pinned_bar.dart';
import '../widgets/surfaces.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _api = NewsApi.instance;
  final _feed = ArticleFeed()..refresh();
  late Future<List<Article>> _breaking = _api.breaking(limit: 6);
  late Future<List<Article>> _featured = _api.featured(limit: 6);
  List<NewsCategory> _categories = const [];
  int? _revision;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  /// Muat ulang beranda setelah ada perubahan dari Ruang Redaksi.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rev = NewsroomScope.of(context).revision;
    if (_revision != null && rev != _revision) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _refresh();
      });
    }
    _revision = rev;
  }

  @override
  void dispose() {
    _feed.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final c = await _api.categories();
      if (mounted) setState(() => _categories = c);
    } on ApiException catch (_) {/* chip rubrik disembunyikan */}
  }

  Future<void> _refresh() async {
    setState(() {
      _breaking = _api.breaking(limit: 6);
      _featured = _api.featured(limit: 6);
    });
    _loadCategories();
    await _feed.refresh();
  }

  void _filter({String? category, ArticleSort? sort}) {
    final nextSort = sort ?? _feed.sort;
    if (category == _feed.category && nextSort == _feed.sort) return;
    setState(() {
      _feed.category = category;
      _feed.sort = nextSort;
    });
    _feed.refresh();
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
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            const SliverToBoxAdapter(child: _Masthead()),
            SliverToBoxAdapter(child: _BreakingTicker(future: _breaking)),
            SliverToBoxAdapter(child: _FeaturedCarousel(future: _featured)),
            SliverToBoxAdapter(
              child: SectionHeader(
                _feed.sort == ArticleSort.popular ? 'Paling Banyak Dibaca' : 'Kabar Terbaru',
                eyebrow: _feed.sort == ArticleSort.popular ? 'Peringkat' : 'Mengalir terus',
                trailing: SortToggle(value: _feed.sort, onChanged: (s) => _filter(category: _feed.category, sort: s)),
              ),
            ),
            if (_categories.isNotEmpty)
              PinnedBar(
                height: 56,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                  children: [
                    ChoicePill(
                      label: 'Semua',
                      selected: _feed.category == null,
                      onTap: () => _filter(category: null),
                    ),
                    for (final c in _categories) ...[
                      const SizedBox(width: 8),
                      ChoicePill(
                        label: c.name,
                        dot: p.tone(c.slug),
                        count: c.articleCount,
                        selected: _feed.category == c.slug,
                        onTap: () => _filter(category: c.slug),
                      ),
                    ],
                  ],
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 6)),
            FeedSliver(feed: _feed, heroPrefix: 'home-feed'),
            SliverToBoxAdapter(child: SizedBox(height: bottom + 110)),
          ],
        ),
      ),
    );
  }
}

class _Masthead extends StatelessWidget {
  const _Masthead();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    final settings = SettingsScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(fullDate(now).toUpperCase(),
                    maxLines: 1, overflow: TextOverflow.ellipsis, style: AppType.mono(10, color: p.muted)),
              ),
              Text(editionLabel(now).toUpperCase(),
                  style: AppType.mono(10, color: p.accent, weight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Kabar'),
                    TextSpan(text: '.', style: TextStyle(color: p.accent)),
                  ]),
                  style: AppType.display(52, color: p.ink, weight: FontWeight.w800, height: 1.05),
                ),
              ),
              CircleButton(
                icon: Icons.edit_note_rounded,
                tooltip: 'Ruang Redaksi',
                active: NewsroomScope.of(context).unlocked,
                onTap: () => openNewsroom(context),
              ),
              const SizedBox(width: 8),
              CircleButton(
                icon: dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                tooltip: dark ? 'Mode terang' : 'Mode gelap',
                onTap: () => settings.themeMode = dark ? ThemeMode.light : ThemeMode.dark,
              ),
            ],
          ),
          const SizedBox(height: 8),
          const DoubleRule(),
        ],
      ),
    );
  }
}

/// Pita "TERKINI": berganti judul setiap beberapa detik, ketuk untuk membaca.
class _BreakingTicker extends StatelessWidget {
  const _BreakingTicker({required this.future});

  final Future<List<Article>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: future,
      builder: (context, snap) {
        final items = snap.data ?? const [];
        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: items.isEmpty
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _Ticker(items: items),
                ),
        );
      },
    );
  }
}

class _Ticker extends StatefulWidget {
  const _Ticker({required this.items});

  final List<Article> items;

  @override
  State<_Ticker> createState() => _TickerState();
}

class _TickerState extends State<_Ticker> with SingleTickerProviderStateMixin {
  int _i = 0;
  Timer? _timer;
  late final _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _i = (_i + 1) % widget.items.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = widget.items[_i % widget.items.length];
    return Pressable(
      onTap: () => openArticle(context, a, heroTag: 'ticker-${a.id}'),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: p.accent.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -6,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
            Container(
              color: Colors.black.withValues(alpha: 0.2),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.center,
              child: Row(
                children: [
                  FadeTransition(
                    opacity: _pulse,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text('TERKINI', style: AppType.mono(10.5, color: Colors.white, weight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, ?current],
                  ),
                  transitionBuilder: (child, anim) {
                    final incoming = child.key == ValueKey(a.id);
                    return SlideTransition(
                      position: Tween(
                        begin: Offset(0, incoming ? 1 : -1),
                        end: Offset.zero,
                      ).animate(anim),
                      child: FadeTransition(opacity: anim, child: child),
                    );
                  },
                  child: Text(
                    a.title,
                    key: ValueKey(a.id),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.sans(14, color: Colors.white, weight: FontWeight.w600),
                  ),
                ),
              ),
            ),
            if (widget.items.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text('${_i + 1}/${widget.items.length}',
                    style: AppType.mono(10, color: Colors.white.withValues(alpha: 0.75))),
              ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCarousel extends StatelessWidget {
  const _FeaturedCarousel({required this.future});

  final Future<List<Article>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Article>>(
      future: future,
      builder: (context, snap) {
        if (snap.hasError) return const SizedBox.shrink();
        if (!snap.hasData) {
          return const Padding(
            padding: EdgeInsets.fromLTRB(20, 28, 20, 0),
            child: Shimmer(child: SkeletonBox(height: 420, radius: 24)),
          );
        }
        final items = snap.data!;
        if (items.isEmpty) return const SizedBox.shrink();
        return _Carousel(items: items);
      },
    );
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel({required this.items});

  final List<Article> items;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _controller = PageController(viewportFraction: 0.86);
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _page => _controller.hasClients && _controller.position.haveDimensions
      ? _controller.page!
      : _controller.initialPage.toDouble();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final n = widget.items.length;
    String two(int v) => v.toString().padLeft(2, '0');
    return Column(
      children: [
        SectionHeader(
          'Pilihan Redaksi',
          eyebrow: 'Sorotan hari ini',
          trailing: Text('${two(_index + 1)} / ${two(n)}', style: AppType.mono(12, color: p.muted)),
        ),
        SizedBox(
          height: 440,
          child: PageView.builder(
            controller: _controller,
            itemCount: n,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final delta = (_page - i).clamp(-1.0, 1.0);
                return Transform.scale(
                  scale: 1 - delta.abs() * 0.07,
                  child: _FeatureCard(
                    article: widget.items[i],
                    parallax: delta,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < n; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _index ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index ? p.accent : p.rule,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.article, required this.parallax});

  final Article article;
  final double parallax;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = article;
    final heroTag = 'home-feat-${a.id}';
    return Pressable(
      scale: 0.98,
      onTap: () => openArticle(context, a, heroTag: heroTag),
      child: Container(
        margin: const EdgeInsets.fromLTRB(6, 4, 6, 26),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: p.ink,
          boxShadow: [
            BoxShadow(
              color: p.shadow.withValues(alpha: (0.28 * p.shadowStrength).clamp(0, 1)),
              blurRadius: 30,
              offset: const Offset(0, 18),
              spreadRadius: -12,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Hero(
              tag: heroTag,
              child: NetImage(a.thumbnailUrl, alignment: Alignment(parallax * 0.9, 0)),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0, 0.35, 1],
                  colors: [Color(0x33000000), Color(0x00000000), Color(0xE6000000)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(99),
                  boxShadow: p.depth(0.5),
                ),
                child: CategoryKicker(a.category, size: 9.5),
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.display(25, color: Colors.white, weight: FontWeight.w700, height: 1.12),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Avatar(name: a.author.name, url: a.author.avatarUrl, size: 24),
                      const SizedBox(width: 8),
                      Expanded(
                        child: MetaLine(
                          [a.author.name, timeAgo(a.publishedAt), '${compact(a.views)} dibaca'],
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
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
