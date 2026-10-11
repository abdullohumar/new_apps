import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/article_provider.dart';
import 'article_detail_screen.dart';
import 'article_form_screen.dart';

class ArticleListScreen extends ConsumerWidget {
  const ArticleListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final articles = ref.watch(articlesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Kabar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticleFormScreen())),
        child: const Icon(Icons.add),
      ),
      body: articles.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$error'),
              TextButton(onPressed: () => ref.invalidate(articlesProvider), child: const Text('Coba lagi')),
            ],
          ),
        ),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.refresh(articlesProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final article = list[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: article.thumbnailUrl == null
                        ? const SizedBox(width: 64, height: 64)
                        : Image.network(article.thumbnailUrl!, width: 64, height: 64, fit: BoxFit.cover),
                  ),
                  title: Text(article.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${article.categoryName} · ${article.author.name}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ArticleDetailScreen(id: article.id)),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
