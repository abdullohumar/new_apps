import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../navigation.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/bits.dart';
import '../widgets/cards.dart';
import '../widgets/dialogs.dart';
import '../widgets/surfaces.dart';
import 'comment_sheet.dart';

class ArticleScreen extends StatefulWidget {
  const ArticleScreen({super.key, required this.article, required this.heroTag});

  /// Versi daftar (atau versi tersimpan). Judul langsung tampil
  /// sementara isi lengkap dimuat.
  final Article article;
  final String heroTag;

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  static const _expanded = 340.0;

  final _api = NewsApi.instance;
  final _scroll = ScrollController();
  late Article _article = widget.article;
  String? _error;
  bool _collapsed = false;
  late Future<List<Article>> _related = _api.related('${widget.article.id}', limit: 6);

  final _comments = <Comment>[];
  int _commentTotal = 0;
  int _commentPage = 0;
  bool _commentsHasNext = false;
  bool _commentsLoading = true;
  String? _commentsError;

  String get _id => '${widget.article.id}';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final c = _scroll.offset > _expanded - kToolbarHeight - 24;
      if (c != _collapsed) setState(() => _collapsed = c);
    });
    _load();
    _loadComments();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final full = await _api.article(_id);
      if (!mounted) return;
      setState(() {
        _article = full;
        _error = null;
      });
      BookmarksScope.of(context).refresh(full);
    } on ApiException catch (e) {
      if (!mounted) return;
      // Kalau ada salinan tersimpan dengan isi lengkap, tetap bisa dibaca.
      final saved = BookmarksScope.of(context).find(widget.article.id);
      setState(() {
        if (saved?.content != null && _article.content == null) _article = saved!;
        _error = e.message;
      });
    }
  }

  Future<void> _loadComments({bool more = false}) async {
    if (more) {
      setState(() {
        _commentsLoading = true;
        _commentsError = null;
      });
    }
    try {
      final res = await _api.comments(_id, page: more ? _commentPage + 1 : 1, limit: 5);
      if (!mounted) return;
      setState(() {
        if (!more) _comments.clear();
        _comments.addAll(res.items);
        _commentPage = res.page;
        _commentTotal = res.total;
        _commentsHasNext = res.hasNext;
        _commentsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _commentsLoading = false;
        _commentsError = e.message;
      });
    }
  }

  Future<void> _writeComment() async {
    final comment = await showCommentSheet(context, articleId: _id, title: _article.title);
    if (comment == null || !mounted) return;
    setState(() {
      _comments.insert(0, comment);
      _commentTotal++;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tanggapanmu sudah terkirim. Terima kasih!')));
  }

  void _toggleSave() {
    final bookmarks = BookmarksScope.of(context);
    final saved = bookmarks.contains(_article.id);
    bookmarks.toggle(_article);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(saved ? 'Dihapus dari Tersimpan' : 'Disimpan untuk dibaca nanti'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _edit() async {
    final result = await openEditor(context, article: _article);
    if (result == null || !mounted) return;
    if (result.deleted) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _article = result.article!);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Perubahan tersimpan')));
  }

  Future<void> _deleteComment(Comment c) async {
    final ok = await confirm(
      context,
      title: 'Hapus komentar?',
      message: 'Komentar dari ${c.name} akan dihapus permanen.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final newsroom = NewsroomScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _api.deleteComment(newsroom.key ?? '', c.id);
      if (!mounted) return;
      setState(() {
        _comments.removeWhere((x) => x.id == c.id);
        _commentTotal--;
      });
      messenger.showSnackBar(const SnackBar(content: Text('Komentar dihapus')));
    } on ApiException catch (e) {
      if (e.statusCode == 401) newsroom.lock();
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = _article;
    final saved = BookmarksScope.of(context).contains(a.id);
    final admin = NewsroomScope.of(context).unlocked;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: CustomScrollView(
        controller: _scroll,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: _expanded,
            backgroundColor: p.paper,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            automaticallyImplyLeading: false,
            leadingWidth: 64,
            systemOverlayStyle: _collapsed && !p.isDark
                ? SystemUiOverlayStyle.dark
                : SystemUiOverlayStyle.light,
            leading: Center(
              child: CircleButton(
                icon: Icons.arrow_back_rounded,
                tooltip: 'Kembali',
                glass: !_collapsed,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
            titleSpacing: 0,
            title: AnimatedOpacity(
              opacity: _collapsed ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                a.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.display(16, color: p.ink),
              ),
            ),
            actions: [
              if (admin) ...[
                CircleButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Sunting artikel',
                  glass: !_collapsed,
                  onTap: _edit,
                ),
                const SizedBox(width: 8),
              ],
              CircleButton(
                icon: saved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                tooltip: saved ? 'Hapus dari Tersimpan' : 'Simpan',
                glass: !_collapsed,
                active: saved,
                onTap: _toggleSave,
              ),
              const SizedBox(width: 12),
            ],
            flexibleSpace: _HeaderImage(
              url: a.thumbnailUrl,
              heroTag: widget.heroTag,
              expandedHeight: _expanded,
            ),
          ),
          SliverToBoxAdapter(child: _body(p, a)),
          SliverToBoxAdapter(child: _relatedSection(p)),
          SliverToBoxAdapter(child: _commentsSection(p)),
          SliverToBoxAdapter(child: SizedBox(height: bottom + 32)),
        ],
      ),
    );
  }

  Widget _body(Palette p, Article a) {
    final paras = paragraphs(a.content);
    final updated =
        a.updatedAt != null &&
        a.publishedAt != null &&
        a.updatedAt!.difference(a.publishedAt!).inMinutes > 30;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => openCategory(context, a.category),
                child: CategoryKicker(a.category, size: 11.5),
              ),
              const Spacer(),
              if (a.isBreaking)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: p.accent,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    'TERKINI',
                    style: AppType.mono(9.5, color: Colors.white, weight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            a.title,
            style: AppType.display(30, color: p.ink, weight: FontWeight.w700, height: 1.1),
          ),
          if (a.summary != null) ...[
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 3, color: p.accent),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      a.summary!,
                      style: AppType.serif(
                        17,
                        color: p.inkSoft,
                        style: FontStyle.italic,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Pressable(
            onTap: () => openAuthor(context, a.author),
            child: Row(
              children: [
                Avatar(name: a.author.name, url: a.author.avatarUrl, size: 44, ring: p.rule),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.author.name,
                        style: AppType.sans(15, color: p.ink, weight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.author.bio ?? 'Penulis',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.sans(12.5, color: p.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: p.muted),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: p.rule)),
            ),
            child: Row(
              children: [
                if (a.publishedAt != null)
                  Expanded(
                    child: Text(
                      dateTime(a.publishedAt!).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.mono(10, color: p.muted),
                    ),
                  )
                else
                  const Spacer(),
                Icon(Icons.schedule_rounded, size: 13, color: p.muted),
                const SizedBox(width: 4),
                Text(
                  '${readingMinutes(a.content ?? a.summary)} MNT',
                  style: AppType.mono(10, color: p.muted),
                ),
                const SizedBox(width: 12),
                Icon(Icons.visibility_outlined, size: 13, color: p.muted),
                const SizedBox(width: 4),
                Text(compact(a.views).toUpperCase(), style: AppType.mono(10, color: p.muted)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (paras.isEmpty && _error != null)
            StateMessage.error(_error!, () {
              setState(() => _error = null);
              _load();
            })
          else if (paras.isEmpty)
            const _ParagraphSkeleton()
          else ...[
            DropCapParagraph(text: paras.first, style: _bodyStyle(p), capColor: p.accent),
            for (final para in paras.skip(1)) ...[
              const SizedBox(height: 18),
              Text(para, style: _bodyStyle(p)),
            ],
          ],
          if (a.tags.isNotEmpty) ...[
            const SizedBox(height: 28),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in a.tags)
                  ChoicePill(label: '#$t', selected: false, onTap: () => openTag(context, t)),
              ],
            ),
          ],
          if (updated)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Text(
                'DIPERBARUI ${dateTime(a.updatedAt!).toUpperCase()}',
                style: AppType.mono(9.5, color: p.muted),
              ),
            ),
        ],
      ),
    );
  }

  TextStyle _bodyStyle(Palette p) => AppType.serif(17.5, color: p.ink, height: 1.7);

  Widget _relatedSection(Palette p) {
    return FutureBuilder<List<Article>>(
      future: _related,
      builder: (context, snap) {
        final items = snap.data ?? const <Article>[];
        if (snap.connectionState == ConnectionState.done && items.isEmpty) {
          return const Ornament();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            SectionHeader('Baca Juga', eyebrow: 'Dari ${_article.category.name}'),
            SizedBox(
              height: 290,
              child: snap.hasData
                  ? ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: items.length,
                      itemBuilder: (context, i) =>
                          CompactCard(article: items[i], heroTag: 'related-$_id-${items[i].id}'),
                    )
                  : snap.hasError
                  ? Center(
                      child: TextButton(
                        onPressed: () => setState(() => _related = _api.related(_id, limit: 6)),
                        child: const Text('Gagal memuat — coba lagi'),
                      ),
                    )
                  : const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Shimmer(child: SkeletonBox(width: 224, height: 260, radius: 16)),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _commentsSection(Palette p) {
    final admin = NewsroomScope.of(context).unlocked;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.rule.withValues(alpha: 0.8), width: 0.8),
        boxShadow: p.depth(1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Tanggapan', style: AppType.display(22, color: p.ink)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(color: p.paper, borderRadius: BorderRadius.circular(6)),
                child: Text('$_commentTotal', style: AppType.mono(11, color: p.muted)),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _writeComment,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Tulis'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_comments.isEmpty && _commentsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Shimmer(
                child: Column(
                  children: [
                    SkeletonBox(height: 52, radius: 10),
                    SizedBox(height: 10),
                    SkeletonBox(height: 52, radius: 10),
                  ],
                ),
              ),
            )
          else if (_comments.isEmpty && _commentsError != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(_commentsError!, style: AppType.sans(13, color: p.muted)),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _commentsLoading = true;
                        _commentsError = null;
                      });
                      _loadComments();
                    },
                    child: const Text('Coba lagi'),
                  ),
                ],
              ),
            )
          else if (_comments.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Belum ada tanggapan. Jadilah yang pertama menulis.',
                style: AppType.serif(15, color: p.muted, style: FontStyle.italic),
              ),
            )
          else ...[
            for (var i = 0; i < _comments.length; i++) ...[
              if (i > 0) Divider(height: 1, color: p.rule),
              _CommentTile(
                _comments[i],
                onDelete: admin ? () => _deleteComment(_comments[i]) : null,
              ),
            ],
            if (_commentsHasNext)
              Center(
                child: _commentsLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : TextButton(
                        onPressed: () => _loadComments(more: true),
                        child: Text('Muat ${math.min(5, _commentTotal - _comments.length)} lagi'),
                      ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Foto header: parallax saat digulir, memudar ke warna kertas saat
/// menyusut, dan "bibir" melengkung di bawah agar isi terasa seperti
/// lembar yang menumpuk di atas foto.
class _HeaderImage extends StatelessWidget {
  const _HeaderImage({required this.url, required this.heroTag, required this.expandedHeight});

  final String? url;
  final String heroTag;
  final double expandedHeight;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = MediaQuery.paddingOf(context).top;
    return LayoutBuilder(
      builder: (context, c) {
        final minH = kToolbarHeight + top;
        final maxH = expandedHeight + top;
        final h = c.maxHeight;
        final t = ((h - minH) / (maxH - minH)).clamp(0.0, 1.0);
        final shift = h < maxH ? (maxH - h) * 0.45 : 0.0;
        final lip = 28 * t;

        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                top: -shift,
                left: 0,
                right: 0,
                height: math.max(h, maxH),
                child: Hero(tag: heroTag, child: NetImage(url)),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: top + 110,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x73000000), Color(0x00000000)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: p.paper.withValues(alpha: (1 - t / 0.45).clamp(0.0, 1.0)),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: -1,
                height: lip + 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: p.paper,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(lip)),
                    boxShadow: [
                      if (t > 0.05)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18 * t),
                          blurRadius: 18,
                          offset: const Offset(0, -4),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Paragraf pembuka dengan huruf awal besar setinggi tiga baris.
class DropCapParagraph extends StatelessWidget {
  const DropCapParagraph({
    super.key,
    required this.text,
    required this.style,
    required this.capColor,
  });

  final String text;
  final TextStyle style;
  final Color capColor;

  static const _lines = 3;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trimLeft();
    if (trimmed.characters.length < 2) return Text(text, style: style);
    final cap = trimmed.characters.first;
    final rest = trimmed.substring(cap.length);
    final scaler = MediaQuery.textScalerOf(context);
    final lineH = scaler.scale(style.fontSize!) * (style.height ?? 1.2);
    final capStyle = AppType.display(
      lineH * 2.45,
      color: capColor,
      weight: FontWeight.w700,
      height: 1,
    );

    // Ukur ulang saat font web selesai dimuat — metrik font cadangan berbeda.
    return ListenableBuilder(
      listenable: PaintingBinding.instance.systemFonts,
      builder: (context, _) => LayoutBuilder(
        builder: (context, c) {
          final capPainter = TextPainter(
            text: TextSpan(text: cap, style: capStyle),
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.noScaling,
          )..layout();
          final capW = capPainter.width + 10;
          final sideW = c.maxWidth - capW;
          if (sideW < 120) return Text(text, style: style);

          final tp = TextPainter(
            text: TextSpan(text: rest, style: style),
            textDirection: TextDirection.ltr,
            textScaler: scaler,
            maxLines: _lines,
          )..layout(maxWidth: sideW);
          var split = rest.length;
          if (tp.didExceedMaxLines) {
            final last = tp.computeLineMetrics().last;
            // Posisi di ujung kanan baris ke-3 = titik potong.
          split = tp.getPositionForOffset(Offset(sideW, last.baseline - 2)).offset;
          }
          tp.dispose();
          capPainter.dispose();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: capW,
                    height: lineH * _lines,
                    child: Transform.translate(
                      offset: Offset(-2, -lineH * 0.08),
                      child: Text(cap, style: capStyle, textScaler: TextScaler.noScaling),
                    ),
                  ),
                  Expanded(child: Text(rest.substring(0, split), style: style)),
                ],
              ),
              if (split < rest.length) Text(rest.substring(split).trimLeft(), style: style),
            ],
          );
        },
      ),
    );
  }
}

class _ParagraphSkeleton extends StatelessWidget {
  const _ParagraphSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < 9; i++) ...[
            SkeletonBox(width: i % 4 == 3 ? 180 : double.infinity, height: 13),
            SizedBox(height: i % 4 == 3 ? 26 : 13),
          ],
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile(this.comment, {this.onDelete});

  final Comment comment;

  /// Hanya ada saat mode redaksi aktif.
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Avatar(name: comment.name, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        comment.name,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.sans(14, color: p.ink, weight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(timeAgo(comment.createdAt), style: AppType.sans(12, color: p.muted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: AppType.serif(15.5, color: p.inkSoft, height: 1.5)),
              ],
            ),
          ),
          if (onDelete != null)
            IconButton(
              tooltip: 'Hapus komentar',
              visualDensity: VisualDensity.compact,
              onPressed: onDelete,
              icon: Icon(Icons.delete_outline_rounded, size: 20, color: p.accent),
            ),
        ],
      ),
    );
  }
}
