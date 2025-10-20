// ignore_for_file: deprecated_member_use, unused_import, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';
import '../models/article.dart';
import '../api/api_service.dart';

class AuthorMagazineScreen extends StatefulWidget {
  final String author;
  final Article? initialArticle;
  const AuthorMagazineScreen({super.key, required this.author, this.initialArticle});

  @override
  State<AuthorMagazineScreen> createState() => _AuthorMagazineScreenState();
}

class _AuthorMagazineScreenState extends State<AuthorMagazineScreen> {
  late Future<List<Article>> _articlesFuture;
  final PageController _pageController = PageController(viewportFraction: 0.95);
  int _currentPage = 0;
  List<bool> _expandedList = [];
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _articlesFuture = _fetchAuthorArticles();
  }

  Future<List<Article>> _fetchAuthorArticles() async {
    final response = await ApiService.fetchArticlesByAuthor(widget.author);
    final articlesList = response['articles'] as List?;
    if (articlesList == null) return [];
    final articles = articlesList.map((data) => Article.fromJson(data)).toList();
    // 定位到初始文章
    if (widget.initialArticle != null) {
      final idx = articles.indexWhere((a) => a.id == widget.initialArticle!.id);
      if (idx >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _pageController.jumpToPage(idx);
          setState(() {
            _currentPage = idx;
          });
        });
      }
    }
    return articles;
  }

  void _initExpandedList(int length) {
    if (_expandedList.length != length) {
      _expandedList = List.filled(length, false);
    }
  }

  Future<void> _saveImageToGallery() async {
    try {
      final imageBytes = await _screenshotController.capture();
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('截图失败')),
        );
        return;
      }
      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: "${widget.author}_${DateTime.now().millisecondsSinceEpoch}",
      );
      if (result['isSuccess'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片已保存到相册'), backgroundColor: Colors.green),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败，请检查权限'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: FutureBuilder<List<Article>>(
        future: _articlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: \n${snapshot.error}'));
          }
          final articles = snapshot.data ?? [];
          _initExpandedList(articles.length);
          if (articles.isEmpty) {
            return const Center(child: Text('暂无作品'));
          }
          return SafeArea(
            child: Column(
              children: [
                // 顶部栏
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 28),
                        onPressed: () {
                          Navigator.of(context).maybePop();
                        },
                      ),
                      Text(
                        widget.author,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '第 ${_currentPage + 1} / ${articles.length} 篇',
                        style: const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.auto_awesome, color: Colors.deepPurple, size: 28),
                        tooltip: '切换风格',
                        onPressed: () {
                          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                            final articles = snapshot.data!;
                            Navigator.of(context).pushReplacementNamed(
                              '/authorWorks',
                              arguments: {
                                'author': widget.author,
                                'initialArticle': articles[_currentPage],
                              },
                            );
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.download, color: Colors.deepPurple, size: 26),
                        tooltip: '保存为图片',
                        onPressed: _saveImageToGallery,
                      ),
                    ],
                  ),
                ),
                // 内容区
                Expanded(
                  child: Center(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: articles.length,
                      physics: const BouncingScrollPhysics(), // 添加弹性滚动效果
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        return LayoutBuilder(
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
                                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
                                                          article.imageUrl,
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
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}