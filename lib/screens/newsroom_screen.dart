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
import '../widgets/dialogs.dart';
import '../widgets/surfaces.dart';

/// Ruang Redaksi: CRUD artikel lewat endpoint admin.
class NewsroomScreen extends StatelessWidget {
  const NewsroomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final unlocked = NewsroomScope.of(context).unlocked;
    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: unlocked ? const _Desk(key: ValueKey('desk')) : const _Unlock(key: ValueKey('lock')),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ kunci

class _Unlock extends StatefulWidget {
  const _Unlock({super.key});

  @override
  State<_Unlock> createState() => _UnlockState();
}

class _UnlockState extends State<_Unlock> {
  final _key = TextEditingController();
  bool _obscure = true;
  bool _checking = false;
  String? _error;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final key = _key.text.trim();
    if (key.isEmpty) {
      setState(() => _error = 'Masukkan ADMIN_API_KEY.');
      return;
    }
    final newsroom = NewsroomScope.of(context);
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final ok = await NewsApi.instance.verifyAdminKey(key);
      if (!mounted) return;
      if (ok) {
        newsroom.unlock(key);
      } else {
        setState(() {
          _checking = false;
          _error = 'Key ditolak server (401). Periksa lagi nilainya.';
        });
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: CircleButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Kembali',
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            children: [
              Positioned(
                left: 8,
                top: 8,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(color: p.accent, borderRadius: BorderRadius.circular(22)),
                ),
              ),
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: p.ink, width: 1.4),
                ),
                child: Icon(Icons.key_rounded, size: 32, color: p.ink),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text('KHUSUS REDAKSI', style: AppType.mono(11, color: p.accent, weight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Ruang\nRedaksi',
            style: AppType.display(44, color: p.ink, weight: FontWeight.w800, height: 1.02)),
        const SizedBox(height: 12),
        Text(
          'Tulis, sunting, terbitkan, dan hapus artikel. Butuh ADMIN_API_KEY '
          'dari Supabase Dashboard → Edge Functions → Secrets.',
          style: AppType.serif(16, color: p.inkSoft, height: 1.5),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border(left: BorderSide(color: p.accent, width: 3)),
          ),
          child: Text(
            'Key disimpan hanya di perangkat ini dan tidak ditanam di kode aplikasi. '
            'Tetap jangan pakai mode ini di build yang dibagikan ke publik.',
            style: AppType.sans(13, color: p.muted, height: 1.45),
          ),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _key,
          enabled: !_checking,
          obscureText: _obscure,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) => _submit(),
          style: AppType.mono(14, color: p.ink),
          decoration: InputDecoration(
            labelText: 'x-api-key',
            errorText: _error,
            errorMaxLines: 3,
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Tampilkan' : 'Sembunyikan',
              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _checking ? null : _submit,
          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          child: _checking
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: p.paper),
                )
              : const Text('Buka Ruang Redaksi'),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ meja

class _Desk extends StatefulWidget {
  const _Desk({super.key});

  @override
  State<_Desk> createState() => _DeskState();
}

