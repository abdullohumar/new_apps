class Comment {
  final int id;
  final String name;
  final String content;
  final DateTime createdAt;

  Comment({required this.id, required this.name, required this.content, required this.createdAt});

  // Contoh JSON:
  // { "id": 4, "name": "Putri", "content": "...", "created_at": "2026-10-11T04:15:00+00:00" }
  factory Comment.fromJson(Map<String, dynamic> json) {
    // TODO: kembalikan Comment(...) dari json
    // Hint: created_at berupa String, ubah dengan DateTime.parse(...).toLocal()
    throw UnimplementedError('Comment.fromJson belum dibuat');
  }
}
