import '../api/api_client.dart';
import '../models/comment.dart';

class CommentService {
  final _api = ApiClient.instance;

  Future<({List<Comment> items, bool hasNext})> getComments(int articleId, {int page = 1}) async {
    final res = await _api.get('/articles/$articleId/comments', query: {'page': page, 'limit': 10});
    final items = (res.data as List).map((e) => Comment.fromJson(e as Map<String, dynamic>)).toList();
    return (items: items, hasNext: res.hasNext);
  }

  Future<Comment> send(int articleId, {required String name, required String content}) async {
    final res = await _api.post('/articles/$articleId/comments', {'name': name, 'content': content});
    return Comment.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> delete(int commentId, String apiKey) => _api.delete('/comments/$commentId', apiKey: apiKey);
}
