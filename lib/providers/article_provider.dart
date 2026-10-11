import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../services/article_service.dart';

// Service dibuat sekali, lalu dipakai provider lain.
final articleServiceProvider = Provider((ref) => ArticleService());

// Semua artikel (dipakai halaman daftar).
final articlesProvider = FutureProvider<List<Article>>((ref) {
  return ref.watch(articleServiceProvider).getArticles();
});

// Satu artikel berdasarkan id (dipakai halaman detail).
final articleProvider = FutureProvider.family<Article, int>((ref, id) {
  return ref.watch(articleServiceProvider).getArticle(id);
});
