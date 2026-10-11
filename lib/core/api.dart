import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.errors = const {}});

  final String message;
  final int? statusCode;

  /// Error validasi per field (hanya pada 422).
  final Map<String, String> errors;

  @override
  String toString() => message;
}

enum ArticleSort { latest, oldest, popular }

class NewsApi {
  NewsApi({http.Client? client}) : _client = client ?? http.Client();

  static final instance = NewsApi();

  static const baseUrl =
      'https://knlhpjkhujzjyzrmxfjj.supabase.co/functions/v1/api';

  final http.Client _client;

  Future<Map<String, dynamic>> _request(
    String path, {
    String? method,
    Map<String, Object?> query = const {},
    Map<String, Object?>? body,
    String? adminKey,
  }) async {
    final params = <String, String>{
      for (final e in query.entries)
        if (e.value != null && '${e.value}'.isNotEmpty) e.key: '${e.value}',
    };
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: params.isEmpty ? null : params);
    final req = http.Request(method ?? (body == null ? 'GET' : 'POST'), uri)
      ..headers['Accept'] = 'application/json';
    if (adminKey != null) req.headers['x-api-key'] = adminKey;
    if (body != null) {
      req.headers['Content-Type'] = 'application/json';
      req.body = jsonEncode(body);
    }

    final http.Response res;
    try {
      res = await _client
          .send(req)
          .then(http.Response.fromStream)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException('Koneksi terlalu lama. Coba lagi sebentar.');
    } catch (_) {
      throw ApiException('Tidak bisa terhubung. Periksa koneksi internetmu.');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Respons server tidak bisa dibaca.',
          statusCode: res.statusCode);
    }

    if (res.statusCode >= 400 || json['success'] != true) {
      final errors = (json['errors'] as Map?)
              ?.map((k, v) => MapEntry('$k', '$v')) ??
          const <String, String>{};
      throw ApiException(
        json['message'] as String? ?? 'Terjadi kesalahan (${res.statusCode}).',
        statusCode: res.statusCode,
        errors: errors,
      );
    }
    return json;
  }

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) parse) =>
      (data as List? ?? const [])
          .map((e) => parse((e as Map).cast<String, dynamic>()))
          .toList();

  Paged<T> _paged<T>(
      Map<String, dynamic> json, T Function(Map<String, dynamic>) parse) {
    final meta = (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {};
    final items = _list(json['data'], parse);
    return Paged(
      items: items,
      page: (meta['page'] as num?)?.toInt() ?? 1,
      total: (meta['total'] as num?)?.toInt() ?? items.length,
      totalPages: (meta['total_pages'] as num?)?.toInt() ?? 1,
      hasNext: meta['has_next'] == true,
    );
  }

  Future<List<NewsCategory>> categories() async =>
      _list((await _request('/categories'))['data'], NewsCategory.fromJson);

  Future<NewsCategory> category(String slug) async => NewsCategory.fromJson(
      (await _request('/categories/$slug'))['data'] as Map<String, dynamic>);

  Future<List<Author>> authors() async =>
      _list((await _request('/authors'))['data'], Author.fromJson);

  Future<Author> author(String slug) async => Author.fromJson(
      (await _request('/authors/$slug'))['data'] as Map<String, dynamic>);

  Future<Paged<Article>> articles({
    int page = 1,
    int limit = 10,
    String? category,
    String? author,
    String? tag,
    String? search,
    ArticleSort sort = ArticleSort.latest,
  }) async =>
      _paged(
        await _request('/articles', query: {
          'page': page,
          'limit': limit,
          'category': category,
          'author': author,
          'tag': tag,
          'search': search?.trim(),
          'sort': sort.name,
        }),
        Article.fromJson,
      );

  Future<List<Article>> featured({int limit = 5}) async => _list(
      (await _request('/articles/featured', query: {'limit': limit}))['data'],
      Article.fromJson);

  Future<List<Article>> breaking({int limit = 5}) async => _list(
      (await _request('/articles/breaking', query: {'limit': limit}))['data'],
      Article.fromJson);

  Future<Article> article(String idOrSlug) async => Article.fromJson(
      (await _request('/articles/$idOrSlug'))['data'] as Map<String, dynamic>);

  Future<List<Article>> related(String idOrSlug, {int limit = 4}) async =>
      _list(
          (await _request('/articles/$idOrSlug/related',
              query: {'limit': limit}))['data'],
          Article.fromJson);

  Future<Paged<Comment>> comments(String idOrSlug,
          {int page = 1, int limit = 10}) async =>
      _paged(
        await _request('/articles/$idOrSlug/comments',
            query: {'page': page, 'limit': limit}),
        Comment.fromJson,
      );

  // ---------------------------------------------------------------- admin

  /// Cek key tanpa efek samping: menghapus komentar yang pasti tidak ada.
  /// 401 = key salah; 404 = key benar (auth dicek lebih dulu oleh API).
  Future<bool> verifyAdminKey(String key) async {
    try {
      await _request('/comments/999999999', method: 'DELETE', adminKey: key);
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401) return false;
      if (e.statusCode == 404) return true;
      rethrow;
    }
  }

  Future<Article> createArticle(String key, Map<String, Object?> fields) async =>
      Article.fromJson((await _request('/articles', method: 'POST', body: fields, adminKey: key))[
          'data'] as Map<String, dynamic>);

  /// PUT bersifat parsial — kirim hanya field yang berubah.
  Future<Article> updateArticle(String key, int id, Map<String, Object?> changes) async =>
      Article.fromJson((await _request('/articles/$id',
              method: 'PUT', body: changes, adminKey: key))['data']
          as Map<String, dynamic>);

  Future<void> deleteArticle(String key, int id) =>
      _request('/articles/$id', method: 'DELETE', adminKey: key);

  Future<void> deleteComment(String key, int id) =>
      _request('/comments/$id', method: 'DELETE', adminKey: key);

  Future<Comment> postComment(String idOrSlug,
          {required String name, required String content}) async =>
      Comment.fromJson((await _request('/articles/$idOrSlug/comments',
              body: {'name': name.trim(), 'content': content.trim()}))['data']
          as Map<String, dynamic>);
}
