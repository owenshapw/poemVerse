import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:poem_verse_app/models/poem.dart';
import 'package:poem_verse_app/services/local_storage_service.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/widgets/interactive_image_preview.dart';
import 'package:screenshot/screenshot.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
import 'package:poem_verse_app/utils/network_init_helper.dart';

class LocalPoemDetailScreen extends StatefulWidget {
  final List<Poem> poems;
  final int initialIndex;

  const LocalPoemDetailScreen({
    super.key,
    required this.poems,
    required this.initialIndex,
  });

  // 为了兼容旧的调用方式，提供一个工厂构造函数
  factory LocalPoemDetailScreen.single({Key? key, required Poem poem}) {
    // 获取所有诗章
    final allPoems = LocalStorageService.getAllPoems();
    // 找到当前诗章在列表中的位置
    final index = allPoems.indexWhere((p) => p.id == poem.id);
    
    return LocalPoemDetailScreen(
      key: key,
      poems: allPoems,
      initialIndex: index >= 0 ? index : 0,
    );
  }

  @override
  LocalPoemDetailScreenState createState() => LocalPoemDetailScreenState();
}

class LocalPoemDetailScreenState extends State<LocalPoemDetailScreen> {
  PageController? _pageController;
  late Poem _poem;
  bool _isDeleting = false;
  int _currentPage = 0;
  final ScreenshotController _screenshotController = ScreenshotController();
  List<Poem> _poems = [];

