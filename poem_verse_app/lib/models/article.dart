// lib/models/article.dart
class Article {
  final String id;
  final String title;
  final String content;
  final String author;
  final String imageUrl;
  final List<String> tags;
  final String createdAt;

  Article({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.imageUrl,
    required this.tags,
    required this.createdAt,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      author: json['author'] ?? '匿名',
      imageUrl: json['image_url'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: json['created_at'] ?? '',
    );
  }
}
