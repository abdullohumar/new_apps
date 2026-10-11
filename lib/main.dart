import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/article_provider.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final auth = AuthProvider();
  await auth.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: auth),
        ChangeNotifierProvider(create: (_) => ArticleProvider()..init()),
      ],
      child: const NewsApp(),
    ),
  );
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kabar',
    debugShowCheckedModeBanner: false,
    theme: buildTheme(),
    home: const HomeScreen(),
  );
}
