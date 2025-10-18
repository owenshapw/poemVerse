// lib/screens/article_detail_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/screens/author_works_screen.dart';
import 'package:screenshot/screenshot.dart';

class ArticleDetailScreen extends StatefulWidget {
  final List<Article> articles;
  final int initialIndex;

  const ArticleDetailScreen({super.key, required this.articles, required this.initialIndex});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late PageController _pageController;
  late Article _article;
  bool _isDeleting = false;
  int _currentPage = 0;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex, viewportFraction: 0.95);
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
        Navigator.of(context).pop();
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
      Navigator.of(context).pop();
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            // 顶部栏 - 简洁设计
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // 返回按钮
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black54, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '返回',
                  ),
                  
                  // 作者名称
                  Expanded(
                    child: Text(
                      _article.author,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  // 右侧按钮组
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 作者权限按钮：编辑
                      if (_isAuthor(context)) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: Colors.black54, size: 20),
                          tooltip: '编辑',
                          onPressed: _isDeleting ? null : _editArticle,
                        ),
                      ],
                      
                      // 星星按钮（作品集）
                      IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Colors.black54, size: 20),
                        tooltip: '作品集',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AuthorWorksScreen(
                                author: _article.author,
                                initialArticle: _article,
                              ),
                        ),
                          );
                        },
                      ),
                      
                      // 作者权限按钮：删除
                      if (_isAuthor(context)) ...[
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          tooltip: '删除',
                          onPressed: _isDeleting ? null : _deleteArticle,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            // 内容区 - 采用author_magazine_screen样式
            Expanded(
              child: Container(
                // 为阴影提供额外的裁剪空间
                clipBehavior: Clip.none,
                child: Center(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: widget.articles.length,
                    physics: const BouncingScrollPhysics(),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                        _article = widget.articles[index];
                      });
                    },
                    itemBuilder: (context, index) {
                      final article = widget.articles[index];
                      return Container(
                      // 防止阴影被父容器裁剪
                      clipBehavior: Clip.none,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedBuilder(
                            animation: _pageController,
                            builder: (context, child) {
                              double scale = 1.0;
                              double opacity = 1.0;
                              
                              if (_pageController.position.haveDimensions) {
                                double page = _pageController.page ?? index.toDouble();
                                double distance = (page - index).abs();
                                
                                // 缩放计算：当前页面为1.0，相邻页面为0.8，更远的为0.7
                                if (distance <= 1.0) {
                                  scale = 1.0 - (distance * 0.2); // 范围 0.8-1.0
                                } else {
                                  scale = 0.7; // 更远的页面
                                }
                                
                                // 透明度计算
                                opacity = (1.0 - distance.clamp(0.0, 1.0) * 0.3).clamp(0.7, 1.0);
                              }
                              
                              final cardWidget = Center(
                                child: Transform.scale(
                                  scale: scale,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 24),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white.withOpacity(opacity),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15 * scale * opacity),
                                          blurRadius: 20 * scale,
                                          spreadRadius: 3 * scale,
                                          offset: Offset(0, 10 * scale),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          AspectRatio(
                                            aspectRatio: 4 / 2.8,
                                            child: article.imageUrl.isNotEmpty
                                                ? ColorFiltered(
                                                    colorFilter: ColorFilter.mode(
                                                      Colors.white.withOpacity(1.0 - opacity),
                                                      BlendMode.srcATop,
                                                    ),
                                                    child: Image.network(
                                                      ApiService.buildImageUrl(article.imageUrl),
                                                      fit: BoxFit.cover,
                                                      width: double.infinity,
                                                    ),
                                                  )
                                                : Container(color: Colors.grey[200]!.withOpacity(opacity)),
                                          ),
                                          Flexible(
                                            child: SingleChildScrollView(
                                              child: Padding(
                                                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      article.title,
                                                      style: TextStyle(
                                                        fontSize: 24,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.black.withOpacity(opacity),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    Text(
                                                      article.author,
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        color: Colors.black54.withOpacity(opacity),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 18),
                                                    Text(
                                                      article.content,
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        color: Colors.black87.withOpacity(opacity),
                                                        height: 1.6,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                              
                              // 只对当前页面应用Screenshot包装
                              if (index == _currentPage) {
                                return Screenshot(
                                  controller: _screenshotController,
                                  child: cardWidget,
                                );
                              } else {
                                return cardWidget;
                              }
                            },
                          );
                        },
                      ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  }