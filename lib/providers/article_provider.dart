import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../services/article_service.dart';

// Contoh: Provider biasa untuk menyediakan service.
final articleServiceProvider = Provider((ref) => ArticleService());

// Semua artikel (dipakai halaman daftar).
final articlesProvider = FutureProvider<List<Article>>((ref) {
  // TODO: ambil service dengan ref.watch(articleServiceProvider), lalu panggil getArticles()
  throw UnimplementedError('articlesProvider belum dibuat');
});

// Satu artikel berdasarkan id (dipakai halaman detail).
// .family = provider yang menerima parameter (di sini: id).
final articleProvider = FutureProvider.family<Article, int>((ref, id) {
  // TODO: sama seperti di atas, tapi panggil getArticle(id)
  throw UnimplementedError('articleProvider belum dibuat');
});
