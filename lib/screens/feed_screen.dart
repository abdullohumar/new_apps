import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/feed.dart';
import '../core/models.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/bits.dart';
import '../widgets/feed_sliver.dart';
import '../widgets/surfaces.dart';

enum _Kind { category, author, tag }

/// Daftar artikel untuk satu rubrik, penulis, atau topik.
class FeedScreen extends StatefulWidget {
  const FeedScreen._(this._kind, {required this.title, this.category, this.author, this.tag, this.description});

  factory FeedScreen.category(CategoryRef c, {String? description}) =>
      FeedScreen._(_Kind.category, title: c.name, category: c, description: description);

  factory FeedScreen.author(AuthorRef a) =>
      FeedScreen._(_Kind.author, title: a.name, author: a, description: a.bio);

  factory FeedScreen.tag(String tag) => FeedScreen._(_Kind.tag, title: '#$tag', tag: tag);

  final _Kind _kind;
  final String title;
  final CategoryRef? category;
  final AuthorRef? author;
  final String? tag;
  final String? description;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final _feed = ArticleFeed(
    category: widget.category?.slug,
    author: widget.author?.slug,
    tag: widget.tag,
  )..refresh();
  final _scroll = ScrollController();
  bool _showTitle = false;
  String? _description;
  Author? _author;

  @override
  void initState() {
    super.initState();
    _description = widget.description;
    _scroll.addListener(() {
      final show = _scroll.offset > 110;
      if (show != _showTitle) setState(() => _showTitle = show);
    });
    _loadInfo();
  }

  Future<void> _loadInfo() async {
    try {
      if (widget._kind == _Kind.category && _description == null) {
        final c = await NewsApi.instance.category(widget.category!.slug);
        if (mounted) setState(() => _description = c.description);
      } else if (widget._kind == _Kind.author) {
        final a = await NewsApi.instance.author(widget.author!.slug);
        if (mounted) {
          setState(() {
            _author = a;
            _description = a.bio;
          });
        }
      }
    } on ApiException catch (_) {/* info tambahan saja, boleh gagal */}
  }

  @override
  void dispose() {
    _feed.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Color get _tone {
    final p = context.palette;
    return switch (widget._kind) {
      _Kind.category => p.tone(widget.category!.slug),
      _Kind.author => p.tone(widget.author!.name.toLowerCase()),
      _Kind.tag => p.accent,
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      body: PaperBackground(
        child: RefreshIndicator(
          onRefresh: _feed.refresh,
          edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
          child: CustomScrollView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: p.paper,
                surfaceTintColor: Colors.transparent,
                scrolledUnderElevation: 0,
                automaticallyImplyLeading: false,
                leadingWidth: 64,
                shape: Border(
                    bottom: BorderSide(color: _showTitle ? p.rule : Colors.transparent)),
                leading: Center(
                  child: CircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Kembali',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
                title: AnimatedOpacity(
                  opacity: _showTitle ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(widget.title, style: AppType.display(18, color: p.ink)),
                ),
              ),
              SliverToBoxAdapter(
                child: widget._kind == _Kind.author ? _authorHeader(p) : _plainHeader(p),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: ListenableBuilder(
                    listenable: _feed,
                    builder: (context, _) => Row(
                      children: [
                        Expanded(
                          child: Text(
                            _feed.page == 0 ? 'MEMUAT…' : '${_feed.total} ARTIKEL',
                            style: AppType.mono(10.5, color: p.muted),
                          ),
                        ),
                        SortToggle(
                          value: _feed.sort,
                          onChanged: (s) {
                            if (s == _feed.sort) return;
                            _feed.sort = s;
                            _feed.refresh();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              FeedSliver(
                feed: _feed,
                heroPrefix: 'feed-${identityHashCode(this)}',
                emptyTitle: 'Masih kosong',
                emptyMessage: 'Belum ada artikel terbit untuk ${widget.title}.',
              ),
              SliverToBoxAdapter(child: SizedBox(height: bottom + 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plainHeader(Palette p) {
    final tone = _tone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget._kind == _Kind.tag ? 'TOPIK' : 'RUBRIK',
              style: AppType.mono(11, color: tone, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(widget.title, style: AppType.display(44, color: p.ink, weight: FontWeight.w700, height: 1.02)),
          const SizedBox(height: 14),
          Container(
            width: 56,
            height: 5,
            decoration: BoxDecoration(color: tone, borderRadius: BorderRadius.circular(3)),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            alignment: Alignment.topLeft,
            child: _description == null
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(_description!,
                        style: AppType.serif(16.5, color: p.inkSoft, style: FontStyle.italic, height: 1.5)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _authorHeader(Palette p) {
    final a = widget.author!;
    final tone = _tone;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: p.ink, width: 1.5),
                  ),
                  child: Avatar(name: a.name, url: a.avatarUrl, size: 85),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('PENULIS', style: AppType.mono(11, color: tone, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(a.name, style: AppType.display(36, color: p.ink, weight: FontWeight.w700, height: 1.05)),
          if (_description != null) ...[
            const SizedBox(height: 10),
            Text(_description!,
                style: AppType.serif(16.5, color: p.inkSoft, style: FontStyle.italic, height: 1.5)),
          ],
          if (_author != null) ...[
            const SizedBox(height: 12),
            Text('${_author!.articleCount} TULISAN TERBIT',
                style: AppType.mono(10.5, color: p.muted)),
          ],
        ],
      ),
    );
  }
}
