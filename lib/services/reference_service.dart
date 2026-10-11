import '../api/api_client.dart';
import '../models/author.dart';
import '../models/category.dart';

/// Data pendukung: kategori dan penulis.
class ReferenceService {
  final _api = ApiClient.instance;

  Future<List<NewsCategory>> getCategories() async => ((await _api.get('/categories')).data as List)
      .map((e) => NewsCategory.fromJson(e as Map<String, dynamic>))
      .toList();

  Future<List<Author>> getAuthors() async => ((await _api.get('/authors')).data as List)
      .map((e) => Author.fromJson(e as Map<String, dynamic>))
      .toList();
}
