import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/common/route_observer.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/screens/article_detail_screen.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/widgets/interactive_image_preview.dart';

class MyArticlesScreen extends StatefulWidget {
  const MyArticlesScreen({super.key});

  @override
  MyArticlesScreenState createState() => MyArticlesScreenState();
}

class MyArticlesScreenState extends State<MyArticlesScreen> with WidgetsBindingObserver, RouteAware {
  Future<List<Article>>? _myArticlesFuture;
  final ScrollController _scrollController = ScrollController();
  bool _wasSyncing = false; // 用于检测同步状态变化

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMyArticles();
    
    // 监听同步状态变化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        _wasSyncing = authProvider.isSyncing;
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    try {
      routeObserver.unsubscribe(this);
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // 从详情/创建页返回时刷新列表，保持图片 offset/scale 最新
    _loadMyArticles(clearCache: true);
  }

  Future<void> _loadMyArticles({bool clearCache = false}) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    if (token == null || userId == null) {
      setState(() => _myArticlesFuture = Future.value(<Article>[]));
      return;
    }

    if (clearCache) {
      try {
        final future = _myArticlesFuture ?? Future.value(<Article>[]);
        final current = await future;
        final urls = current
            .map((a) => ApiService.getImageUrlWithVariant(a.imageUrl, 'public'))
            .where((u) => u.isNotEmpty)
            .toSet()
            .toList();
        for (final u in urls) {
          final provider = NetworkImage(u);
          await provider.evict();
          PaintingBinding.instance.imageCache.evict(provider);
        }
      } catch (_) {}
    }

