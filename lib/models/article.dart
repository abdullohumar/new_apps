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
  // Contoh JSON:
  // {
  //   "id": 5, "title": "...", "summary": "...", "content": "...",
  //   "thumbnail_url": "https://...",
  //   "category": { "id": 2, "name": "Olahraga" },
  //   "author":   { "id": 2, "name": "Budi Santoso", ... }
  // }
  factory Article.fromJson(Map<String, dynamic> json) {
    // TODO: kembalikan Article(...) dari json
    // Hint: category ada di dalam objek -> json['category']['id']
    // Hint: author juga objek -> pakai Author.fromJson(...)
    throw UnimplementedError('Article.fromJson belum dibuat');
  }

  // Objek Article -> body JSON untuk POST / PUT
  Map<String, dynamic> toJson() {
    // TODO: kembalikan Map berisi: title, summary, content, thumbnail_url, category_id, author_id
    // Hint: API minta 'author_id', bukan objek author.
    throw UnimplementedError('Article.toJson belum dibuat');
  }
}
