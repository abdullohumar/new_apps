import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/article.dart';
import '../models/article_response.dart';

class ArticleService {
  static const baseUrl = 'https://knlhpjkhujzjyzrmxfjj.supabase.co/functions/v1/api';

  // Key admin untuk POST, PUT, DELETE. Isi dengan ADMIN_API_KEY dari punyamu dewe.
  // Hanya untuk latihan — aslinya jangan taruh kayak gini si apiKey ini.
  static const apiKey = 'overridemode';

  static const headers = {'Content-Type': 'application/json', 'x-api-key': apiKey};

  // GET /articles?limit=50
  Future<List<Article>> getArticles() async {
    // TODO: panggil http.get(Uri.parse(...)), lalu ubah dengan _decode(response)
    // Hint: hasilnya dibungkus -> pakai ArticleResponse.fromJson(...).articles
    throw UnimplementedError('getArticles belum dibuat');
  }

  // GET /articles/{id}
  Future<Article> getArticle(int id) async {
    // TODO: GET ke '$baseUrl/articles/$id'
    // Hint: satu artikel ada di body['data'] -> Article.fromJson(...)
    throw UnimplementedError('getArticle belum dibuat');
  }

  // POST /articles (butuh headers)
  Future<Article> createArticle(Article article) async {
    // TODO: http.post dengan headers dan body
    // Hint: body harus String JSON -> jsonEncode(article.toJson())
    throw UnimplementedError('createArticle belum dibuat');
  }

  // PUT /articles/{id} (butuh headers)
  Future<Article> updateArticle(Article article) async {
    // TODO: mirip createArticle, tapi pakai http.put dan id artikel di URL
    throw UnimplementedError('updateArticle belum dibuat');
  }

  // DELETE /articles/{id} (butuh headers)
  Future<void> deleteArticle(int id) async {
    // TODO: http.delete dengan headers, lalu cek hasilnya dengan _decode(response)
    throw UnimplementedError('deleteArticle belum dibuat');
  }

  // Ubah response menjadi Map. Kalau gagal, lempar pesan error dari API.
  Map<String, dynamic> _decode(http.Response response) {
    // TODO: ubah response jadi Map dengan jsonDecode(...)
    // Hint: pakai utf8.decode(response.bodyBytes) agar huruf non-ASCII aman
    // Hint: kalau response.statusCode >= 400, throw Exception(body['message'])
    throw UnimplementedError('_decode belum dibuat');
  }
}
