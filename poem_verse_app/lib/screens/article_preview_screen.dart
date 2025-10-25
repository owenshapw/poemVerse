// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/widgets/simple_network_image.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/models/poem.dart';
import 'package:poem_verse_app/services/local_storage_service.dart';
import 'package:uuid/uuid.dart';

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
  final bool isLocalMode; // 添加本地模式标记
  final Poem? localPoem; // 本地作品（用于编辑）

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
    this.isLocalMode = false,
    this.localPoem,
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
  
  // 保存本地作品
  Future<void> _saveLocalPoem() async {
    if (_isPublishing) return;
    setState(() { _isPublishing = true; });

    try {
      const uuid = Uuid();
      final poem = Poem(
        id: widget.localPoem?.id ?? uuid.v4(),
        title: widget.title,
        content: widget.content,
        imageUrl: widget.imageUrl,
        createdAt: widget.localPoem?.createdAt ?? DateTime.now(),
        synced: false,
        imageOffsetX: 0.0,
        imageOffsetY: widget.imageOffsetY ?? 0.0, // 使用从编辑页面传入的值
        imageScale: 1.0,
        author: widget.author,
        textPositionX: _textPositionX, // 保存调整后的文字位置
        textPositionY: _textPositionY,
      );
      
      await LocalStorageService.savePoem(poem);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEdit ? '修改已保存' : '作品已保存'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 返回 'saved' 状态，让编辑页面关闭
        Navigator.of(context).pop('saved');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isPublishing = false; });
      }
    }
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
            const SnackBar(content: Text('请先登录')),
          );
        }
        setState(() { _isPublishing = false; });
        return;
      }

      if (widget.isEdit && (widget.articleId == null || widget.articleId!.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('编辑模式下缺少文章ID')),
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
          const SnackBar(content: Text('发布失败')),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isPublishing = false; });
      }
    }
  }

  // 构建背景图片组件
  Widget _buildBackgroundImage(String imageUrl) {
    final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://');
    
    // 本地模式下，图片居中显示，不应用offset和缩放
    if (widget.isLocalMode && isLocalFile) {
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        alignment: Alignment.center, // 居中显示
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
            ),
          );
        },
      );
    } else if (isLocalFile) {
      // 非本地模式的本地文件（不应该出现）
      return Image.file(
        File(imageUrl),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 50),
            ),
          );
        },
      );
    } else {
      // 网络图片（云端模式）
      return SimpleNetworkImage(
        imageUrl: ApiService.getImageUrlWithVariant(imageUrl, 'public'),
        fit: BoxFit.cover,
      );
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
                  child: ClipRect(
                    clipBehavior: Clip.none, // 确保不裁剪阴影，与article_detail_screen保持一致
                    child: Center(
                      child: _buildArticleCard(),
                    ),
                  ),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // 确保所有元素垂直居中对齐
        children: [
          // 返回按钮 - 使用与author_works_screen一致的IconButton
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          
          // 中间的提示文本
          Expanded(
            child: Center(
              child: Text(
                '拖拽调整文字位置',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          
          // 保存/发布按钮 - 根据模式显示不同文本
          Container(
            height: 32, // 调整为与article_detail_screen一致的轻盈高度
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8), // 统一圆角
              border: Border.all(
                color: Colors.white.withOpacity(0.15),
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _isPublishing ? null : () async {
                  if (widget.isLocalMode) {
                    await _saveLocalPoem();
                  } else {
                    await _publishArticle();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // 调整内边距适应32px高度
                  child: _isPublishing 
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        )
                      : Text(
                          widget.isLocalMode ? '保存' : '发布',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12, // 调整字体大小适应轻盈设计
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard() {
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
      // 本地模式下，预览页面不应用offset（图片居中显示）
      imageOffsetX: widget.isLocalMode ? 0.0 : (widget.imageOffsetX ?? 0.0),
      imageOffsetY: widget.isLocalMode ? 0.0 : (widget.imageOffsetY ?? 0.0),
      imageScale: widget.isLocalMode ? 1.0 : (widget.imageScale ?? 1.0),
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
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16), // 增加顶部间距16px（从16改为32）
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
                  ? _buildBackgroundImage(article.imageUrl)
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
              right: 12.0,
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