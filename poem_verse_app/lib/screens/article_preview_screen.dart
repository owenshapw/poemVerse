// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/widgets/simple_network_image.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:poem_verse_app/config/app_config.dart';

import 'package:poem_verse_app/providers/article_provider.dart';

class ArticlePreviewScreen extends StatefulWidget {
  final String title;
  final String content;
  final String author;
  final String? imageUrl;
  final double initialTextPositionX;
  final double initialTextPositionY;
  final String? articleId; // 添加文章ID参数
  final bool isEdit; // 添加编辑模式参数
  final double? imageOffsetX; // 添加图片变换参数
  final double? imageOffsetY;
  final double? imageScale;

  const ArticlePreviewScreen({
    super.key,
    required this.title,
    required this.content,
    required this.author,
    this.imageUrl,
    required this.initialTextPositionX,
    required this.initialTextPositionY,
    this.articleId,
    this.isEdit = false,
    this.imageOffsetX,
    this.imageOffsetY,
    this.imageScale,
  });

  @override
  ArticlePreviewScreenState createState() => ArticlePreviewScreenState();
}

class ArticlePreviewScreenState extends State<ArticlePreviewScreen> {
  late double _textPositionX;
  late double _textPositionY;
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _textPositionX = widget.initialTextPositionX;
    _textPositionY = widget.initialTextPositionY;
  }
  
  Future<void> _publishArticle() async {
    if (_isPublishing) return;
    setState(() { _isPublishing = true; });

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.token ?? '';

      if (token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('请先登录')),
          );
        }
        setState(() { _isPublishing = false; });
        return;
      }

      if (widget.isEdit && (widget.articleId == null || widget.articleId!.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('编辑模式下缺少文章ID')),
          );
        }
        setState(() { _isPublishing = false; });
        return;
      }



      if (widget.isEdit && widget.articleId != null) {
        // 编辑模式：使用 ArticleProvider 的更新方法
        final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
        
        await articleProvider.updateArticle(
          token,
          widget.articleId!,
          widget.title,
          widget.content,
          [], // tags
          widget.author,
          auth.userId!,
          previewImageUrl: widget.imageUrl,
          textPositionX: _textPositionX,
          textPositionY: _textPositionY,
          imageOffsetX: 0.0, // 固定为0，不允许横向移动
          imageOffsetY: widget.imageOffsetY ?? 0.0, // 只允许纵向偏移
          imageScale: 1.0, // 固定为1，不允许缩放
        );
        

      } else {
        // 新建模式：使用创建 API
        final body = {
          'title': widget.title,
          'content': widget.content,
          'author': widget.author,
          'preview_image_url': widget.imageUrl ?? '',
          'text_position_x': _textPositionX,
          'text_position_y': _textPositionY,
          'image_offset_x': 0.0, // 固定为0，不允许横向移动
          'image_offset_y': widget.imageOffsetY ?? 0.0, // 只允许纵向偏移
          'image_scale': 1.0, // 固定为1，不允许缩放
        };



        final response = await http.post(
          Uri.parse('${AppConfig.backendApiUrl}/articles'),
          headers: {
            'Content-Type': 'application/json; charset=UTF-8',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        );


        
        if (response.statusCode != 201 && response.statusCode != 200) {
          throw Exception('创建文章失败: ${response.statusCode}');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEdit ? '更新成功' : '发布成功')),
        );
        
        // 立即返回，让目标页面处理缓存清理
        Navigator.of(context).pop('published');
      }
    } catch (e) {

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('发布失败')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isPublishing = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232946),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF764ba2),
                ],
              ),
            ),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildArticleCard(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              Text(
                '拖拽调整文字位置',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ElevatedButton(
            onPressed: _isPublishing ? null : () async {
              // 使用和create_article_screen相同的发布逻辑
              await _publishArticle();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: _isPublishing 
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('发布'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard() {
    final cardWidth = MediaQuery.of(context).size.width - 32;
    final textContainerWidth = cardWidth - 32;

    // get current user id if AuthProvider is available, otherwise empty
    String currentUserId = '';
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      currentUserId = auth.userId ?? '';
    } catch (_) {
      // provider not found — keep empty
    }

    final article = Article(
      id: '',
      title: widget.title,
      author: widget.author,
      content: widget.content,
      imageUrl: widget.imageUrl ?? '',
      userId: currentUserId,
    );

    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(article.title, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4)])),
        const SizedBox(height: 16),
        Text(article.author, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 17, shadows: const [Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2)])),
        const SizedBox(height: 20),
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              article.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17, // Increased font size
                height: 1.6,
                shadows: [
                  Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                  Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 5), // Enhanced shadow
                ],
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      width: cardWidth,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: article.imageUrl.isNotEmpty
                  ? SimpleNetworkImage(imageUrl: ApiService.getImageUrlWithVariant(article.imageUrl, 'public'), fit: BoxFit.cover)
                  : Container(color: Colors.grey[200]),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.85)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: _textPositionX,
              top: _textPositionY,
              bottom: 30.0,
              width: textContainerWidth,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _textPositionX += details.delta.dx;
                    _textPositionY += details.delta.dy;
                  });
                },
                child: textContent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}