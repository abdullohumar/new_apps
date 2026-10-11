import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/comment.dart';
import 'article_service.dart';

class CommentService {
  // GET /articles/{articleId}/comments?limit=50
  Future<List<Comment>> getComments(int articleId) async {
    // TODO: GET komentar, lalu ubah body['data'] menjadi List<Comment>
    throw UnimplementedError('getComments belum dibuat');
  }

  // POST /articles/{articleId}/comments — tidak perlu api key
  Future<Comment> addComment(int articleId, String name, String content) async {
    // TODO: http.post dengan header Content-Type dan body {'name': ..., 'content': ...}
    // Hint: jangan lupa jsonEncode body-nya
    throw UnimplementedError('addComment belum dibuat');
  }
}
