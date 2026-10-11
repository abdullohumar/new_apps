class Author {
  const Author({required this.id, required this.name, required this.slug, this.bio, this.avatarUrl});

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: json['id'] as int,
    name: json['name'] as String,
    slug: json['slug'] as String,
    bio: json['bio'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );

  final int id;
  final String name;
  final String slug;
  final String? bio;
  final String? avatarUrl;
}
