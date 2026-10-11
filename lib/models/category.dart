class NewsCategory {
  const NewsCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.articleCount = 0,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> json) => NewsCategory(
    id: json['id'] as int,
    name: json['name'] as String,
    slug: json['slug'] as String,
    description: json['description'] as String?,
    articleCount: json['article_count'] as int? ?? 0,
  );

  final int id;
  final String name;
  final String slug;
  final String? description;
  final int articleCount;
}
