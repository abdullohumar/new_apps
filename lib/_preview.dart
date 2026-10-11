import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/article.dart';
import 'providers/article_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/detail_screen.dart';
import 'screens/form_screen.dart';
import 'screens/home_screen.dart';
import 'services/article_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final s = Uri.base.queryParameters['s'];
  final article = s == 'detail' ? await ArticleService().getArticle(5) : null;
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => ArticleProvider()..init()),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      onGenerateRoute: (_) => switch (s) {
        'detail' => DetailScreen.route(article as Article),
        'form' => MaterialPageRoute(builder: (_) => const FormScreen()),
        _ => MaterialPageRoute(builder: (_) => const HomeScreen()),
      },
    ),
  ));
}
