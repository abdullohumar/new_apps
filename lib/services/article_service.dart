import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../models/article_response.dart';

class ArticleService {
  static const baseUrl = 'https://knlhpjkhujzjyzrmxfjj.supabase.co/functions/v1/api';

  // Key admin untuk POST, PUT, DELETE. Isi dengan ADMIN_API_KEY dari guru.
  // Hanya untuk latihan — jangan simpan key di aplikasi yang dirilis.
  static const apiKey = 'ISI_ADMIN_API_KEY';

  static const headers = {'Content-Type': 'application/json', 'x-api-key': apiKey};

  // GET /articles
  Future<List<Article>> getArticles() async {
    final response = await http.get(Uri.parse('$baseUrl/articles?limit=50'));
    final body = _decode(response);
    return ArticleResponse.fromJson(body).articles;
  }

  // GET /articles/{id}
  Future<Article> getArticle(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/articles/$id'));
    final body = _decode(response);
    return Article.fromJson(body['data']);
  }

  // POST /articles
  Future<Article> createArticle(Article article) async {
    final response = await http.post(
      Uri.parse('$baseUrl/articles'),
      headers: headers,
      body: jsonEncode(article.toJson()),
    );
    final body = _decode(response);
    return Article.fromJson(body['data']);
  }

  // PUT /articles/{id}
  Future<Article> updateArticle(Article article) async {
    final response = await http.put(
      Uri.parse('$baseUrl/articles/${article.id}'),
      headers: headers,
      body: jsonEncode(article.toJson()),
    );
    final body = _decode(response);
    return Article.fromJson(body['data']);
  }

  // DELETE /articles/{id}
  Future<void> deleteArticle(int id) async {
    final response = await http.delete(Uri.parse('$baseUrl/articles/$id'), headers: headers);
    _decode(response);
  }

  // Ubah response menjadi Map. Kalau gagal, lempar pesan error dari API.
  Map<String, dynamic> _decode(http.Response response) {
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) {
      throw Exception(body['message']);
    }
    return body;
  }
}
