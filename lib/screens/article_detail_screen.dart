import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../models/author.dart';
import '../providers/article_provider.dart';
import '../providers/comment_provider.dart';
import 'article_form_screen.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.id});

  final int id;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus artikel?'),
        content: const Text('Artikel yang dihapus tidak bisa dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (yes != true) return;

    try {
      await ref.read(articleServiceProvider).deleteArticle(id);
      ref.invalidate(articlesProvider); // muat ulang daftar
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleProvider(id));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (article.hasValue) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ArticleFormScreen(article: article.value)),
              ),
            ),
            IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(context, ref)),
          ],
        ],
      ),
      body: article.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
        data: (article) => _ArticleBody(article),
      ),
    );
  }
}

class _ArticleBody extends StatelessWidget {
  const _ArticleBody(this.article);

  final Article article;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return ListView(
      children: [
        if (article.thumbnailUrl != null)
          Image.network(article.thumbnailUrl!, height: 220, fit: BoxFit.cover),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                article.categoryName.toUpperCase(),
                style: text.labelMedium?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 8),
              Text(article.title, style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              if (article.summary != null) ...[
                const SizedBox(height: 16),
                Text(article.summary!, style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 16),
              _AuthorCard(article.author),
              const Divider(height: 32),
              Text(article.content ?? '', style: text.bodyLarge?.copyWith(height: 1.6)),
              const Divider(height: 48),
              _CommentSection(articleId: article.id),
            ],
          ),
        ),
      ],
    );
  }
}

class _AuthorCard extends StatelessWidget {
  const _AuthorCard(this.author);

  final Author author;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: author.avatarUrl == null ? null : NetworkImage(author.avatarUrl!),
          child: author.avatarUrl == null ? Text(author.name[0]) : null,
        ),
        title: Text(author.name),
        subtitle: Text(author.bio ?? 'Penulis'),
      ),
    );
  }
}

class _CommentSection extends ConsumerStatefulWidget {
  const _CommentSection({required this.articleId});

  final int articleId;

  @override
  ConsumerState<_CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends ConsumerState<_CommentSection> {
  final _name = TextEditingController();
  final _content = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _name.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _isSending = true);
    try {
      await ref.read(commentServiceProvider).addComment(widget.articleId, _name.text, _content.text);
      _content.clear();
      ref.invalidate(commentsProvider(widget.articleId)); // muat ulang komentar
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.articleId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Komentar', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        comments.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Text('$error'),
          data: (list) => list.isEmpty
              ? const Text('Belum ada komentar.')
              : Column(
                  children: list
                      .map(
                        (comment) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(child: Text(comment.name[0].toUpperCase())),
                          title: Text(comment.name),
                          subtitle: Text(comment.content),
                          trailing: Text(
                            '${comment.createdAt.day}/${comment.createdAt.month}/${comment.createdAt.year}',
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _content,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Tulis komentar', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _isSending ? null : _send,
          child: Text(_isSending ? 'Mengirim...' : 'Kirim Komentar'),
        ),
      ],
    );
  }
}
