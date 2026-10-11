import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

/// Artikel tersimpan. Versi detail (dengan `content`) ikut disimpan,
/// jadi artikel tetap bisa dibaca saat offline.
class Bookmarks extends ChangeNotifier {
  Bookmarks(this._prefs) {
    for (final raw in _prefs.getStringList(_key) ?? const <String>[]) {
      try {
        _items.add(Article.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {/* abaikan data rusak */}
    }
  }

  static const _key = 'bookmarks.v1';
  final SharedPreferences _prefs;
  final _items = <Article>[];

  List<Article> get items => List.unmodifiable(_items);
  int get length => _items.length;

  bool contains(int id) => _items.any((a) => a.id == id);

  Article? find(int id) {
    for (final a in _items) {
      if (a.id == id) return a;
    }
    return null;
  }

  void toggle(Article a) => contains(a.id) ? remove(a.id) : insert(0, a);

  void insert(int index, Article a) {
    _items.removeWhere((e) => e.id == a.id);
    _items.insert(index.clamp(0, _items.length), a);
    _save();
  }

  /// Perbarui salinan tersimpan (mis. setelah konten lengkap dimuat).
  void refresh(Article a) {
    final i = _items.indexWhere((e) => e.id == a.id);
    if (i == -1) return;
    _items[i] = a;
    _save();
  }

  int remove(int id) {
    final i = _items.indexWhere((e) => e.id == id);
    if (i != -1) {
      _items.removeAt(i);
      _save();
    }
    return i;
  }

  void _save() {
    _prefs.setStringList(
        _key, _items.map((a) => jsonEncode(a.toJson())).toList());
    notifyListeners();
  }
}

class Settings extends ChangeNotifier {
  Settings(this._prefs)
      : _themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == _prefs.getString('theme'),
          orElse: () => ThemeMode.system,
        );

  final SharedPreferences _prefs;
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode m) {
    _themeMode = m;
    _prefs.setString('theme', m.name);
    notifyListeners();
  }

  String get commentName => _prefs.getString('comment.name') ?? '';
  set commentName(String v) => _prefs.setString('comment.name', v);
}

class BookmarksScope extends InheritedNotifier<Bookmarks> {
  const BookmarksScope(
      {super.key, required Bookmarks bookmarks, required super.child})
      : super(notifier: bookmarks);

  static Bookmarks of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<BookmarksScope>()!
      .notifier!;
}

class SettingsScope extends InheritedNotifier<Settings> {
  const SettingsScope(
      {super.key, required Settings settings, required super.child})
      : super(notifier: settings);

  static Settings of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SettingsScope>()!.notifier!;
}

/// Mode redaksi (admin). Key hanya disimpan di perangkat ini — tidak pernah
/// ditanam di kode, sesuai peringatan di dokumentasi API.
class Newsroom extends ChangeNotifier {
  Newsroom(this._prefs) : _key = _prefs.getString(_keyPref) {
    for (final raw in _prefs.getStringList(_draftsPref) ?? const <String>[]) {
      try {
        _drafts.add(Article.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {/* abaikan data rusak */}
    }
  }

  static const _keyPref = 'admin.key';
  static const _draftsPref = 'admin.drafts.v1';
  final SharedPreferences _prefs;
  String? _key;
  final _drafts = <Article>[];
  int _revision = 0;

  String? get key => _key;
  bool get unlocked => _key != null;

  /// Naik setiap ada artikel/komentar yang dibuat, diubah, atau dihapus.
  int get revision => _revision;

  /// Draf tidak pernah muncul di endpoint GET, jadi yang bisa ditampilkan
  /// hanyalah draf yang dibuat atau diubah dari perangkat ini.
  List<Article> get drafts => List.unmodifiable(_drafts);

  void unlock(String key) {
    _key = key;
    _prefs.setString(_keyPref, key);
    notifyListeners();
  }

  void lock() {
    _key = null;
    _prefs.remove(_keyPref);
    notifyListeners();
  }

  /// Catat hasil POST/PUT: simpan bila draf, lepas bila sudah terbit.
  void remember(Article a) {
    _drafts.removeWhere((d) => d.id == a.id);
    if (a.isDraft) _drafts.insert(0, a);
    _saveDrafts();
  }

  void forget(int id) {
    _drafts.removeWhere((d) => d.id == id);
    _saveDrafts();
  }

  void touch() {
    _revision++;
    notifyListeners();
  }

  void _saveDrafts() {
    _prefs.setStringList(_draftsPref, _drafts.map((a) => jsonEncode(a.toJson())).toList());
    touch();
  }
}

class NewsroomScope extends InheritedNotifier<Newsroom> {
  const NewsroomScope({super.key, required Newsroom newsroom, required super.child})
      : super(notifier: newsroom);

  static Newsroom of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<NewsroomScope>()!.notifier!;
}
