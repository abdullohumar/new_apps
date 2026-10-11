import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/comment.dart';
import '../services/comment_service.dart';

final commentServiceProvider = Provider((ref) => CommentService());

// Komentar milik satu artikel (parameter: id artikel).
final commentsProvider = FutureProvider.family<List<Comment>, int>((ref, articleId) {
  return ref.watch(commentServiceProvider).getComments(articleId);
});
