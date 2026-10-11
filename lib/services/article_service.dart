import '../api/api_client.dart';
import '../models/article.dart';

class ArticleService {
  final _api = ApiClient.instance;

  List<Article> _list(dynamic data) =>
      (data as List).map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();

  Future<({List<Article> items, bool hasNext})> getArticles({
    int page = 1,
    String? category,
    String? search,
  }) async {
    final res = await _api.get(
      '/articles',
      query: {'page': page, 'limit': 10, 'category': category, 'search': search},
    );
    return (items: _list(res.data), hasNext: res.hasNext);
  }

  Future<List<Article>> getFeatured() async =>
      _list((await _api.get('/articles/featured', query: {'limit': 5})).data);

  /// Catatan: setiap panggilan menambah `views` artikel sebanyak 1.
  Future<Article> getArticle(int id) async =>
      Article.fromJson((await _api.get('/articles/$id')).data as Map<String, dynamic>);

  Future<Article> create(Map<String, Object?> body, String apiKey) async =>
      Article.fromJson((await _api.post('/articles', body, apiKey: apiKey)).data as Map<String, dynamic>);

  Future<Article> update(int id, Map<String, Object?> body, String apiKey) async =>
      Article.fromJson((await _api.put('/articles/$id', body, apiKey: apiKey)).data as Map<String, dynamic>);

  Future<void> delete(int id, String apiKey) => _api.delete('/articles/$id', apiKey: apiKey);
}
