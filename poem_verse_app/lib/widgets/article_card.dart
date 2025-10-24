// ignore_for_file: deprecated_member_use, dead_code

import 'package:flutter/material.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/widgets/simple_network_image.dart';

import 'package:poem_verse_app/api/api_service.dart';

class ArticleCard extends StatefulWidget {
  final Article article;
  final bool isDraggable;
  final bool isPublished;
  final Function(Offset)? onPositionChanged;

  const ArticleCard({
    super.key,
    required this.article,
    this.isDraggable = false,
    this.isPublished = false,
    this.onPositionChanged,
  });

  @override
  State<ArticleCard> createState() => _ArticleCardState();
}

class _ArticleCardState extends State<ArticleCard> {
  late Offset _textPosition;

  @override
  void initState() {
    super.initState();
    _textPosition = Offset(
      widget.article.textPositionX ?? 50,
      widget.article.textPositionY ?? 50,
    );
  }

  @override
  void didUpdateWidget(ArticleCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.article.textPositionX != oldWidget.article.textPositionX ||
        widget.article.textPositionY != oldWidget.article.textPositionY) {
      setState(() {
        _textPosition = Offset(
          widget.article.textPositionX ?? 50,
          widget.article.textPositionY ?? 50,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: SimpleNetworkImage(
                imageUrl: ApiService.getImageUrlWithVariant(
                  widget.article.imageUrl,
                  'public',
                ),
                fit: BoxFit.cover,
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.2),
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: [
                      Positioned(
                        left: _textPosition.dx,
                        top: _textPosition.dy,
                        child: GestureDetector(
                          onPanUpdate: widget.isDraggable
                              ? (details) {
                                  setState(() {
                                    _textPosition += details.delta;
                                  });
                                  widget.onPositionChanged?.call(_textPosition);
                                }
                              : null,
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth * 0.85,
                              maxHeight: constraints.maxHeight * 0.7,
                            ),
                            child: Container(
                              color: Colors.transparent,
                              child: widget.isPublished
                                  ? SingleChildScrollView(
                                      child: _buildTextContent(),
                                    )
                                  : _buildTextContent(maxLines: 5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextContent({int? maxLines}) {
   

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.article.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          widget.article.author,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 16,

          ),
        ),
        const SizedBox(height: 20),
        Text(
          widget.article.content,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            height: 1.6,
          ),
          maxLines: maxLines,
          overflow: maxLines != null
              ? TextOverflow.ellipsis
              : TextOverflow.visible,
        ),
      ],
    );
  }
}
