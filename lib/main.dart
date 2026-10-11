import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/store.dart';
import 'screens/shell.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  runApp(
    KabarApp(bookmarks: Bookmarks(prefs), settings: Settings(prefs), newsroom: Newsroom(prefs)),
  );
}

class KabarApp extends StatelessWidget {
  const KabarApp({
    super.key,
    required this.bookmarks,
    required this.settings,
    required this.newsroom,
  });

  final Bookmarks bookmarks;
  final Settings settings;
  final Newsroom newsroom;

  @override
  Widget build(BuildContext context) {
    return SettingsScope(
      settings: settings,
      child: BookmarksScope(
        bookmarks: bookmarks,
        child: NewsroomScope(
          newsroom: newsroom,
          child: ListenableBuilder(
            listenable: settings,
            builder: (context, _) => MaterialApp(
              title: 'Kabar',
              debugShowCheckedModeBanner: false,
              themeMode: settings.themeMode,
              theme: buildTheme(Brightness.light),
              darkTheme: buildTheme(Brightness.dark),
              home: const AppShell(),
            ),
          ),
        ),
      ),
    );
  }
}
