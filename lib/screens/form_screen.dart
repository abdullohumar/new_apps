import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';

/// Form buat artikel baru, atau ubah bila [article] diisi.
class FormScreen extends StatefulWidget {
  const FormScreen({super.key, this.article});

  final Article? article;

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.article?.title);
  late final _summary = TextEditingController(text: widget.article?.summary);
  late final _content = TextEditingController(text: widget.article?.content);
  late final _thumbnail = TextEditingController(text: widget.article?.thumbnailUrl);
  late final _tags = TextEditingController(text: widget.article?.tags.join(', '));
  late int? _categoryId = widget.article?.category.id;
  late int? _authorId = widget.article?.author.id;
  late bool _featured = widget.article?.isFeatured ?? false;
  late bool _breaking = widget.article?.isBreaking ?? false;
  late bool _draft = widget.article?.status == 'draft';

  bool _saving = false;
  Map<String, String> _errors = const {};

  bool get _isEdit => widget.article != null;

  @override
  void dispose() {
    for (final c in [_title, _summary, _content, _thumbnail, _tags]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _optional(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    setState(() => _errors = const {});
    if (!_formKey.currentState!.validate()) return;

    final body = <String, Object?>{
      'title': _title.text.trim(),
      'summary': _optional(_summary),
      'content': _content.text.trim(),
      'thumbnail_url': _optional(_thumbnail),
      'category_id': _categoryId,
      'author_id': _authorId,
      'tags': _tags.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
      'is_featured': _featured,
      'is_breaking': _breaking,
      'status': _draft ? 'draft' : 'published',
    };

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    try {
      await context.read<ArticleProvider>().save(
        body,
        context.read<AuthProvider>().apiKey!,
        id: widget.article?.id,
      );
      navigator.pop(true);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _draft
                ? 'Draf tersimpan. Draf tidak tampil di daftar publik.'
                : _isEdit
                ? 'Artikel diperbarui'
                : 'Artikel terbit',
          ),
        ),
      );
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _errors = e.errors;
      });
      _formKey.currentState!.validate();
      if (e.errors.isEmpty) messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Validasi lokal sesuai aturan API; error dari server diutamakan.
  String? Function(String?) _rule(String field, {int min = 0, int? max}) => (value) {
    if (_errors[field] case final error?) return error;
    final length = (value ?? '').trim().length;
    if (min > 0 && length < min) return 'Minimal $min karakter';
    if (max != null && length > max) return 'Maksimal $max karakter';
    return null;
  };

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ArticleProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        title: Text(_isEdit ? 'Ubah Artikel' : 'Tulis Artikel', style: AppText.headline(20)),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
          children: [
            TextFormField(
              controller: _title,
              style: AppText.headline(18),
              maxLines: null,
              decoration: const InputDecoration(labelText: 'Judul'),
              validator: _rule('title', min: 5, max: 200),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _summary,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Ringkasan (opsional)'),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _content,
              minLines: 8,
              maxLines: null,
              style: AppText.body(16),
              decoration: const InputDecoration(
                labelText: 'Isi artikel',
                alignLabelWithHint: true,
                helperText: 'Pisahkan paragraf dengan satu baris kosong.',
              ),
              validator: _rule('content', min: 20),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _thumbnail,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(labelText: 'URL gambar (opsional)'),
              validator: _rule('thumbnail_url'),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategori'),
              items: [
                for (final c in provider.categories) DropdownMenuItem(value: c.id, child: Text(c.name)),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
              validator: (v) => _errors['category_id'] ?? (v == null ? 'Pilih kategori' : null),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<int>(
              initialValue: _authorId,
              decoration: const InputDecoration(labelText: 'Penulis'),
              items: [for (final a in provider.authors) DropdownMenuItem(value: a.id, child: Text(a.name))],
              onChanged: (v) => setState(() => _authorId = v),
              validator: (v) => _errors['author_id'] ?? (v == null ? 'Pilih penulis' : null),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _tags,
              decoration: const InputDecoration(labelText: 'Tag', hintText: 'pisahkan dengan koma'),
            ),
            const SizedBox(height: 10),
            _Toggle('Artikel pilihan', _featured, (v) => setState(() => _featured = v)),
            _Toggle('Breaking news', _breaking, (v) => setState(() => _breaking = v)),
            _Toggle('Simpan sebagai draf', _draft, (v) => setState(() => _draft = v)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            child: Text(_saving ? 'Menyimpan…' : (_isEdit ? 'Simpan Perubahan' : 'Terbitkan')),
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle(this.label, this.value, this.onChanged);

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(label, style: AppText.ui(15)),
    value: value,
    onChanged: onChanged,
  );
}
