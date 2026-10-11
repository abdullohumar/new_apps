import 'article.dart';

// Pembungkus response GET /articles:
// { "success": true, "message": "OK", "data": [ {...}, {...} ] }
class ArticleResponse {
  final bool success;
  final String message;
  final List<Article> articles;

  ArticleResponse({required this.success, required this.message, required this.articles});

  factory ArticleResponse.fromJson(Map<String, dynamic> json) {
    final List data = json['data'];
    return ArticleResponse(
      success: json['success'],
      message: json['message'],
      articles: data.map((item) => Article.fromJson(item)).toList(),
    );
  }
}
