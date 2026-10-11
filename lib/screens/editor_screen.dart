import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/format.dart';
import '../core/models.dart';
import '../core/store.dart';
import '../theme/palette.dart';
import '../theme/type.dart';
import '../widgets/bits.dart';
import '../widgets/dialogs.dart';
import '../widgets/surfaces.dart';

/// Hasil editor: artikel tersimpan, atau `deleted` bila artikel dihapus.
class EditorResult {
  const EditorResult.saved(Article this.article) : deleted = false;
  const EditorResult.deleted() : article = null, deleted = true;

  final Article? article;
  final bool deleted;
}

class ArticleEditorScreen extends StatefulWidget {
  const ArticleEditorScreen({super.key, this.initial});

  /// `null` = artikel baru.
  final Article? initial;

  @override
  State<ArticleEditorScreen> createState() => _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends State<ArticleEditorScreen> {
  final _api = NewsApi.instance;
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _content = TextEditingController();
  final _thumb = TextEditingController();
  final _slug = TextEditingController();
  final _tagInput = TextEditingController();
  final _tags = <String>[];
  int? _categoryId;
  int? _authorId;
  bool _featured = false;
  bool _breaking = false;
  String _status = 'published';

  /// Versi lengkap artikel yang sedang disunting (pembanding untuk PUT).
  Article? _source;
  bool _loading = false;
  String? _loadError;
  bool _saving = false;
  bool _dirty = false;
  bool _filling = false;
  Map<String, String> _serverErrors = const {};
  String? _banner;

  late final Future<List<NewsCategory>> _categories = _api.categories();
  late final Future<List<Author>> _authors = _api.authors();

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    for (final c in [_title, _summary, _content, _thumb, _slug]) {
      c.addListener(_markDirty);
    }
    final initial = widget.initial;
    if (initial != null) {
      initial.content != null ? _fill(initial) : _fetchFull();
    }
  }

  @override
  void dispose() {
    for (final c in [_title, _summary, _content, _thumb, _slug, _tagInput]) {
      c.dispose();
    }
    super.dispose();
  }

  void _markDirty() {
    if (!_filling && !_dirty) setState(() => _dirty = true);
  }

  void _change(VoidCallback fn) => setState(() {
        fn();
        _dirty = true;
      });

  /// Versi daftar tidak membawa `content`, jadi ambil detailnya dulu.
  /// (Catatan: GET detail ikut menambah `views` artikel sebanyak 1.)
  Future<void> _fetchFull() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final full = await _api.article('${widget.initial!.id}');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _fill(full);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  void _fill(Article a) {
    _filling = true;
    _source = a;
    _title.text = a.title;
    _summary.text = a.summary ?? '';
    _content.text = a.content ?? '';
    _thumb.text = a.thumbnailUrl ?? '';
    _slug.text = a.slug;
    _tags
      ..clear()
      ..addAll(a.tags);
    _categoryId = a.category.id;
    _authorId = a.author.id;
    _featured = a.isFeatured;
    _breaking = a.isBreaking;
    _status = a.status ?? 'published';
    _filling = false;
    _dirty = false;
  }

  String? _nullIfEmpty(String s) => s.trim().isEmpty ? null : s.trim();

  Map<String, Object?> _fields() => {
        'title': _title.text.trim(),
        'summary': _nullIfEmpty(_summary.text),
        'content': _content.text.trim(),
        'thumbnail_url': _nullIfEmpty(_thumb.text),
        'category_id': _categoryId,
        'author_id': _authorId,
        'tags': List.of(_tags),
        'is_featured': _featured,
        'is_breaking': _breaking,
        'status': _status,
        if (_slug.text.trim().isNotEmpty) 'slug': _slug.text.trim(),
      };

  Map<String, Object?> _fieldsOf(Article a) => {
        'title': a.title.trim(),
        'summary': _nullIfEmpty(a.summary ?? ''),
        'content': (a.content ?? '').trim(),
        'thumbnail_url': _nullIfEmpty(a.thumbnailUrl ?? ''),
        'category_id': a.category.id,
        'author_id': a.author.id,
        'tags': a.tags,
        'is_featured': a.isFeatured,
        'is_breaking': a.isBreaking,
        'status': a.status ?? 'published',
        'slug': a.slug,
      };

