import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/article.dart';
import '../models/author.dart';
import '../models/category.dart';
import '../services/article_service.dart';
import '../services/reference_service.dart';

/// Beranda: artikel pilihan, daftar artikel (pagination + filter kategori),
/// data kategori/penulis, serta aksi CRUD artikel.
class ArticleProvider extends ChangeNotifier {
  final _service = ArticleService();
  final _references = ReferenceService();

  List<Article> featured = [];
  List<Article> articles = [];
  List<NewsCategory> categories = [];
  List<Author> authors = [];

  String? selectedCategory;
  bool hasNext = false;
  bool isLoading = false;
  bool isLoadingMore = false;
  String? error;

  int _page = 1;
  int _request = 0;

  Future<void> init() => Future.wait([_loadReferences(), refresh()]);

  Future<void> refresh() async {
    try {
      featured = await _service.getFeatured();
    } on ApiException {
      featured = [];
    }
    await _loadArticles();
  }

  void selectCategory(String? slug) {
    if (slug == selectedCategory) return;
    selectedCategory = slug;
    _loadArticles();
  }

  Future<void> loadMore() async {
    if (isLoading || isLoadingMore || !hasNext) return;
    final request = _request;
    isLoadingMore = true;
    notifyListeners();
    try {
      final page = await _service.getArticles(page: _page + 1, category: selectedCategory);
      if (request != _request) return;
      articles = [...articles, ...page.items];
      hasNext = page.hasNext;
      _page++;
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      if (request == _request) {
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  /// Membuat artikel baru, atau mengubah bila [id] diisi (PUT parsial).
  Future<Article> save(Map<String, Object?> body, String apiKey, {int? id}) async {
    final article = id == null
        ? await _service.create(body, apiKey)
        : await _service.update(id, body, apiKey);
    refresh();
    return article;
  }

  Future<void> delete(int id, String apiKey) async {
    await _service.delete(id, apiKey);
    articles.removeWhere((a) => a.id == id);
    featured.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  Future<void> _loadArticles() async {
    final request = ++_request;
    isLoading = true;
    isLoadingMore = false;
    error = null;
    notifyListeners();
    try {
      final page = await _service.getArticles(category: selectedCategory);
      if (request != _request) return;
      articles = page.items;
      hasNext = page.hasNext;
      _page = 1;
    } on ApiException catch (e) {
      if (request != _request) return;
      error = e.message;
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> _loadReferences() async {
    try {
      categories = await _references.getCategories();
      authors = await _references.getAuthors();
      notifyListeners();
    } on ApiException {
      // Chip kategori disembunyikan bila gagal; daftar artikel tetap jalan.
    }
  }
}
