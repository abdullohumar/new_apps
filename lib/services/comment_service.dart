import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/comment.dart';
import 'article_service.dart';

class CommentService {
  // GET /articles/{articleId}/comments
  Future<List<Comment>> getComments(int articleId) async {
    final response = await http.get(
      Uri.parse('${ArticleService.baseUrl}/articles/$articleId/comments?limit=50'),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) throw Exception(body['message']);

    final List data = body['data'];
    return data.map((json) => Comment.fromJson(json)).toList();
  }

  // POST /articles/{articleId}/comments — tidak perlu api key
  Future<Comment> addComment(int articleId, String name, String content) async {
    final response = await http.post(
      Uri.parse('${ArticleService.baseUrl}/articles/$articleId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'content': content}),
    );
    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode >= 400) throw Exception(body['message']);

    return Comment.fromJson(body['data']);
  }
}
