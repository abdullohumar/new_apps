import 'author.dart';
import 'category.dart';

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.author,
    this.summary,
    this.content,
    this.thumbnailUrl,
    this.tags = const [],
    this.isFeatured = false,
    this.isBreaking = false,
    this.views = 0,
    this.status = 'published',
    this.publishedAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'] as int,
    title: json['title'] as String,
    slug: json['slug'] as String,
    summary: json['summary'] as String?,
    content: json['content'] as String?,
    thumbnailUrl: json['thumbnail_url'] as String?,
    tags: List<String>.from(json['tags'] as List? ?? const []),
    isFeatured: json['is_featured'] as bool? ?? false,
    isBreaking: json['is_breaking'] as bool? ?? false,
    views: json['views'] as int? ?? 0,
    status: json['status'] as String? ?? 'published',
    publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '')?.toLocal(),
    category: NewsCategory.fromJson(json['category'] as Map<String, dynamic>),
    author: Author.fromJson(json['author'] as Map<String, dynamic>),
  );

  final int id;
  final String title;
  final String slug;
  final String? summary;

  /// Hanya terisi dari endpoint detail. Paragraf dipisah `\n\n`.
  final String? content;
  final String? thumbnailUrl;
  final List<String> tags;
  final bool isFeatured;
  final bool isBreaking;
  final int views;
  final String status;
  final DateTime? publishedAt;
  final NewsCategory category;
  final Author author;

  List<String> get paragraphs =>
      (content ?? '').split(RegExp(r'\n\s*\n')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
}
