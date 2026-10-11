import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../providers/article_provider.dart';
import '../providers/author_provider.dart';

// ID kategori mengikuti data dummy di API_DOCS.md
const categories = {1: 'Teknologi', 2: 'Olahraga', 3: 'Ekonomi', 4: 'Hiburan', 5: 'Kesehatan', 6: 'Otomotif'};

/// Tambah artikel (article == null) atau edit artikel (article != null).
class ArticleFormScreen extends ConsumerStatefulWidget {
  const ArticleFormScreen({super.key, this.article});

  final Article? article;

  @override
  ConsumerState<ArticleFormScreen> createState() => _ArticleFormScreenState();
}

class _ArticleFormScreenState extends ConsumerState<ArticleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.article?.title);
  late final _summary = TextEditingController(text: widget.article?.summary);
  late final _content = TextEditingController(text: widget.article?.content);
  late final _thumbnail = TextEditingController(text: widget.article?.thumbnailUrl);
  late int _categoryId = widget.article?.categoryId ?? 1;
  late int? _authorId = widget.article?.author.id;
  bool _isSaving = false;

  bool get _isEdit => widget.article != null;

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _content.dispose();
    _thumbnail.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    // Cari objek Author yang dipilih dari data authorsProvider.
    final authors = ref.read(authorsProvider).requireValue;
    final author = authors.firstWhere((a) => a.id == _authorId);

    final article = Article(
      id: widget.article?.id ?? 0,
      title: _title.text,
      summary: _summary.text.isEmpty ? null : _summary.text,
      content: _content.text,
      thumbnailUrl: _thumbnail.text.isEmpty ? null : _thumbnail.text,
      categoryId: _categoryId,
      author: author,
    );

    try {
      final service = ref.read(articleServiceProvider);
      if (_isEdit) {
        await service.updateArticle(article);
        ref.invalidate(articleProvider(article.id)); // muat ulang detail
      } else {
        await service.createArticle(article);
      }
      ref.invalidate(articlesProvider); // muat ulang daftar
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authors = ref.watch(authorsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Artikel' : 'Tambah Artikel')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Judul', border: OutlineInputBorder()),
              validator: (value) => value!.length < 5 ? 'Judul minimal 5 karakter' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _summary,
              decoration: const InputDecoration(labelText: 'Ringkasan', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _content,
              maxLines: 8,
              decoration: const InputDecoration(labelText: 'Isi', border: OutlineInputBorder()),
              validator: (value) => value!.length < 20 ? 'Isi minimal 20 karakter' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _thumbnail,
              decoration: const InputDecoration(labelText: 'URL Gambar', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Kategori', border: OutlineInputBorder()),
              items: categories.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (value) => setState(() => _categoryId = value!),
            ),
            const SizedBox(height: 16),
            authors.when(
              loading: () => const LinearProgressIndicator(),
              error: (error, _) => Text('Gagal memuat penulis: $error'),
              data: (list) => DropdownButtonFormField<int>(
                initialValue: _authorId,
                decoration: const InputDecoration(labelText: 'Penulis', border: OutlineInputBorder()),
                items: list.map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))).toList(),
                onChanged: (value) => setState(() => _authorId = value),
                validator: (value) => value == null ? 'Pilih penulis' : null,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              // Nonaktif selama menyimpan atau daftar penulis belum siap.
              onPressed: _isSaving || !authors.hasValue ? null : _save,
              child: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