  Map<String, Object?> _changes() {
    final now = _fields();
    final before = _fieldsOf(_source!);
    return {
      for (final e in now.entries)
        if (!(e.value is List && before[e.key] is List
            ? listEquals(e.value as List, before[e.key] as List)
            : e.value == before[e.key]))
          e.key: e.value,
    };
  }

  Future<void> _save() async {
    setState(() {
      _serverErrors = const {};
      _banner = null;
    });
    final valid = _form.currentState!.validate();
    if (_categoryId == null || _authorId == null) {
      setState(() => _banner = 'Pilih rubrik dan penulis terlebih dahulu.');
      return;
    }
    if (!valid) return;

    final payload = _editing ? _changes() : _fields();
    if (_editing && payload.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Tidak ada perubahan untuk disimpan.')));
      return;
    }

    final newsroom = NewsroomScope.of(context);
    final bookmarks = BookmarksScope.of(context);
    setState(() => _saving = true);
    try {
      final key = newsroom.key ?? '';
      final result = _editing
          ? await _api.updateArticle(key, widget.initial!.id, payload)
          : await _api.createArticle(key, payload);
      newsroom.remember(result);
      bookmarks.refresh(result);
      if (!mounted) return;
      _dirty = false;
      Navigator.of(context).pop(EditorResult.saved(result));
    } on ApiException catch (e) {
      if (!mounted) return;
      final errors = Map.of(e.errors);
      if (e.statusCode == 409) errors['slug'] = e.message;
      String? banner;
      if (e.statusCode == 401) {
        newsroom.lock();
        banner = 'Key admin ditolak server. Masuk ulang di Ruang Redaksi.';
      } else if (errors.containsKey('category_id') || errors.containsKey('author_id')) {
        banner = [errors['category_id'], errors['author_id']].whereType<String>().join('\n');
      }
      setState(() {
        _saving = false;
        _serverErrors = errors;
        _banner = banner ?? (errors.isEmpty ? e.message : 'Periksa kembali isian yang ditandai.');
      });
      _form.currentState!.validate();
    }
  }

