import 'package:flutter_test/flutter_test.dart';
import 'package:new_apps/models/article.dart';
import 'package:new_apps/utils/format.dart';

void main() {
  test('Article.fromJson membaca respons API', () {
    final article = Article.fromJson({
      'id': 5,
      'title': 'Klub Garuda Muda Juara Liga Futsal Pelajar',
      'slug': 'garuda-muda-juara-liga-futsal-pelajar',
      'summary': null,
      'content': 'Paragraf satu.\n\nParagraf dua.',
      'thumbnail_url': null,
      'tags': ['futsal', 'pelajar'],
      'is_featured': true,
      'is_breaking': false,
      'views': 2101,
      'status': 'published',
      'published_at': '2026-10-11T02:15:00.000000+00:00',
      'category': {'id': 2, 'name': 'Olahraga', 'slug': 'olahraga'},
      'author': {'id': 2, 'name': 'Budi Santoso', 'slug': 'budi-santoso', 'avatar_url': null},
    });

    expect(article.category.name, 'Olahraga');
    expect(article.tags, ['futsal', 'pelajar']);
    expect(article.paragraphs, ['Paragraf satu.', 'Paragraf dua.']);
    expect(article.publishedAt!.toUtc(), DateTime.utc(2026, 10, 11, 2, 15));
  });

  test('format', () {
    expect(compactNumber(410), '410');
    expect(compactNumber(2101), '2,1 rb');
    expect(formatDate(DateTime(2026, 10, 11)), 'Minggu, 11 Oktober 2026');
  });
}
