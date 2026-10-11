class Author {
  final int id;
  final String name;
  final String? bio;
  final String? avatarUrl;

  Author({required this.id, required this.name, this.bio, this.avatarUrl});

  factory Author.fromJson(Map<String, dynamic> json) {
    return Author(id: json['id'], name: json['name'], bio: json['bio'], avatarUrl: json['avatar_url']);
  }
}
