import 'article.dart';

// Pembungkus response GET /articles:
// { "success": true, "message": "OK", "data": [ {...}, {...} ] }
class ArticleResponse {
  final bool success;
  final String message;
  final List<Article> articles;

  ArticleResponse({required this.success, required this.message, required this.articles});

  factory ArticleResponse.fromJson(Map<String, dynamic> json) {
    // TODO: kembalikan ArticleResponse(...)
    // Hint: daftar artikel ada di json['data'] (List).
    //       Ubah tiap item jadi Article dengan .map(...) lalu .toList()
    throw UnimplementedError('ArticleResponse.fromJson belum dibuat');
  }
}
