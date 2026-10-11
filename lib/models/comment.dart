class Comment {
  final int id;
  final String name;
  final String content;
  final DateTime createdAt;

  Comment({required this.id, required this.name, required this.content, required this.createdAt});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      name: json['name'],
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
