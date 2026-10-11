DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v)?.toLocal() : null;

int _int(Object? v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;

class CategoryRef {
  const CategoryRef({required this.id, required this.name, required this.slug});

  factory CategoryRef.fromJson(Map<String, dynamic> j) => CategoryRef(
        id: _int(j['id']),
        name: j['name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
      );

  final int id;
  final String name;
  final String slug;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'slug': slug};
}

class NewsCategory extends CategoryRef {
  const NewsCategory({
    required super.id,
    required super.name,
    required super.slug,
    this.description,
    this.articleCount = 0,
  });

  factory NewsCategory.fromJson(Map<String, dynamic> j) => NewsCategory(
        id: _int(j['id']),
        name: j['name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        description: j['description'] as String?,
        articleCount: _int(j['article_count']),
      );

  final String? description;
  final int articleCount;
}

class AuthorRef {
  const AuthorRef({
    required this.id,
    required this.name,
    required this.slug,
    this.avatarUrl,
    this.bio,
  });

  factory AuthorRef.fromJson(Map<String, dynamic> j) => AuthorRef(
        id: _int(j['id']),
        name: j['name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
        bio: j['bio'] as String?,
      );

  final int id;
  final String name;
  final String slug;
  final String? avatarUrl;
  final String? bio;

  Map<String, dynamic> toJson() =>
      {'id': id, 'name': name, 'slug': slug, 'avatar_url': avatarUrl, 'bio': bio};
}

class Author extends AuthorRef {
  const Author({
    required super.id,
    required super.name,
    required super.slug,
    super.avatarUrl,
    super.bio,
    this.articleCount = 0,
  });

  factory Author.fromJson(Map<String, dynamic> j) => Author(
        id: _int(j['id']),
        name: j['name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        avatarUrl: j['avatar_url'] as String?,
        bio: j['bio'] as String?,
        articleCount: _int(j['article_count']),
      );

  final int articleCount;
}

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.slug,
    required this.category,
    required this.author,
    this.summary,
    this.thumbnailUrl,
    this.tags = const [],
    this.isFeatured = false,
    this.isBreaking = false,
    this.views = 0,
    this.publishedAt,
    this.content,
    this.updatedAt,
    this.status,
  });

  factory Article.fromJson(Map<String, dynamic> j) => Article(
        id: _int(j['id']),
        title: j['title'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        summary: j['summary'] as String?,
        thumbnailUrl: j['thumbnail_url'] as String?,
        tags: (j['tags'] as List?)?.map((e) => '$e').toList() ?? const [],
        isFeatured: j['is_featured'] == true,
        isBreaking: j['is_breaking'] == true,
        views: _int(j['views']),
        publishedAt: _date(j['published_at']),
        category: CategoryRef.fromJson(
            (j['category'] as Map?)?.cast<String, dynamic>() ?? const {}),
        author: AuthorRef.fromJson(
            (j['author'] as Map?)?.cast<String, dynamic>() ?? const {}),
        content: j['content'] as String?,
        updatedAt: _date(j['updated_at']),
        status: j['status'] as String?,
      );

  final int id;
  final String title;
  final String slug;
  final String? summary;
  final String? thumbnailUrl;
  final List<String> tags;
  final bool isFeatured;
  final bool isBreaking;
  final int views;
  final DateTime? publishedAt;
  final CategoryRef category;
  final AuthorRef author;

  /// Hanya terisi pada versi detail.
  final String? content;
  final DateTime? updatedAt;

  /// `published` / `draft` — hanya ada pada versi detail.
  final String? status;

  bool get isDraft => status == 'draft';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'slug': slug,
        'summary': summary,
        'thumbnail_url': thumbnailUrl,
        'tags': tags,
        'is_featured': isFeatured,
        'is_breaking': isBreaking,
        'views': views,
        'published_at': publishedAt?.toUtc().toIso8601String(),
        'category': category.toJson(),
        'author': author.toJson(),
        'content': content,
        'updated_at': updatedAt?.toUtc().toIso8601String(),
        'status': status,
      };
}

class Comment {
  const Comment({
    required this.id,
    required this.name,
    required this.content,
    this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> j) => Comment(
        id: _int(j['id']),
        name: j['name'] as String? ?? '',
        content: j['content'] as String? ?? '',
        createdAt: _date(j['created_at']),
      );

  final int id;
  final String name;
  final String content;
  final DateTime? createdAt;
}

class Paged<T> {
  const Paged({
    required this.items,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.hasNext,
  });

  final List<T> items;
  final int page;
  final int total;
  final int totalPages;
  final bool hasNext;
}
