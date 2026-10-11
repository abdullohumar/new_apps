class Comment {
  const Comment({required this.id, required this.name, required this.content, this.createdAt});

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json['id'] as int,
    name: json['name'] as String,
    content: json['content'] as String,
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? '')?.toLocal(),
  );

  final int id;
  final String name;
  final String content;
  final DateTime? createdAt;
}
