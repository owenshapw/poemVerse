// lib/screens/author_works_screen.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 添加触觉反馈
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/widgets/interactive_image_preview.dart';
import 'dart:ui';
import 'package:screenshot/screenshot.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:provider/provider.dart';


class AuthorWorksScreen extends StatefulWidget {
  final String author;
  final Article initialArticle;

  const AuthorWorksScreen({
    super.key,
    required this.author,
    required this.initialArticle,
  });

  @override
  State<AuthorWorksScreen> createState() => _AuthorWorksScreenState();
}

// 独立的文本组件，避免重复构建 - 使用和 ArticlePreviewScreen 相同的样式
class _ArticleText extends StatelessWidget {
  final Article article;

  const _ArticleText({required this.article});

  @override
  Widget build(BuildContext context) {
    return Column(
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
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          article.author,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 17,
            shadows: const [
              Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2)
            ],
          ),
        ),
        const SizedBox(height: 20),
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              article.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17, // 保持增大的字体大小
                height: 1.6,
                shadows: [
                  Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2),
                  Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 5), // 增强的阴影
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthorWorksScreenState extends State<AuthorWorksScreen> {
  List<Article> _articles = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;
  final ScreenshotController _screenshotController = ScreenshotController();
  PageController? _pageController;
  
  // 点赞状态管理
  final Map<String, bool> _likedArticles = {};
  final Map<String, int> _likeCounts = {};
  

  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保 PageController 有正确的 viewportFraction 设置
    if (_pageController != null && _pageController!.hasClients) {
      _pageController!.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAuthorArticles();
  }

  // 预加载相邻页面的图片
  void _preloadImages() {
    if (_articles.isEmpty) return;
    
    final currentIndex = _currentIndex;
    final imagesToPreload = <String>[];
    
    // 预加载当前页面前后各2页的图片
    for (int i = -2; i <= 2; i++) {
      final index = currentIndex + i;
      if (index >= 0 && index < _articles.length) {
        final imageUrl = _articles[index].imageUrl;
        if (imageUrl.isNotEmpty) {
          imagesToPreload.add(ApiService.getImageUrlWithVariant(imageUrl, 'public'));
        }
      }
    }
    
    // 预加载图片到缓存
    for (final imageUrl in imagesToPreload) {
      precacheImage(NetworkImage(imageUrl), context);
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadAuthorArticles() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // 获取当前用户token以支持可见性过滤
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUserToken = authProvider.token;
      
      final response = await ApiService.fetchArticlesByAuthor(widget.author, token: currentUserToken);
      final articlesList = response['articles'] as List?;
      
      if (articlesList != null && articlesList.isNotEmpty) {
        final articles = articlesList.map((data) => Article.fromJson(data)).toList();
        
        final initialIndex = articles.indexWhere((article) => article.id == widget.initialArticle.id);
        final startIndex = initialIndex >= 0 ? initialIndex : 0;
        
        if (!mounted) return;
        setState(() {
          _articles = articles;
          _currentIndex = startIndex;
          _isLoading = false;
        });
        
        // 从持久化存储加载点赞状态
        await _loadLikeStates();
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              // 使用 viewportFraction 来支持卡片缩放动画
              _pageController = PageController(
                initialPage: startIndex,
                viewportFraction: 0.95, // 增大卡片显示比例
                keepPage: true, // 保持页面状态
              );
            });
            // 简化初始化逻辑，减少不必要的动画
            // 移除了额外的 Future.delayed 和 setState 调用
            // 延迟预加载图片
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) _preloadImages();
            });
          }
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage = '没有找到该作者的文章';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveImageToGallery() async {
    try {
      final platform = Theme.of(context).platform;
      
      if (platform == TargetPlatform.iOS) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正在生成图片...')),
          );
        }

        await Future.delayed(const Duration(milliseconds: 100));

        final Uint8List? imageBytes = await _screenshotController.capture();
        
        if (imageBytes == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('截图失败')),
            );
          }
          return;
        }

        try {
          final result = await ImageGallerySaver.saveImage(
            imageBytes,
            quality: 100,
            name: "${_articles[_currentIndex].title}_${widget.author}",
          );

          if (mounted) {
            if (result['isSuccess'] == true) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('图片已保存到相册'),
                  backgroundColor: Colors.green,
                ),
              );
            } else {
              _showPermissionDialog();
            }
          }
        } catch (e) {
          if (mounted) {
            _showPermissionDialog();
          }
        }
        return;
      }

      var status = await Permission.photos.status;
      if (!status.isGranted) {
        status = await Permission.photos.request();
        if (!status.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('需要相册权限才能保存图片'),
                action: SnackBarAction(
                  label: '去设置',
                  onPressed: () {
                    openAppSettings();
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      var storageStatus = await Permission.storage.status;
      if (!storageStatus.isGranted) {
        storageStatus = await Permission.storage.request();
        if (!storageStatus.isGranted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('需要存储权限才能保存图片'),
                action: SnackBarAction(
                  label: '去设置',
                  onPressed: () {
                    openAppSettings();
                  },
                ),
                duration: const Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('正在生成图片...')),
        );
      }

      await Future.delayed(const Duration(milliseconds: 100));

      final Uint8List? imageBytes = await _screenshotController.capture();
      
      if (imageBytes == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('截图失败')),
          );
        }
        return;
      }

      final result = await ImageGallerySaver.saveImage(
        imageBytes,
        quality: 100,
        name: "${_articles[_currentIndex].title}_${widget.author}",
      );

      if (mounted) {
        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片已保存到相册'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('保存失败，请检查权限设置'),
              action: SnackBarAction(
                label: '去设置',
                onPressed: () {
                  openAppSettings();
                },
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
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
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要照片权限'),
        content: const Text(
          '要保存诗篇图片到相册，需要照片权限.\n\n'
          '请在设置中：\n'
          '1. 找到"Poem Verse App"\n'
          '2. 点击"照片"\n'
          '3. 选择"所有照片"\n\n'
          '如果只显示"选中的照片"，请先选择"所有照片"再返回。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  // 从服务器加载点赞状态
  Future<void> _loadLikeStates() async {
    try {
      // 批量从服务器获取点赞信息
      final articleIds = _articles.map((a) => a.id).toList();
      final response = await ApiService.getBatchArticleLikes(articleIds);
      
      // 更新点赞状态
      for (final article in _articles) {
        final likeInfo = response[article.id];
        if (likeInfo != null) {
          _likedArticles[article.id] = likeInfo['is_liked_by_user'] ?? false;
          _likeCounts[article.id] = likeInfo['like_count'] ?? 0;
        } else {
          _likedArticles[article.id] = false;
          _likeCounts[article.id] = 0;
        }
      }
      
      if (mounted) {
        setState(() {});
      }
      
    } catch (e) {

      
      // 服务器调用失败，尝试从本地存储加载作为备用方案
      try {
        final prefs = await SharedPreferences.getInstance();
        for (final article in _articles) {
          final isLiked = prefs.getBool('liked_${article.id}') ?? false;
          _likedArticles[article.id] = isLiked;
          
          final likeCount = prefs.getInt('like_count_${article.id}') ?? 0;
          _likeCounts[article.id] = likeCount;
        }
        
        if (mounted) {
          setState(() {});
        }
      } catch (localError) {

        // 如果都失败，使用默认状态
        for (final article in _articles) {
          _likedArticles[article.id] = false;
          _likeCounts[article.id] = 0;
        }
      }
    }
  }

  // 保存点赞状态到本地存储（作为备用缓存）
  Future<void> _saveLikeStateToLocal(String articleId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 保存点赞状态
      await prefs.setBool('liked_$articleId', _likedArticles[articleId] ?? false);
      
      // 保存点赞计数
      await prefs.setInt('like_count_$articleId', _likeCounts[articleId] ?? 0);
    } catch (e) {
      // 保存本地点赞状态失败时不做任何处理
    }
  }

  // 点赞功能 - 使用服务器API
  void _toggleLike(String articleId) async {
    final isCurrentlyLiked = _likedArticles[articleId] ?? false;
    final newLikedState = !isCurrentlyLiked;
    
    // 先更新UI（乐观更新）
    setState(() {
      _likedArticles[articleId] = newLikedState;
      
      if (newLikedState) {
        // 点赞
        _likeCounts[articleId] = (_likeCounts[articleId] ?? 0) + 1;
        HapticFeedback.lightImpact();
      } else {
        // 取消点赞
        _likeCounts[articleId] = ((_likeCounts[articleId] ?? 1) - 1).clamp(0, double.infinity).toInt();
        HapticFeedback.selectionClick();
      }
    });
    
    try {
      // 调用服务器API
      final result = await ApiService.toggleArticleLike(articleId, newLikedState);
      
      if (result['success'] == true) {
        // 使用服务器返回的真实数据更新
        if (mounted) {
          setState(() {
            _likedArticles[articleId] = result['is_liked'] ?? newLikedState;
            _likeCounts[articleId] = result['like_count'] ?? _likeCounts[articleId];
          });
        }
        
        // 同时保存到本地作为缓存
        await _saveLikeStateToLocal(articleId);
      } else {
        throw Exception('服务器返回失败状态: $result');
      }
      
    } catch (e) {
      // 如果服务器调用失败，回滚UI状态

      
      if (mounted) {
        setState(() {
          _likedArticles[articleId] = isCurrentlyLiked; // 回滚
          if (isCurrentlyLiked) {
            _likeCounts[articleId] = (_likeCounts[articleId] ?? 0) + 1;
          } else {
            _likeCounts[articleId] = ((_likeCounts[articleId] ?? 1) - 1).clamp(0, double.infinity).toInt();
          }
        });
        
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('点赞失败: ${e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : '网络连接问题'}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF232946),
      body: Stack(
        children: [
          // Background - 保持与 ArticlePreviewScreen 完全相同
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
          ),// Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: ClipRect(
                    clipBehavior: Clip.none, // 确保不裁剪阴影
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : _errorMessage != null
                            ? Center(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              )
                            : _buildArticleContent(),
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
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          Expanded(
            child: Row(
              children: [
                Text(
                  widget.author,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_articles.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    height: 32, // 与其他按钮保持一致的高度
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    child: Text(
                      '${_currentIndex + 1}/${_articles.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 点赞按钮和计数 - 移到中间位置
          if (_articles.isNotEmpty) ...[
            GestureDetector(
              onTap: () => _toggleLike(_articles[_currentIndex].id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _likedArticles[_articles[_currentIndex].id] == true 
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _likedArticles[_articles[_currentIndex].id] == true 
                          ? Colors.red.shade300.withOpacity(0.9)
                          : Colors.white.withOpacity(0.7),
                      size: 22,
                    ),
                    if (_likeCounts[_articles[_currentIndex].id] != null && 
                        _likeCounts[_articles[_currentIndex].id]! > 0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${_likeCounts[_articles[_currentIndex].id]}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.download, color: Colors.white, size: 24),
              tooltip: '保存为图片',
              onPressed: _saveImageToGallery,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    if (_articles.isEmpty) {
      return const Center(
        child: Text(
          '暂无作品',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    if (_pageController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return PageView.builder(
      itemCount: _articles.length,
      controller: _pageController!,
      // 添加缓存页面以提高性能
      allowImplicitScrolling: true,
      clipBehavior: Clip.none, // 关键修复：不裁剪阴影
      physics: const BouncingScrollPhysics(), // 添加弹性滚动效果
      onPageChanged: (index) {
        if (mounted) {
          HapticFeedback.selectionClick();
          setState(() {
            _currentIndex = index;
          });
          // 减少预加载延迟，提高响应速度
          _preloadImages();
        }
      },
      itemBuilder: (context, index) {
        final article = _articles[index];
        
            return AnimatedBuilder(
              animation: _pageController!,
              builder: (context, child) {
                double scale = 1.0;
                double opacity = 1.0;
                
                // 正常动画计算
                double page = _currentIndex.toDouble();
                  if (_pageController!.hasClients && _pageController!.position.haveDimensions) {
                    final currentPage = _pageController!.page;
                    if (currentPage != null && !currentPage.isNaN && currentPage.isFinite) {
                      page = currentPage;
                    }
                  }
                      
                  double distance = (page - index).abs();
                  
                  // 确保 distance 是有效数值
                  if (distance.isNaN || !distance.isFinite) {
                    distance = 0.0;
                  }
                  
                  // 缩放计算：当前页面为1.0，相邻页面为0.85，更远的为0.75
                  if (distance <= 1.0) {
                    scale = 1.0 - (distance * 0.15); // 范围 0.85-1.0
                  } else {
                    scale = 0.75; // 更远的页面
                  }
                  
                  // 确保 scale 是有效数值
                  if (scale.isNaN || !scale.isFinite || scale < 0.1) {
                    scale = index == _currentIndex ? 1.0 : 0.75;
                  }
                  
                  // 透明度计算
                  opacity = (1.0 - distance.clamp(0.0, 1.0) * 0.25).clamp(0.75, 1.0);
                  
                  // 确保 opacity 是有效数值
                  if (opacity.isNaN || !opacity.isFinite) {
                    opacity = index == _currentIndex ? 1.0 : 0.75;
                  }
                
                // 最终安全检查：确保所有数值都是有效的
                final safeScale = (scale.isNaN || !scale.isFinite || scale <= 0) ? 1.0 : scale.clamp(0.1, 2.0);
                final safeOpacity = (opacity.isNaN || !opacity.isFinite) ? 1.0 : opacity.clamp(0.0, 1.0);
                
                final card = Center(
                  child: Transform.scale(
                    scale: safeScale,
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(8, 16, 8, 16),
                      child: Stack(
                        children: [
                          // 阴影层 - 直接渲染到背景上
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3 * safeOpacity),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                )
                              ],
                            ),
                          ),
                          // 卡片内容
                          _buildArticleCardContent(context, article, safeOpacity),
                        ],
                      ),
                    ),
                  ),
                );

                // 只对当前页面应用Screenshot包装
                if (index == _currentIndex) {
                  return Screenshot(
                    controller: _screenshotController,
                    child: card,
                  );
                } else {
                  return card;
                }
              },
            );
      },
    );
  }

  

  Widget _buildArticleCardContent(BuildContext context, Article article, [double opacity = 1.0]) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: article.imageUrl.isNotEmpty
                ? InteractiveImagePreview(
                    imageUrl: ApiService.getImageUrlWithVariant(article.imageUrl, 'public'),
                    width: double.infinity,
                    height: double.infinity,
                    initialOffsetX: 0.0, // 作品集页面不应用 offset
                    initialOffsetY: 0.0, // 作品集页面不应用 offset
                    initialScale: 1.0, // 作品集页面不应用 scale
                    isInteractive: false,
                    fit: BoxFit.cover,
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(
                        Icons.image,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  ),
          ),// 渐变遮罩 - 使用和 ArticlePreviewScreen 相同的样式
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.1),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // 文本内容
          Positioned(
            left: article.textPositionX ?? 15.0,
            top: article.textPositionY ?? 200.0,
            bottom: 30.0,
            right: 12.0,
            child: _ArticleText(article: article),
          ),
        ],
      ),
    );
  }


}