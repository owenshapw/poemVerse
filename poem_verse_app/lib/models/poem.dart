import 'package:hive/hive.dart';
import 'package:poem_verse_app/models/article.dart';

part 'poem.g.dart';

@HiveType(typeId: 0)
class Poem extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String content;

  @HiveField(3)
  String? imageUrl;

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  bool synced;

  @HiveField(6)
  double? imageOffsetX;

  @HiveField(7)
  double? imageOffsetY;

  @HiveField(8)
  double? imageScale;

  @HiveField(9)
  String? author;

  @HiveField(10)
  double? textPositionX;

  @HiveField(11)
  double? textPositionY;

  Poem({
    required this.id,
    required this.title,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    this.synced = false,
    this.imageOffsetX,
    this.imageOffsetY,
    this.imageScale,
    this.author,
    this.textPositionX,
    this.textPositionY,
  });

  // 转换为 Article 对象（用于上传到云端）
  Article toArticle(String userId, String authorName) {
    return Article(
      id: id,
      title: title,
      author: authorName,
      content: content,
      imageUrl: imageUrl ?? '',
      userId: userId,
      imageOffsetX: imageOffsetX,
      imageOffsetY: imageOffsetY,
      imageScale: imageScale,
      isPublicVisible: false, // 本地模式下默认私有
    );
  }

  // 从 Article 对象创建 Poem（用于云端下载）
  factory Poem.fromArticle(Article article) {
    return Poem(
      id: article.id,
      title: article.title,
      content: article.content,
      imageUrl: article.imageUrl,
      createdAt: DateTime.now(), // 使用当前时间，因为 Article 可能没有这个字段
      synced: true, // 从云端来的默认已同步
      imageOffsetX: article.imageOffsetX,
      imageOffsetY: article.imageOffsetY,
      imageScale: article.imageScale,
      author: article.author,
    );
  }

  // 转换为 JSON（用于 API 上传）
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'image_offset_x': imageOffsetX,
      'image_offset_y': imageOffsetY,
      'image_scale': imageScale,
    };
  }

  // 从 JSON 创建 Poem
  factory Poem.fromJson(Map<String, dynamic> json) {
    return Poem(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      synced: json['synced'] ?? false,
      imageOffsetX: json['image_offset_x']?.toDouble(),
      imageOffsetY: json['image_offset_y']?.toDouble(),
      imageScale: json['image_scale']?.toDouble(),
      author: json['author'],
    );
  }

  // 复制对象
  Poem copyWith({
    String? id,
    String? title,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    bool? synced,
    double? imageOffsetX,
    double? imageOffsetY,
    double? imageScale,
    String? author,
  }) {
    return Poem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      synced: synced ?? this.synced,
      imageOffsetX: imageOffsetX ?? this.imageOffsetX,
      imageOffsetY: imageOffsetY ?? this.imageOffsetY,
      imageScale: imageScale ?? this.imageScale,
      author: author ?? this.author,
    );
  }
}
