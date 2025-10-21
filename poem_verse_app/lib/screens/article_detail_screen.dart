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
import 'package:flutter/services.dart';

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
  PageController? _pageController;
  late Article _article;
  bool _isDeleting = false;
  int _currentPage = 0;
  final ScreenshotController _screenshotController = ScreenshotController();
  
  // 可见性控制状态
  bool _isUpdatingVisibility = false;

  @override
  void initState() {
    super.initState();
    _article = widget.articles[widget.initialIndex];
    _currentPage = widget.initialIndex;
    
    // 延迟初始化PageController以避免动画冲突
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _pageController = PageController(
            initialPage: widget.initialIndex,
            viewportFraction: 1.0, // 全屏显示，不缩放
            keepPage: true,
          );
        });
      }
    });
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 确保 PageController 有正确的 viewportFraction 设置
    if (_pageController != null && _pageController!.hasClients) {
      _pageController!.dispose();
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
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

  Widget _buildVisibilityToggle() {
    // 使用与其他导航按钮一致的轻盈风格
    return Container(
      height: 32, // 与其他导航按钮保持一致的轻盈高度
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
          onTap: _isUpdatingVisibility ? null : _toggleArticleVisibility,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isUpdatingVisibility) ...[
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.9)),
                    ),
                  ),
                ] else ...[
                  Icon(
                    _article.isPublicVisible ? Icons.public : Icons.lock,
                    color: Colors.white.withOpacity(0.9),
                    size: 14,
                  ),
                ],
                const SizedBox(width: 4),
                Text(
                  _article.isPublicVisible ? '公开' : '私密',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleArticleVisibility() async {
    if (_isUpdatingVisibility) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    
    if (token == null) {
      _showErrorMessage('请先登录');
      return;
    }

    final newVisibility = !_article.isPublicVisible;
    
    setState(() {
      _isUpdatingVisibility = true;
    });
    
    try {
      // 显示加载状态
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('正在${newVisibility ? '公开' : '隐藏'}作品...'),
          duration: const Duration(seconds: 1),
        ),
      );

      // 调用API更新可见性
      final result = await ApiService.updateArticleVisibility(
        token,
        _article.id,
        newVisibility,
      );

      if (result['success'] == true) {
        // 更新本地状态
        setState(() {
          _article = Article(
            id: _article.id,
            title: _article.title,
            author: _article.author,
            content: _article.content,
            imageUrl: _article.imageUrl,
            userId: _article.userId,
            imageOffsetX: _article.imageOffsetX,
            imageOffsetY: _article.imageOffsetY,
            imageScale: _article.imageScale,
            textPositionX: _article.textPositionX,
            textPositionY: _article.textPositionY,
            isPublicVisible: newVisibility,
          );
          
          // 同时更新articles列表中的对应文章
          widget.articles[_currentPage] = _article;
        });

        // 显示成功提示
        HapticFeedback.lightImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('作品已${newVisibility ? '公开' : '隐藏'}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('服务器返回失败状态');
      }
    } catch (e) {
      // 显示错误提示
      _showErrorMessage('更新失败: ${e.toString().contains('Exception:') ? e.toString().split('Exception: ')[1] : e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingVisibility = false;
        });
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 返回按钮 - 优雅轻盈的设计
          _buildNavButton(
            icon: Icons.arrow_back_ios_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          const SizedBox(width: 12),
          
          // 页面计数 - 居中显示
          Expanded(
            child: Center(
              child: widget.articles.isNotEmpty
                  ? _buildNavTextButton(
                      text: '${_currentPage + 1}/${widget.articles.length}',
                      onPressed: null, // 页面计数不可点击
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 右侧编辑和删除按钮
          if (_isAuthor(context))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 编辑按钮
                _buildNavButton(
                  icon: Icons.edit_outlined,
                  onPressed: (_isDeleting || _isUpdatingVisibility) ? null : _editArticle,
                ),
                
                const SizedBox(width: 8),
                
                // 可见性控制按钮
                _buildVisibilityToggle(),
                
                const SizedBox(width: 8),
                
                // 删除按钮 - 改为白色
                _buildNavButton(
                  icon: Icons.delete_outline,
                  iconColor: Colors.white,
                  onPressed: (_isDeleting || _isUpdatingVisibility) ? null : _deleteArticle,
                ),
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

    if (_pageController == null) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return ClipRect(
      clipBehavior: Clip.none, // 确保不裁剪阴影
      child: PageView.builder(
        itemCount: widget.articles.length,
        controller: _pageController!,
        // 添加缓存页面以提高性能
        allowImplicitScrolling: true,
        clipBehavior: Clip.none, // 关键修复：不裁剪阴影
        physics: const BouncingScrollPhysics(), // 添加弹性滚动效果
        onPageChanged: (index) {
          if (mounted) {
            HapticFeedback.lightImpact();
            setState(() {
              _currentPage = index;
              _article = widget.articles[index];
            });
          }
        },
        itemBuilder: (context, index) {
          final article = widget.articles[index];
          
          return AnimatedBuilder(
            animation: _pageController!,
            builder: (context, child) {
              double scale = 1.0;
              double opacity = 1.0;
              
              // 正常动画计算
              double page = _currentPage.toDouble();
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
                scale = index == _currentPage ? 1.0 : 0.75;
              }
              
              // 透明度计算
              opacity = (1.0 - distance.clamp(0.0, 1.0) * 0.25).clamp(0.75, 1.0);
              
              // 确保 opacity 是有效数值
              if (opacity.isNaN || !opacity.isFinite) {
                opacity = index == _currentPage ? 1.0 : 0.75;
              }
            
              // 最终安全检查：确保所有数值都是有效的
              final safeScale = (scale.isNaN || !scale.isFinite || scale <= 0) ? 1.0 : scale.clamp(0.1, 2.0);
              final safeOpacity = (opacity.isNaN || !opacity.isFinite) ? 1.0 : opacity.clamp(0.0, 1.0);
              
              final card = Center(
                child: Transform.scale(
                  scale: safeScale,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 32, 16, 16), // 增加顶部间距16px（从16改为32）
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
                        _buildArticleCard(article, safeOpacity),
                      ],
                    ),
                  ),
                ),
              );

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
      },
      ),
    );
  }

  Widget _buildArticleCard(Article article, [double opacity = 1.0]) {
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: article.imageUrl.isNotEmpty
                ? SimpleNetworkImage(
                    imageUrl: ApiService.getImageUrlWithVariant(article.imageUrl, 'public'),
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
          ),
          // 渐变遮罩
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
          // 文本内容 - 恢复原始的布局设置
          Positioned(
            left: article.textPositionX ?? 15.0,
            top: article.textPositionY ?? 200.0,
            bottom: 30.0,
            right: 12.0,
            child: textContent,
          ),
                ],
      ),
    );
  }

  /// 优雅轻盈的统一导航按钮样式
  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? iconColor,
    double? width,
  }) {
    return Container(
      height: 32, // 轻盈的高度
      width: width ?? 32, // 默认方形，可自定义宽度
      decoration: BoxDecoration(
        color: (backgroundColor ?? Colors.white).withOpacity(0.12),
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
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.all(6), // 精致的内边距
            child: Icon(
              icon,
              color: (iconColor ?? Colors.white).withOpacity(0.9),
              size: 18, // 统一的图标尺寸
            ),
          ),
        ),
      ),
    );
  }

  /// 优雅轻盈的文本按钮样式
  Widget _buildNavTextButton({
    required String text,
    required VoidCallback? onPressed,
    Color? backgroundColor,
    Color? textColor,
    Widget? leading,
  }) {
    return Container(
      height: 32, // 与图标按钮保持一致的高度
      decoration: BoxDecoration(
        color: (backgroundColor ?? Colors.white).withOpacity(0.12),
        borderRadius: BorderRadius.circular(16), // 更圆润的设计
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
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (leading != null) ...[
                  leading,
                  const SizedBox(width: 4),
                ],
                Text(
                  text,
                  style: TextStyle(
                    color: (textColor ?? Colors.white).withOpacity(0.95),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}