// lib/screens/article_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/widgets/simple_network_image.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:screenshot/screenshot.dart';

class ArticleDetailScreen extends StatefulWidget {
  final List<Article> articles;
  final int initialIndex;

  const ArticleDetailScreen({
    super.key,
    required this.articles,
    required this.initialIndex,
  });

  @override
  ArticleDetailScreenState createState() => ArticleDetailScreenState();
}

class ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late PageController _pageController;
  late Article _article;
  bool _isDeleting = false;
  int _currentPage = 0;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _article = widget.articles[widget.initialIndex];
    _currentPage = widget.initialIndex;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _isAuthor(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userId == _article.userId;
  }

  Future<void> _deleteArticle() async {
    if (_isDeleting) return;
    
    setState(() {
      _isDeleting = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      final token = authProvider.token!;
      final articleId = _article.id;

      final confirmed = await _showDeleteConfirmDialog();
      if (confirmed != true) {
        setState(() {
          _isDeleting = false;
        });
        return;
      }

      if (mounted) {
        _showLoadingDialog();
      }

      await articleProvider.deleteArticle(token, articleId);
      
      if (mounted) {
        _hideLoadingDialog();
        _showSuccessMessage('诗篇删除成功');
        Navigator.of(context).pop('deleted'); // 返回删除标记
      }
    } catch (e) {
      if (mounted) {
        _hideLoadingDialog();
        _showErrorMessage('删除失败：${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<bool?> _showDeleteConfirmDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('确认删除'),
          content: const Text('确定要删除这篇诗篇吗？删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  void _hideLoadingDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _editArticle() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateArticleScreen(
          article: _article,
          isEdit: true,
        ),
      ),
    );
    
    if (updated == true && mounted) {
      // 编辑成功后重新获取文章数据，更新当前显示
      try {
        // 清理图片缓存
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();

        
        final updatedArticle = await ApiService.getArticleDetail(_article.id);
        if (mounted) {
          setState(() {
            _article = updatedArticle;
            // 更新articles列表中的对应文章
            widget.articles[_currentPage] = updatedArticle;
          });

        }
      } catch (e) {

        // 如果刷新失败，仍然返回上一级
        if (mounted) {
          Navigator.of(context).pop();
        }
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
                  child: _buildArticleContent(),
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
        children: [
          // 返回按钮
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          // 作者名称和页面计数
          Expanded(
            child: Row(
              children: [
                Text(
                  _article.author,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.articles.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_currentPage + 1}/${widget.articles.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 右侧编辑和删除按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 编辑按钮（仅作者可见）
              if (_isAuthor(context)) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                  tooltip: '编辑',
                  onPressed: _isDeleting ? null : _editArticle,
                ),
                const SizedBox(width: 4),
              ],
              
              // 删除按钮（仅作者可见）
              if (_isAuthor(context)) ...[
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 22),
                  tooltip: '删除',
                  onPressed: _isDeleting ? null : _deleteArticle,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    if (widget.articles.isEmpty) {
      return const Center(
        child: Text(
          '暂无文章',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: widget.articles.length,
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        setState(() {
          _currentPage = index;
          _article = widget.articles[index];
        });
      },
      itemBuilder: (context, index) {
        final article = widget.articles[index];
        
        final card = _buildArticleCard(article);

        // 只对当前页面应用Screenshot包装
        if (index == _currentPage) {
          return Screenshot(
            controller: _screenshotController,
            child: card,
          );
        } else {
          return card;
        }
      },
    );
  }

  Widget _buildArticleCard(Article article) {
    // 确保与 article_preview_screen.dart 卡片尺寸一致
    final cardWidth = MediaQuery.of(context).size.width - 32;
    final textContainerWidth = cardWidth - 32;

    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          article.title, 
          style: const TextStyle(
            color: Colors.white, 
            fontSize: 28, 
            fontWeight: FontWeight.bold, 
            shadows: [
              Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4)
            ]
          )
        ),
        const SizedBox(height: 16),
        Text(
          article.author, 
          style: TextStyle(
            color: Colors.white.withOpacity(0.9), 
            fontSize: 17, 
            shadows: const [
              Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2)
            ]
          )
        ),
        const SizedBox(height: 20),
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              article.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.6,
                shadows: [
                  Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                  Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 5),
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
              left: article.textPositionX ?? 15.0,
              top: article.textPositionY ?? 200.0,
              bottom: 30.0,
              width: textContainerWidth,
              child: textContent,
            ),
          ],
        ),
      ),
    );
  }
}