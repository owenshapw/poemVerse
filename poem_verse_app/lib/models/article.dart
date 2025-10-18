class Article {
  final String id;
  final String title;
  final String author;
  final String content;
  final String imageUrl;
  final String userId;
  final double? imageOffsetX;
  final double? imageOffsetY;
  final double? imageScale;
  final double? textPositionX;
  final double? textPositionY;

  Article({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
    required this.imageUrl,
    required this.userId,
    this.imageOffsetX,
    this.imageOffsetY,
    this.imageScale,
    this.textPositionX,
    this.textPositionY,
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    double? parseNum(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v is num) return v.toDouble();
        if (v is String) {
          final d = double.tryParse(v);
          if (d != null) return d;
        }
      }
      return null;
    }
    String parseStr(List<String> keys) {
      for (final k in keys) {
        final v = json[k];
        if (v != null) return v.toString();
      }
      return '';
    }

    return Article(
      id: parseStr(['id','article_id','_id']),
      title: parseStr(['title']),
      author: parseStr(['author']),
      content: parseStr(['content']),
      imageUrl: parseStr(['preview_image_url','image_url','imageUrl']),
      userId: parseStr(['user_id','userId','author_id']),
      imageOffsetX: parseNum(['image_offset_x','imageOffsetX']),
      imageOffsetY: parseNum(['image_offset_y','imageOffsetY']),
      imageScale: parseNum(['image_scale','imageScale']),
      textPositionX: parseNum(['text_position_x','textPositionX']),
      textPositionY: parseNum(['text_position_y','textPositionY']),
    );
  }
}
