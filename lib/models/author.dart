class Author {
  final int id;
  final String name;
  final String? bio;
  final String? avatarUrl;

  Author({required this.id, required this.name, this.bio, this.avatarUrl});

  // Contoh JSON:
  // { "id": 1, "name": "Rina Pratiwi", "bio": "...", "avatar_url": "https://..." }
  factory Author.fromJson(Map<String, dynamic> json) {
    // TODO: kembalikan Author(...) dengan mengambil nilai dari json['...']
    // Hint: perhatikan nama key di JSON pakai snake_case (avatar_url).
    throw UnimplementedError('Author.fromJson belum dibuat');
  }
}
