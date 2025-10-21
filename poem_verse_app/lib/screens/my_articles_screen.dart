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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadMyArticles();
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
      return list;
    } catch (_) {
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16), // 减少顶部间距，让第一个卡片上移
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
        Icon(Icons.error_outline, color: Colors.black54, size: 64),
        const SizedBox(height: 16),
        Text('加载失败', style: TextStyle(color: Colors.black87, fontSize: 18)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: () => _loadMyArticles(), child: const Text('重试')),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.article_outlined, color: Colors.purple.shade200, size: 80),
        const SizedBox(height: 24),
        Text('还没有诗篇', style: TextStyle(color: Colors.grey[700], fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Text('点击右上角的编辑按钮\n开始创作你的第一首诗篇', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final result = await navigator.push(MaterialPageRoute(builder: (ctx) => CreateArticleScreen()));
            if (!mounted) return;
            if (result != null) {
              if (result is Map && result['action'] == 'published') {
                await _handlePublishedArticle(result['articleInfo']);
              } else if (result == 'published' || result == true) {
                await _loadMyArticles(clearCache: true);
              }
            }
          },
          icon: const Icon(Icons.edit_outlined),
          label: const Text('开始创作'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade100,
            foregroundColor: Colors.purple.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        ),
      ]),
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

    // 调整卡片尺寸显示4行文本
    const imageHeight = 180.0; // 图片高度保持180px
    const textAreaHeight = 150.0; // 增加文字区域高度以4行文本
    const cardHeight = imageHeight + textAreaHeight; // 总卡片高度 330px

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
          top: index == 0 ? 4 : 8, // 第一个卡片上边距更小
          bottom: 10,
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
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color.fromRGBO(0, 0, 0, 0.08), Color.fromRGBO(0, 0, 0, 0.0)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom half: title + first four lines (no author)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis), // 保持18字体大小
                      const SizedBox(height: 8),
                      Text(firstFour, style: TextStyle(fontSize: 16, color: Colors.grey[800], height: 1.4), maxLines: 4, overflow: TextOverflow.ellipsis), // 增加到4行文本显示
                      const Spacer(),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text('我的诗篇', style: titleStyle)),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.add_circle_outline, size: 22, color: Colors.grey[800]),
                        tooltip: '发布诗篇',
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final result = await navigator.push(MaterialPageRoute(builder: (ctx) => CreateArticleScreen()));
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
                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
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
                          authProvider.logout();
                          navigator.pushNamedAndRemoveUntil('/home', (route) => false);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
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
}