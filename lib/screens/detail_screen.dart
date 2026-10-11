import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../models/article.dart';
import '../providers/article_detail_provider.dart';
import '../providers/article_provider.dart';
import '../providers/auth_provider.dart';
import '../theme.dart';
import '../utils/format.dart';
import '../widgets/common.dart';
import 'form_screen.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  static Route<void> route(Article article) => MaterialPageRoute(
    builder: (_) => ChangeNotifierProvider(
      create: (_) => ArticleDetailProvider(article)..load(),
      child: const DetailScreen(),
    ),
  );

  Future<void> _edit(BuildContext context) async {
    final detail = context.read<ArticleDetailProvider>();
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => FormScreen(article: detail.article)),
    );
    if (saved == true) detail.load();
  }

  Future<void> _delete(BuildContext context) async {
    final article = context.read<ArticleDetailProvider>().article;
    final apiKey = context.read<AuthProvider>().apiKey!;
    final articles = context.read<ArticleProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final ok = await confirmDialog(
      context,
      title: 'Hapus artikel?',
      message: '"${article.title}" dan semua komentarnya akan dihapus.',
    );
    if (!ok) return;
    try {
      await articles.delete(article.id, apiKey);
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Artikel dihapus')));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<ArticleDetailProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final a = detail.article;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            backgroundColor: AppColors.paper,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            leading: RoundButton(
              icon: Icons.arrow_back,
              tooltip: 'Kembali',
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isAdmin) ...[
                RoundButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Ubah',
                  onPressed: detail.isLoading ? null : () => _edit(context),
                ),
                RoundButton(icon: Icons.delete_outline, tooltip: 'Hapus', onPressed: () => _delete(context)),
              ],
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(background: NetImage(a.thumbnailUrl)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CategoryLabel(a.category),
                  const SizedBox(height: 12),
                  Text(a.title, style: AppText.headline(30, weight: FontWeight.w700)),
                  if (a.summary != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.only(left: 14),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: AppColors.accent, width: 3)),
                      ),
                      child: Text(
                        a.summary!,
                        style: AppText.body(17, color: AppColors.inkSoft, style: FontStyle.italic),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Avatar(name: a.author.name, url: a.author.avatarUrl, size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.author.name, style: AppText.ui(15, weight: FontWeight.w600)),
                            Text(
                              '${timeAgo(a.publishedAt)}  ·  ${compactNumber(a.views)} dibaca',
                              style: AppText.ui(12.5, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Divider(color: AppColors.line, height: 1),
                  ),
                  if (detail.isLoading && a.content == null)
                    const Center(child: CircularProgressIndicator(color: AppColors.accent))
                  else if (detail.error != null && a.content == null)
                    ErrorView(message: detail.error!, onRetry: detail.load)
                  else
                    for (final (i, p) in a.paragraphs.indexed)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        // Paragraf pembuka sedikit lebih besar.
                        child: Text(p, style: AppText.body(i == 0 ? 19 : 17)),
                      ),
                  if (a.tags.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final t in a.tags)
                          Chip(
                            label: Text('#$t'),
                            labelStyle: AppText.ui(12.5),
                            backgroundColor: AppColors.card,
                            side: const BorderSide(color: AppColors.line),
                            shape: const StadiumBorder(),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: _Comments()),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _Comments extends StatefulWidget {
  const _Comments();

  @override
  State<_Comments> createState() => _CommentsState();
}

class _CommentsState extends State<_Comments> {
  final _name = TextEditingController();
  final _content = TextEditingController();
  bool _sending = false;
  Map<String, String> _errors = const {};

  @override
  void dispose() {
    _name.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _errors = const {};
    });
    try {
      await context.read<ArticleDetailProvider>().sendComment(_name.text, _content.text);
      _content.clear();
    } on ApiException catch (e) {
      _errors = e.errors.isEmpty ? {'content': e.message} : e.errors;
    }
    if (mounted) setState(() => _sending = false);
  }

  Future<void> _delete(int id) async {
    final detail = context.read<ArticleDetailProvider>();
    final apiKey = context.read<AuthProvider>().apiKey!;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await confirmDialog(context, title: 'Hapus komentar?', message: 'Komentar ini akan dihapus.');
    if (!ok) return;
    try {
      await detail.deleteComment(id, apiKey);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = context.watch<ArticleDetailProvider>();
    final isAdmin = context.watch<AuthProvider>().isAdmin;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Komentar', style: AppText.headline(22)),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: 'Nama', errorText: _errors['name']),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _content,
            minLines: 2,
            maxLines: 5,
            decoration: InputDecoration(labelText: 'Tulis komentar…', errorText: _errors['content']),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _sending ? null : _send, child: Text(_sending ? 'Mengirim…' : 'Kirim')),
          const SizedBox(height: 8),
          if (detail.comments.isEmpty && !detail.isLoading)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text('Belum ada komentar.', style: AppText.body(15, color: AppColors.muted)),
            ),
          for (final c in detail.comments)
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Avatar(name: c.name, size: 34),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: c.name,
                                style: AppText.ui(14, weight: FontWeight.w600),
                              ),
                              TextSpan(
                                text: '   ${timeAgo(c.createdAt)}',
                                style: AppText.ui(12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(c.content, style: AppText.body(15.5, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                  if (isAdmin)
                    IconButton(
                      tooltip: 'Hapus komentar',
                      onPressed: () => _delete(c.id),
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.accent),
                    ),
                ],
              ),
            ),
          if (detail.commentsHasNext)
            TextButton(onPressed: detail.loadMoreComments, child: const Text('Muat lebih banyak')),
        ],
      ),
    );
  }
}