    setState(() {
      _myArticlesFuture = _fetchArticles(token, userId);
    });
  }

  Future<List<Article>> _fetchArticles(String token, String userId) async {
    try {
      final data = await ApiService.getMyArticles(token, userId);
      final articlesJson = data['articles'] as List?;
      final list = articlesJson?.map((j) => Article.fromJson(j)).toList().cast<Article>() ?? <Article>[];
      debugPrint('从云端获取到 ${list.length} 个作品（包含登录时同步的本地作品）');
      
      // 调试：查看云端返回的数据结构
      if (list.isNotEmpty) {
        final firstArticle = list.first;
        debugPrint('第一篇作品数据: title=${firstArticle.title}, imageUrl=${firstArticle.imageUrl}, offsetX=${firstArticle.imageOffsetX}, offsetY=${firstArticle.imageOffsetY}');
      }
      
      return list;
    } catch (e) {
      debugPrint('获取云端作品失败: $e');
      return <Article>[];
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Widget _buildContent() {
    return FutureBuilder<List<Article>>(
      future: _myArticlesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade100)));
        }
        if (snapshot.hasError || !snapshot.hasData) return _buildErrorState();
        final articles = snapshot.data!;
        if (articles.isEmpty) return _buildEmptyState();
        return RefreshIndicator(
          onRefresh: () => _loadMyArticles(clearCache: true),
          color: Colors.white,
          backgroundColor: Colors.transparent,
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16), // 进一步减少顶部间距，优化显示效果
            itemCount: articles.length,
            itemBuilder: (context, index) => _buildArticleCard(articles[index], articles, index),
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.error_outline, color: Colors.black54, size: 64),
        const SizedBox(height: 16),
        const Text('加载失败', style: TextStyle(color: Colors.black87, fontSize: 18)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => _loadMyArticles(), child: const Text('重试')),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            color: const Color(0xFF8A5AFF).withValues(alpha: 0.6), // 半透明紫色
            size: 100,
          ),
          const SizedBox(height: 24),
          Text(
            '还没有诗章',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右上角的 + 按钮开始创作',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(Article article, List<Article> articles, int index) {
    final imageField = article.imageUrl;
    final imageUrl = ApiService.getImageUrlWithVariant(imageField, 'public');

    final title = article.title.trim();
    // extract first four non-empty lines from content
    final raw = article.content.replaceAll('\r', '');
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final firstFour = lines.isEmpty ? '' : 
        (lines.length == 1 ? lines[0] : 
         lines.length == 2 ? '${lines[0]}\n${lines[1]}' :
         lines.length == 3 ? '${lines[0]}\n${lines[1]}\n${lines[2]}' :
         '${lines[0]}\n${lines[1]}\n${lines[2]}\n${lines[3]}');

    final imgOffsetX = _toDouble(article.imageOffsetX);
    final imgOffsetY = _toDouble(article.imageOffsetY);
    // Not scaling images in card view (fill width, keep aspect ratio), so imgScale not used here.

    // 调整卡片尺寸，一屏显示三个卡片
    const imageHeight = 180.0; // 图片高度保持180px
    const textAreaHeight = 80.0; // 减少文字区域高度，只显示2行正文
    const cardHeight = imageHeight + textAreaHeight; // 总卡片高度 260px，一屏约可显示3个

    Widget imageWidget;
    if (imageUrl.isNotEmpty) {
      // 使用与创建页面相同的 InteractiveImagePreview，但冻结交互
      imageWidget = InteractiveImagePreview(
        imageUrl: imageUrl,
        width: double.infinity,
        height: imageHeight,
        initialOffsetX: imgOffsetX,
        initialOffsetY: imgOffsetY,
        initialScale: 1.0, // 在列表中不应用缩放
        onTransformChanged: null, // 不需要回调
        isInteractive: false, // 冻结交互
        fit: BoxFit.cover,
      );
    } else {
      imageWidget = Container(height: imageHeight, color: Colors.grey[300]);
    }

    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        await navigator.push(MaterialPageRoute(builder: (ctx) => ArticleDetailScreen(articles: articles, initialIndex: index)));
        await _loadMyArticles(clearCache: true);
      },
      child: Card(
        // Clip card so transformed image is clipped to this card's bounds and won't
        // overlap neighboring cards.
        clipBehavior: Clip.hardEdge,
        margin: EdgeInsets.only(
          top: index == 0 ? 2 : 6, // 进一步减小卡片间距，让一屏显示更多卡片
          bottom: 6,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: cardHeight,
          child: Column(
            children: [
              // Top half: image
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageWidget,
                    // 渐变遮罩，为标题文字提供背景
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color.fromRGBO(0, 0, 0, 0.6), Color.fromRGBO(0, 0, 0, 0.0)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [0.0, 0.7],
                        ),
                      ),
                    ),
                    // 标题覆盖在图片上
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 作者信息显示（如果有的话）
                          if (article.author.isNotEmpty) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                article.author,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom part: 只显示正文前两行
              SizedBox(
                height: textAreaHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          firstFour,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: 2, // 减少到2行
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.grey[900],
      letterSpacing: 1.2,
    );

    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // 检测同步状态从 true 变为 false（同步完成）
        if (_wasSyncing && !authProvider.isSyncing) {
          _wasSyncing = false;
          // 同步完成，刷新列表
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _loadMyArticles(clearCache: true);
            }
          });
        } else if (authProvider.isSyncing) {
          _wasSyncing = true;
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F6FF),
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          Expanded(child: Text('我的诗章', style: titleStyle)),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.add_circle_outline, size: 22, color: Colors.grey[800]),
                                tooltip: '发布诗章',
                                onPressed: () async {
                                  final navigator = Navigator.of(context);
                                  final result = await navigator.push(MaterialPageRoute(builder: (ctx) => const CreateArticleScreen()));
                                  if (!mounted) return;
                                  if (result != null) {
                                    if (result is Map && result['action'] == 'published') {
                                      await _handlePublishedArticle(result['articleInfo']);
                                    } else if (result == 'published' || result == true) {
                                      await _loadMyArticles(clearCache: true);
                                    }
                                  }
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.logout_outlined, size: 22, color: Colors.grey[800]),
                                tooltip: '退出登录',
                                onPressed: () async {
                                  final logoutAuthProvider = Provider.of<AuthProvider>(context, listen: false);
                                  final navigator = Navigator.of(context);
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('确认退出'),
                                      content: const Text('确定要退出登录吗？'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('取消')),
                                        TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('退出')),
                                      ],
                                    ),
                                  );
                                  if (confirmed != true) return;
                                  await logoutAuthProvider.logout();
                                  navigator.pushNamedAndRemoveUntil('/local_home', (route) => false);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 同步状态提示条
                    if (authProvider.isSyncing)
                      _buildSyncingBanner(authProvider),
                    Expanded(child: _buildContent()),
                  ],
                ),
                // 单击顶部区域返回顶部
                Positioned(
                  top: 0,
                  left: 0,
                  right: 120, // 为右侧按钮留出空间
                  height: 40,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () {
                      _scrollController.animateTo(
                        0.0,
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
      ),
        );
      },
    );
  }

  Future<void> _handlePublishedArticle(Map<String, dynamic>? articleInfo) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    final userId = authProvider.userId;

    await _loadMyArticles(clearCache: true);
    if (articleInfo == null) return;
    if (token == null || userId == null) return;

    final data = await ApiService.getMyArticles(token, userId);
    final articlesJson = data['articles'] as List?;
    final articles = articlesJson?.map((j) => Article.fromJson(j)).toList().cast<Article>() ?? <Article>[];

    final title = articleInfo['title']?.toString().trim() ?? '';
    final content = articleInfo['content']?.toString().trim() ?? '';
    int idx = 0;
    for (var i = 0; i < articles.length; i++) {
      if (articles[i].title == title && articles[i].content == content) {
        idx = i;
        break;
      }
    }

    if (!mounted || articles.isEmpty) return;
    final navigator = Navigator.of(context);
    await navigator.push(MaterialPageRoute(builder: (ctx) => ArticleDetailScreen(articles: articles, initialIndex: idx)));
    await _loadMyArticles(clearCache: true);
  }

  /// 构建同步状态提示条
  Widget _buildSyncingBanner(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.blue.shade500,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '您的新作正在加载',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (authProvider.syncTotal > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '正在同步: ${authProvider.syncProgress}/${authProvider.syncTotal}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            Icons.cloud_upload,
            color: Colors.white.withValues(alpha: 0.9),
            size: 20,
          ),
        ],
      ),
    );
  }
}