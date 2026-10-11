import 'author.dart';

class Article {
  final int id;
  final String title;
  final String? summary;
  final String? content;
  final String? thumbnailUrl;
  final int categoryId;
  final String categoryName;
  final Author author;

  Article({
    required this.id,
    required this.title,
    this.summary,
    this.content,
    this.thumbnailUrl,
    required this.categoryId,
    this.categoryName = '',
    required this.author,
  });

  // JSON dari API -> objek Article
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'],
      summary: json['summary'],
      content: json['content'],
      thumbnailUrl: json['thumbnail_url'],
      categoryId: json['category']['id'],
      categoryName: json['category']['name'],
      author: Author.fromJson(json['author']),
    );
  }

  // Objek Article -> body JSON untuk POST / PUT
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'content': content,
      'thumbnail_url': thumbnailUrl,
      'category_id': categoryId,
      'author_id': author.id,
    };
  }
}
