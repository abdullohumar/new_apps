import 'package:flutter_test/flutter_test.dart';
import 'package:new_apps/core/format.dart';
import 'package:new_apps/core/models.dart';

void main() {
  test('Article.fromJson membaca versi daftar & bolak-balik lewat toJson', () {
    final a = Article.fromJson({
      'id': 5,
      'title': 'Klub Garuda Muda Juara Liga Futsal Pelajar',
      'slug': 'garuda-muda-juara-liga-futsal-pelajar',
      'summary': null,
      'thumbnail_url': 'https://picsum.photos/seed/x/800/450',
      'tags': ['futsal', 'pelajar'],
      'is_featured': true,
      'is_breaking': false,
      'views': 2101,
      'published_at': '2026-10-11T02:15:00.000000+00:00',
      'category': {'id': 2, 'name': 'Olahraga', 'slug': 'olahraga'},
      'author': {'id': 2, 'name': 'Budi Santoso', 'slug': 'budi-santoso', 'avatar_url': null},
    });
    expect(a.category.slug, 'olahraga');
    expect(a.tags, ['futsal', 'pelajar']);
    expect(a.publishedAt!.toUtc(), DateTime.utc(2026, 10, 11, 2, 15));

    final again = Article.fromJson(a.toJson());
    expect(again.title, a.title);
    expect(again.publishedAt, a.publishedAt);
  });

  test('format', () {
    expect(compact(410), '410');
    expect(compact(2101), '2,1 rb');
    expect(compact(3000), '3 rb');
    expect(fullDate(DateTime(2026, 10, 11)), 'Minggu, 11 Oktober 2026');
    final now = DateTime(2026, 10, 11, 12);
    expect(timeAgo(now.subtract(const Duration(minutes: 5)), now: now), '5 menit lalu');
    expect(timeAgo(now.subtract(const Duration(hours: 30)), now: now), 'Kemarin');
    expect(paragraphs('A\n\nB\n \nC'), ['A', 'B', 'C']);
    expect(initials('Rina Pratiwi'), 'RP');
  });
}