class _DeskState extends State<_Desk> {
  final _published = ArticleFeed(pageSize: 15)..refresh();
  final _search = TextEditingController();
  Timer? _debounce;
  int? _revision;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rev = NewsroomScope.of(context).revision;
    if (_revision != null && rev != _revision) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _published.refresh());
    }
    _revision = rev;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _published.dispose();
    super.dispose();
  }

  void _onSearch(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _published.search = q.trim();
      _published.refresh();
    });
  }

  Future<void> _create() async {
    final result = await openEditor(context);
    final a = result?.article;
    if (a == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(a.isDraft ? 'Draf tersimpan' : 'Artikel terbit'),
      action: a.isDraft
          ? null
          : SnackBarAction(
              label: 'LIHAT',
              onPressed: () => openArticle(context, a, heroTag: 'newsroom-new-${a.id}'),
            ),
    ));
  }

  Future<void> _edit(Article a) async {
    final result = await openEditor(context, article: a);
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(result.deleted ? 'Artikel dihapus' : 'Perubahan tersimpan'),
    ));
  }

  Future<void> _delete(Article a) async {
    final ok = await confirm(
      context,
      title: 'Hapus artikel?',
      message: '“${a.title}” beserta semua komentarnya akan dihapus permanen.',
      confirmLabel: 'Hapus',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final newsroom = NewsroomScope.of(context);
    final bookmarks = BookmarksScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NewsApi.instance.deleteArticle(newsroom.key ?? '', a.id);
      bookmarks.remove(a.id);
      newsroom.forget(a.id);
      messenger.showSnackBar(const SnackBar(content: Text('Artikel dihapus')));
    } on ApiException catch (e) {
      if (e.statusCode == 401) newsroom.lock();
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _lock() async {
    final ok = await confirm(
      context,
      title: 'Keluar dari Redaksi?',
      message: 'Key admin dihapus dari perangkat ini. Draf lokal tetap tersimpan.',
      confirmLabel: 'Keluar',
    );
    if (ok && mounted) NewsroomScope.of(context).lock();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final drafts = NewsroomScope.of(context).drafts;
    final bottom = MediaQuery.paddingOf(context).bottom;

    return RefreshIndicator(
      onRefresh: _published.refresh,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  CircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Kembali',
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  CircleButton(icon: Icons.lock_outline_rounded, tooltip: 'Keluar', onTap: _lock),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(color: Color(0xFF2EAD5B), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 7),
                      Text('RUANG REDAKSI · TERHUBUNG',
                          style: AppType.mono(10.5, color: p.muted, weight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Meja Kerja',
                      style: AppType.display(44, color: p.ink, weight: FontWeight.w800, height: 1.02)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ListenableBuilder(
                          listenable: _published,
                          builder: (context, _) => _Stat(
                            value: _published.page == 0 ? '—' : '${_published.total}',
                            label: _published.search?.isNotEmpty == true ? 'COCOK' : 'TERBIT',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: _Stat(value: '${drafts.length}', label: 'DRAF LOKAL')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _NewArticleCard(onTap: _create),
                ],
              ),
            ),
          ),
          if (drafts.isNotEmpty) ...[
            const SliverToBoxAdapter(child: SectionHeader('Draf', eyebrow: 'Belum terbit')),
            SliverList.builder(
              itemCount: drafts.length,
              itemBuilder: (context, i) => _AdminRow(
                article: drafts[i],
                onEdit: () => _edit(drafts[i]),
                onDelete: () => _delete(drafts[i]),
              ),
            ),
          ],
          const SliverToBoxAdapter(child: SectionHeader('Terbit', eyebrow: 'Tampil di aplikasi')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: TextField(
                controller: _search,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Cari artikel…',
                  prefixIcon: const Icon(Icons.search_rounded),
                  fillColor: p.card,
                ),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _published,
            builder: (context, _) {
              final items = _published.items;
              if (items.isEmpty) {
                return SliverToBoxAdapter(
                  child: _published.error != null
                      ? StateMessage.error(_published.error!, _published.retry)
                      : _published.loading || _published.hasNext
                          ? const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : const StateMessage(
                              icon: Icons.inbox_outlined,
                              title: 'Tidak ada artikel',
                              message: 'Belum ada artikel terbit yang cocok.',
                            ),
                );
              }
              return SliverList.builder(
                itemCount: items.length + 1,
                itemBuilder: (context, i) {
                  if (i >= items.length - 3) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _published.loadMore());
                  }
                  if (i == items.length) {
                    return _published.hasNext
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : const Ornament();
                  }
                  final a = items[i];
                  return _AdminRow(
                    article: a,
                    onEdit: () => _edit(a),
                    onOpen: () => openArticle(context, a, heroTag: 'newsroom-${a.id}'),
                    onDelete: () => _delete(a),
                  );
                },
              );
            },
          ),
          SliverToBoxAdapter(child: SizedBox(height: bottom + 32)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.rule.withValues(alpha: 0.8), width: 0.8),
        boxShadow: p.depth(0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppType.display(30, color: p.ink, weight: FontWeight.w800, height: 1)),
          const SizedBox(height: 4),
          Text(label, style: AppType.mono(9.5, color: p.muted)),
        ],
      ),
    );
  }
}

class _NewArticleCard extends StatelessWidget {
  const _NewArticleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.ink,
          borderRadius: BorderRadius.circular(20),
          boxShadow: p.depth(1.6),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tulis artikel baru',
                      style: AppType.display(22, color: p.paper, weight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Terbitkan langsung atau simpan sebagai draf.',
                      style: AppType.sans(13, color: p.paper.withValues(alpha: 0.65))),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: p.accent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: p.accent.withValues(alpha: 0.45),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.edit_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminRow extends StatelessWidget {
  const _AdminRow({required this.article, required this.onEdit, required this.onDelete, this.onOpen});

  final Article article;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final a = article;
    Widget badge(String text, Color color) => Container(
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(text, style: AppType.mono(8.5, color: color, weight: FontWeight.w700)),
        );

    return Pressable(
      onTap: onEdit,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
        padding: const EdgeInsets.fromLTRB(10, 10, 4, 10),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: a.isDraft ? p.ink.withValues(alpha: 0.5) : p.rule.withValues(alpha: 0.8),
            width: a.isDraft ? 1.2 : 0.8,
          ),
          boxShadow: p.depth(0.6),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(width: 60, height: 60, child: NetImage(a.thumbnailUrl)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (a.isDraft) badge('DRAF', p.ink),
                      if (a.isFeatured) badge('PILIHAN', p.tone('teknologi')),
                      if (a.isBreaking) badge('TERKINI', p.accent),
                      Flexible(child: CategoryKicker(a.category, size: 8.5)),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(a.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppType.display(15, color: p.ink, height: 1.2)),
                  const SizedBox(height: 4),
                  MetaLine([
                    '#${a.id}',
                    a.isDraft ? timeAgo(a.updatedAt) : timeAgo(a.publishedAt),
                    if (!a.isDraft) '${compact(a.views)} dibaca',
                  ], size: 10.5),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Aksi',
              icon: Icon(Icons.more_vert_rounded, color: p.muted),
              onSelected: (v) => switch (v) {
                'edit' => onEdit(),
                'open' => onOpen?.call(),
                _ => onDelete(),
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Sunting')),
                if (onOpen != null) const PopupMenuItem(value: 'open', child: Text('Lihat')),
                PopupMenuItem(
                  value: 'delete',
                  child: Text('Hapus', style: TextStyle(color: p.accent)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
