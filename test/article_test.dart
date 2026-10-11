import 'package:flutter_test/flutter_test.dart';
import 'package:new_apps/models/article.dart';
import 'package:new_apps/models/article_response.dart';
import 'package:new_apps/models/comment.dart';

void main() {
  test('Article.fromJson dan toJson', () {
    final article = Article.fromJson({
      'id': 5,
      'title': 'Klub Garuda Muda Juara Liga Futsal Pelajar',
      'summary': null,
      'content': 'Isi artikel.',
      'thumbnail_url': null,
      'category': {'id': 2, 'name': 'Olahraga', 'slug': 'olahraga'},
      'author': {'id': 2, 'name': 'Budi Santoso', 'slug': 'budi-santoso', 'avatar_url': null},
    });

    expect(article.categoryName, 'Olahraga');
    expect(article.author.name, 'Budi Santoso');
    expect(article.toJson()['category_id'], 2);
    expect(article.toJson()['author_id'], 2);
  });

  test('Comment.fromJson', () {
    final comment = Comment.fromJson({
      'id': 4,
      'name': 'Putri',
      'content': 'Gol di menit akhir itu luar biasa.',
      'created_at': '2026-10-11T04:15:00.000000+00:00',
    });

    expect(comment.name, 'Putri');
    expect(comment.createdAt.toUtc(), DateTime.utc(2026, 10, 11, 4, 15));
  });

  test('ArticleResponse.fromJson', () {
    final response = ArticleResponse.fromJson({
      'success': true,
      'message': 'OK',
      'data': [
        {
          'id': 4,
          'title': 'Uji Coba Internet Satelit',
          'category': {'id': 1, 'name': 'Teknologi'},
          'author': {'id': 1, 'name': 'Rina Pratiwi'},
        },
      ],
    });

    expect(response.success, true);
    expect(response.articles.length, 1);
    expect(response.articles.first.author.name, 'Rina Pratiwi');
  });
}
