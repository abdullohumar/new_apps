import 'package:flutter/material.dart';

import 'core/models.dart';
import 'screens/article_screen.dart';
import 'screens/editor_screen.dart';
import 'screens/feed_screen.dart';
import 'screens/newsroom_screen.dart';

Future<void> openArticle(BuildContext context, Article article, {required String heroTag}) =>
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ArticleScreen(article: article, heroTag: heroTag),
    ));

Future<void> openCategory(BuildContext context, CategoryRef category, {String? description}) =>
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FeedScreen.category(category, description: description),
    ));

Future<void> openAuthor(BuildContext context, AuthorRef author) =>
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FeedScreen.author(author),
    ));

Future<void> openTag(BuildContext context, String tag) =>
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FeedScreen.tag(tag),
    ));

Future<void> openNewsroom(BuildContext context) => Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const NewsroomScreen(),
    ));

/// Tanpa [article] = buat baru. Mengembalikan `null` bila ditutup tanpa simpan.
Future<EditorResult?> openEditor(BuildContext context, {Article? article}) =>
    Navigator.of(context).push<EditorResult>(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ArticleEditorScreen(initial: article),
    ));