  Future<void> _delete() async {
    final a = _source ?? widget.initial!;
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
    setState(() => _saving = true);
    try {
      await _api.deleteArticle(newsroom.key ?? '', a.id);
      bookmarks.remove(a.id);
      newsroom.forget(a.id);
      if (!mounted) return;
      _dirty = false;
      Navigator.of(context).pop(const EditorResult.deleted());
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) newsroom.lock();
      setState(() {
        _saving = false;
        _banner = e.message;
      });
    }
  }

  Future<void> _confirmLeave() async {
    final leave = await confirm(
      context,
      title: 'Buang perubahan?',
      message: 'Isian yang belum disimpan akan hilang.',
      confirmLabel: 'Buang',
      destructive: true,
    );
    if (leave && mounted) Navigator.of(context).pop();
  }

  void _addTag(String raw) {
    final tag = slugify(raw);
    if (tag.isEmpty) return;
    _change(() {
      if (!_tags.contains(tag)) _tags.add(tag);
      _tagInput.clear();
    });
  }

  void _randomImage() {
    final seed = slugify(_title.text).isNotEmpty ? slugify(_title.text) : 'kabar';
    _thumb.text =
        'https://picsum.photos/seed/$seed-${math.Random().nextInt(9999)}/800/450';
  }

  String? _check(String field, String? v, {int min = 0, int? max, bool required = true}) {
    if (_serverErrors[field] case final msg?) return msg;
    final len = (v ?? '').trim().length;
    if (len == 0) return required ? 'Wajib diisi' : null;
    if (len < min) return 'Minimal $min karakter';
    if (max != null && len > max) return 'Maksimal $max karakter';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return PopScope(
      canPop: !_dirty || _saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmLeave();
      },
      child: Scaffold(
        body: PaperBackground(
          child: SafeArea(
            child: Column(
              children: [
                _topBar(p),
                Expanded(child: _body(p)),
                if (!_loading && _loadError == null) _saveBar(p),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(Palette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          CircleButton(
            icon: Icons.close_rounded,
            tooltip: 'Tutup',
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editing ? 'SUNTING · #${widget.initial!.id}' : 'NASKAH BARU',
                  style: AppType.mono(10, color: p.accent, weight: FontWeight.w600),
                ),
                Text(_editing ? 'Sunting Artikel' : 'Tulis Artikel',
                    style: AppType.display(21, color: p.ink)),
              ],
            ),
          ),
          if (_editing)
            CircleButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Hapus artikel',
              onTap: _saving ? () {} : _delete,
            ),
        ],
      ),
    );
  }

  Widget _body(Palette p) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_loadError != null) {
      return Center(child: StateMessage.error(_loadError!, _fetchFull));
    }
    final bodyStyle = AppType.serif(16, color: p.ink, height: 1.6);
    return Form(
      key: _form,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          if (_banner != null) _Banner(_banner!),
          _Section(
            title: 'Naskah',
            children: [
              TextFormField(
                controller: _title,
                enabled: !_saving,
                maxLines: null,
                maxLength: 200,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.display(20, color: p.ink),
                decoration: const InputDecoration(labelText: 'Judul', counterText: ''),
                validator: (v) => _check('title', v, min: 5, max: 200),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _summary,
                enabled: !_saving,
                minLines: 2,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                style: AppType.serif(15, color: p.inkSoft, style: FontStyle.italic, height: 1.5),
                decoration: const InputDecoration(
                  labelText: 'Ringkasan (opsional)',
                  alignLabelWithHint: true,
                ),
                validator: (v) => _check('summary', v, required: false),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _content,
                enabled: !_saving,
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: bodyStyle,
                decoration: const InputDecoration(
                  labelText: 'Isi artikel',
                  alignLabelWithHint: true,
                  helperText: 'Pisahkan paragraf dengan satu baris kosong.',
                ),
                validator: (v) => _check('content', v, min: 20),
              ),
              ValueListenableBuilder(
                valueListenable: _content,
                builder: (context, value, _) => Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    '${paragraphs(value.text).length} PARAGRAF · '
                    '${value.text.trim().isEmpty ? 0 : value.text.trim().split(RegExp(r'\s+')).length} KATA · '
                    '±${readingMinutes(value.text)} MNT BACA',
                    style: AppType.mono(9.5, color: p.muted),
                  ),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Gambar sampul',
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ValueListenableBuilder(
                    valueListenable: _thumb,
                    builder: (context, v, _) => NetImage(_nullIfEmpty(v.text)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _thumb,
                      enabled: !_saving,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(labelText: 'URL gambar (opsional)'),
                      validator: (v) {
                        if (_serverErrors['thumbnail_url'] case final m?) return m;
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return null;
                        final uri = Uri.tryParse(t);
                        return uri != null && uri.hasScheme && uri.host.isNotEmpty
                            ? null
                            : 'URL tidak valid';
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: CircleButton(
                      icon: Icons.casino_outlined,
                      tooltip: 'Gambar acak',
                      onTap: _randomImage,
                    ),
                  ),
                ],
              ),
            ],
          ),
          _Section(
            title: 'Rubrik',
            children: [
              FutureBuilder<List<NewsCategory>>(
                future: _categories,
                builder: (context, snap) => _picker(
                  snap,
                  (c) => ChoicePill(
                    label: c.name,
                    dot: p.tone(c.slug),
                    selected: _categoryId == c.id,
                    onTap: () => _change(() => _categoryId = c.id),
                  ),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Penulis',
            children: [
              FutureBuilder<List<Author>>(
                future: _authors,
                builder: (context, snap) => _picker(
                  snap,
                  (a) => ChoicePill(
                    label: a.name,
                    dot: p.tone(a.name.toLowerCase()),
                    selected: _authorId == a.id,
                    onTap: () => _change(() => _authorId = a.id),
                  ),
                ),
              ),
            ],
          ),
          _Section(
            title: 'Tag',
            children: [
              TextField(
                controller: _tagInput,
                enabled: !_saving,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Tambah tag',
                  hintText: 'mis. pendidikan, lalu Enter',
                  suffixIcon: IconButton(
                    tooltip: 'Tambah',
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => _addTag(_tagInput.text),
                  ),
                ),
                onChanged: (v) {
                  if (v.endsWith(',')) _addTag(v.substring(0, v.length - 1));
                },
                onSubmitted: _addTag,
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in _tags)
                      ChoicePill(
                        label: '#$t  ✕',
                        selected: true,
                        onTap: () => _change(() => _tags.remove(t)),
                      ),
                  ],
                ),
              ],
            ],
          ),
          _Section(
            title: 'Penerbitan',
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Status', style: AppType.sans(14.5, color: p.ink, weight: FontWeight.w600)),
                  ),
                  _StatusToggle(
                    value: _status,
                    onChanged: (s) => _change(() => _status = s),
                  ),
                ],
              ),
              if (_status == 'draft')
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Draf tidak tampil di aplikasi pembaca dan tidak bisa diambil lagi dari API. '
                    'Kabar mencatatnya di perangkat ini supaya tetap bisa disunting.',
                    style: AppType.sans(12.5, color: p.muted, height: 1.45),
                  ),
                ),
              const SizedBox(height: 6),
              _SwitchRow(
                title: 'Pilihan Redaksi',
                subtitle: 'Tampil di carousel beranda',
                value: _featured,
                onChanged: (v) => _change(() => _featured = v),
              ),
              _SwitchRow(
                title: 'Terkini',
                subtitle: 'Tampil di pita breaking news',
                value: _breaking,
                onChanged: (v) => _change(() => _breaking = v),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _slug,
                enabled: !_saving,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: 'Slug (opsional)',
                  helperText: _editing
                      ? 'Mengubah judul tidak mengubah slug otomatis.'
                      : 'Kosongkan untuk dibuat otomatis dari judul.',
                  helperMaxLines: 2,
                ),
                validator: (v) => _check('slug', v, required: false),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _picker<T>(AsyncSnapshot<List<T>> snap, Widget Function(T) pill) {
    if (snap.hasError) {
      return Text('Gagal memuat: ${snap.error}',
          style: AppType.sans(13, color: context.palette.muted));
    }
    if (!snap.hasData) {
      return const Shimmer(child: SkeletonBox(height: 36, radius: 18));
    }
    return Wrap(spacing: 8, runSpacing: 8, children: [for (final x in snap.data!) pill(x)]);
  }

  Widget _saveBar(Palette p) {
    final label = _editing
        ? 'Simpan perubahan'
        : _status == 'draft'
            ? 'Simpan sebagai draf'
            : 'Terbitkan';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: p.card,
        border: Border(top: BorderSide(color: p.rule)),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: (0.06 * p.shadowStrength).clamp(0, 1)),
            blurRadius: 16,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: p.accent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: p.accent.withValues(alpha: 0.5),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          icon: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Icon(_status == 'draft' ? Icons.save_outlined : Icons.send_rounded, size: 18),
          label: Text(label),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.rule.withValues(alpha: 0.8), width: 0.8),
        boxShadow: p.depth(0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title.toUpperCase(), style: AppType.mono(10.5, color: p.muted, weight: FontWeight.w600)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: p.accent, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppType.sans(13.5, color: p.ink, height: 1.4))),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppType.sans(14.5, color: p.ink, weight: FontWeight.w600)),
                  Text(subtitle, style: AppType.sans(12.5, color: p.muted)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _StatusToggle extends StatelessWidget {
  const _StatusToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.rule),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (status, label) in const [('published', 'Terbit'), ('draft', 'Draf')])
            GestureDetector(
              onTap: () => onChanged(status),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: status == value
                      ? (status == 'draft' ? p.ink : p.accent)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  label,
                  style: AppType.sans(13,
                      weight: FontWeight.w600,
                      color: status == value
                          ? (status == 'draft' ? p.paper : Colors.white)
                          : p.muted),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
