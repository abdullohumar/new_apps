import 'package:flutter/foundation.dart';

import 'api.dart';
import 'models.dart';

/// Daftar artikel ber-pagination dengan filter. Dipakai beranda,
/// halaman rubrik/penulis/topik, dan hasil pencarian.
class ArticleFeed extends ChangeNotifier {
  ArticleFeed({
    this.category,
    this.author,
    this.tag,
    this.search,
    this.sort = ArticleSort.latest,
    this.pageSize = 10,
  });

  String? category;
  String? author;
  String? tag;
  String? search;
  ArticleSort sort;
  final int pageSize;

  final items = <Article>[];
  int page = 0;
  int total = 0;
  bool hasNext = true;
  bool loading = false;
  String? error;

  int _token = 0;
  bool _disposed = false;

  Future<void> refresh() {
    _token++;
    items.clear();
    page = 0;
    total = 0;
    hasNext = true;
    error = null;
    return _fetch();
  }

  Future<void> loadMore() async {
    if (loading || !hasNext || error != null) return;
    return _fetch();
  }

  Future<void> retry() {
    error = null;
    return items.isEmpty ? refresh() : _fetch();
  }

  Future<void> _fetch() async {
    final token = _token;
    loading = true;
    notifyListeners();
    try {
      final res = await NewsApi.instance.articles(
        page: page + 1,
        limit: pageSize,
        category: category,
        author: author,
        tag: tag,
        search: search,
        sort: sort,
      );
      if (_disposed || token != _token) return;
      items.addAll(res.items);
      page = res.page;
      total = res.total;
      hasNext = res.hasNext;
    } on ApiException catch (e) {
      if (_disposed || token != _token) return;
      error = e.message;
    }
    loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