  @override
  void initState() {
    super.initState();
    // 处理单个 poem 的情况
    if (widget.poems.isEmpty) {
      // 这种情况下，我们需要从某个地方获取所有 poems
      _poems = LocalStorageService.getAllPoems();
      _currentPage = 0;
      _poem = _poems.isNotEmpty ? _poems[0] : Poem(
        id: 'empty',
        title: '未找到诗章',
        content: '',
        createdAt: DateTime.now(),
      );
    } else {
      _poems = List.from(widget.poems);
      _currentPage = widget.initialIndex.clamp(0, _poems.length - 1);
      _poem = _poems[_currentPage];
    }
    
    // 延迟初始化PageController
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _pageController = PageController(
            initialPage: _currentPage,
            viewportFraction: 1.0,
            keepPage: true,
          );
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pageController != null && _pageController!.hasClients) {
      _pageController!.dispose();
    }
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _deletePoem() async {
    if (_isDeleting) return;
    
    setState(() {
      _isDeleting = true;
    });

    try {
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

      await LocalStorageService.deletePoem(_poem.id);
      
      if (mounted) {
        _hideLoadingDialog();
        _showSuccessMessage('诗章删除成功');
        
        // 从列表中移除已删除的诗章
        _poems.removeAt(_currentPage);
        
        if (_poems.isEmpty) {
          Navigator.of(context).pop('deleted');
        } else {
          // 调整当前页面索引
          if (_currentPage >= _poems.length) {
            _currentPage = _poems.length - 1;
          }
          _poem = _poems[_currentPage];
          
          // 更新页面控制器
          if (_pageController != null) {
            _pageController!.animateToPage(
              _currentPage,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
          
          setState(() {});
        }
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
          content: Text('确定要删除《${_poem.title}》吗？删除后无法恢复。'),
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

  Widget _buildPoemImage(Poem poem) {
    final imageUrl = poem.imageUrl!;
    final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://') || !imageUrl.startsWith('http');
    
    // 详情页面始终使用固定的图片位置，不受编辑页面调整的影响
    if (isLocalFile) {
      // 本地文件图片
      return InteractiveImagePreview(
        imageFile: File(imageUrl),
        width: double.infinity,
        height: double.infinity,
        initialOffsetX: 0.0,
        initialOffsetY: 0.0,
        initialScale: 1.0,
        onTransformChanged: null,
        isInteractive: false,
        fit: BoxFit.cover,
      );
    } else {
      // 网络图片
      return InteractiveImagePreview(
        imageUrl: imageUrl,
        width: double.infinity,
        height: double.infinity,
        initialOffsetX: 0.0,
        initialOffsetY: 0.0,
        initialScale: 1.0,
        onTransformChanged: null,
        isInteractive: false,
        fit: BoxFit.cover,
      );
    }
  }

  Future<void> _editPoem() async {
    final updated = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateArticleScreen(
          localPoem: _poem,
          isEdit: true,
          isLocalMode: true,
        ),
      ),
    );
    
    if (updated == true && mounted) {
      // 重新加载诗章数据
      final updatedPoems = LocalStorageService.getAllPoems();
      final updatedPoem = updatedPoems.firstWhere(
        (p) => p.id == _poem.id,
        orElse: () => _poem,
      );
      
      setState(() {
        _poem = updatedPoem;
        _poems[_currentPage] = updatedPoem;
      });
    }
  }

  /// 云朵同步按钮（始终显示）
  Widget _buildCloudSyncButton() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final unsyncedCount = LocalStorageService.getUnsyncedCount();
    
    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _isDeleting ? null : _syncToCloud,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLoggedIn 
                      ? (unsyncedCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined)
                      : Icons.cloud_off_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  isLoggedIn ? '同步' : '登录',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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
  
  /// 同步到云端（按需初始化网络）
  Future<void> _syncToCloud() async {
    if (!mounted) return;
    
    // 按需初始化网络服务
    final success = await NetworkInitHelper.ensureNetworkInitialized(context);
    
    if (!success || !mounted) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isAuthenticated;
    
    // 如果未登录，跳转到登录页面
    if (!isLoggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      
      // 登录成功后会自动触发同步，这里检查是否成功
      if (result == true && mounted) {
        _showSuccessMessage('登录成功，开始同步...');
        // 等待一下让 AuthProvider 更新
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          final updatedAuthProvider = Provider.of<AuthProvider>(context, listen: false);
          _performSync(updatedAuthProvider);
        }
      }
      return;
    }
    
    // 已登录，直接执行同步
    _performSync(authProvider);
  }
  
  /// 执行同步操作
  Future<void> _performSync(AuthProvider authProvider) async {
    // 显示同步中提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('正在同步本地作品到云端...')),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final result = await authProvider.syncLocalPoems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.message}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // 刷新当前诗章数据
          final updatedPoems = LocalStorageService.getAllPoems();
          setState(() {
            _poems = updatedPoems;
            if (_currentPage < _poems.length) {
              _poem = _poems[_currentPage];
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${result.message}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 同步失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _buildPoemContent(),
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
          // 返回按钮
          _buildNavButton(
            icon: Icons.arrow_back_ios_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
          
          const SizedBox(width: 12),
          
          // 页面计数 - 居中显示
          Expanded(
            child: Center(
              child: _poems.isNotEmpty
                  ? _buildNavTextButton(
                      text: '${_currentPage + 1}/${_poems.length}',
                      onPressed: null,
                    )
                  : const SizedBox.shrink(),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // 右侧操作按钮
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 编辑按钮
              _buildNavButton(
                icon: Icons.edit_outlined,
                onPressed: _isDeleting ? null : _editPoem,
              ),
              
              const SizedBox(width: 8),
              
              // 云朵同步按钮（使用 TextButton 风格）
              _buildCloudSyncButton(),
              
              const SizedBox(width: 8),
              
              // 删除按钮
              _buildNavButton(
                icon: Icons.delete_outline,
                iconColor: Colors.white,
                onPressed: _isDeleting ? null : _deletePoem,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPoemContent() {
    if (_poems.isEmpty) {
      return const Center(
        child: Text(
          '暂无诗章',
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
      clipBehavior: Clip.none,
      child: PageView.builder(
        itemCount: _poems.length,
        controller: _pageController!,
        allowImplicitScrolling: true,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          if (mounted) {
            HapticFeedback.lightImpact();
            setState(() {
              _currentPage = index;
              _poem = _poems[index];
            });
          }
        },
        itemBuilder: (context, index) {
          final poem = _poems[index];
          
          return AnimatedBuilder(
            animation: _pageController!,
            builder: (context, child) {
              double scale = 1.0;
              double opacity = 1.0;
              
              double page = _currentPage.toDouble();
              if (_pageController!.hasClients && _pageController!.position.haveDimensions) {
                final currentPage = _pageController!.page;
                if (currentPage != null && !currentPage.isNaN && currentPage.isFinite) {
                  page = currentPage;
                }
              }
                    
              double distance = (page - index).abs();
              
              if (distance.isNaN || !distance.isFinite) {
                distance = 0.0;
              }
              
              if (distance <= 1.0) {
                scale = 1.0 - (distance * 0.15);
              } else {
                scale = 0.75;
              }
              
              if (scale.isNaN || !scale.isFinite || scale < 0.1) {
                scale = index == _currentPage ? 1.0 : 0.75;
              }
              
              opacity = (1.0 - distance.clamp(0.0, 1.0) * 0.25).clamp(0.75, 1.0);
              
              if (opacity.isNaN || !opacity.isFinite) {
                opacity = index == _currentPage ? 1.0 : 0.75;
              }
            
              final safeScale = (scale.isNaN || !scale.isFinite || scale <= 0) ? 1.0 : scale.clamp(0.1, 2.0);
              final safeOpacity = (opacity.isNaN || !opacity.isFinite) ? 1.0 : opacity.clamp(0.0, 1.0);
              
              final card = Center(
                child: Transform.scale(
                  scale: safeScale,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3 * safeOpacity),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                        ),
                        _buildPoemCard(poem, safeOpacity),
                      ],
                    ),
                  ),
                ),
              );

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

  Widget _buildPoemCard(Poem poem, [double opacity = 1.0]) {
    final textContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          poem.title, 
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
        if (poem.author?.isNotEmpty == true)
          Text(
            poem.author!, 
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9), 
              fontSize: 17, 
              shadows: const [
                Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 2)
              ]
            )
          ),
        const SizedBox(height: 20),
        // 同步状态标识
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (poem.synced ? Colors.green : Colors.orange).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: (poem.synced ? Colors.green : Colors.orange).withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                poem.synced ? Icons.cloud_done : Icons.cloud_off,
                size: 14,
                color: poem.synced ? Colors.green[300] : Colors.orange[300],
              ),
              const SizedBox(width: 4),
              Text(
                poem.synced ? '已同步' : '未同步',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Flexible(
          child: SingleChildScrollView(
            child: Text(
              poem.content,
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
            child: (poem.imageUrl?.isNotEmpty == true)
                ? _buildPoemImage(poem)
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
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
          ),
          // 文本内容
          Positioned(
            left: poem.textPositionX ?? 15.0,
            top: poem.textPositionY ?? 200.0,
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
      height: 32,
      width: width ?? 32,
      decoration: BoxDecoration(
        color: (backgroundColor ?? Colors.white).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
            padding: const EdgeInsets.all(6),
            child: Icon(
              icon,
              color: (iconColor ?? Colors.white).withValues(alpha: 0.9),
              size: 18,
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
      height: 32,
      decoration: BoxDecoration(
        color: (backgroundColor ?? Colors.white).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
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
                    color: (textColor ?? Colors.white).withValues(alpha: 0.95),
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