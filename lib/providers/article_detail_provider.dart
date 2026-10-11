import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../models/article.dart';
import '../models/comment.dart';
import '../services/article_service.dart';
import '../services/comment_service.dart';

/// State satu halaman detail: isi artikel + komentarnya.
class ArticleDetailProvider extends ChangeNotifier {
  /// [article] versi daftar dipakai sebagai tampilan awal sambil memuat isi.
  ArticleDetailProvider(this.article);

  final _articles = ArticleService();
  final _comments = CommentService();

  Article article;
  List<Comment> comments = [];
  bool commentsHasNext = false;
  bool isLoading = true;
  String? error;

  int _commentPage = 1;
  bool _disposed = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    _notify();
    try {
      final results = await Future.wait([
        _articles.getArticle(article.id),
        _comments.getComments(article.id),
      ]);
      article = results[0] as Article;
      final page = results[1] as ({List<Comment> items, bool hasNext});
      comments = page.items;
      commentsHasNext = page.hasNext;
      _commentPage = 1;
    } on ApiException catch (e) {
      error = e.message;
    }
    isLoading = false;
    _notify();
  }

  Future<void> loadMoreComments() async {
    final page = await _comments.getComments(article.id, page: _commentPage + 1);
    comments = [...comments, ...page.items];
    commentsHasNext = page.hasNext;
    _commentPage++;
    _notify();
  }

  /// Melempar [ApiException] bila validasi gagal — ditangani di UI.
  Future<void> sendComment(String name, String content) async {
    final comment = await _comments.send(article.id, name: name.trim(), content: content.trim());
    comments = [comment, ...comments];
    _notify();
  }

  Future<void> deleteComment(int id, String apiKey) async {
    await _comments.delete(id, apiKey);
    comments = comments.where((c) => c.id != id).toList();
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
