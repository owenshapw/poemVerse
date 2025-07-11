// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'article_detail_screen.dart';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:poem_verse_app/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<Map<String, dynamic>> _homeDataFuture;

  @override
  void initState() {
    super.initState();
    _homeDataFuture = ApiService.fetchHomeArticles();
    
    // 监听 ArticleProvider 变化，重新获取主页数据
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
      articleProvider.addListener(_onArticleProviderChanged);
    });
  }

  @override
  void dispose() {
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    articleProvider.removeListener(_onArticleProviderChanged);
    super.dispose();
  }

  void _onArticleProviderChanged() {
    setState(() {
      _homeDataFuture = ApiService.fetchHomeArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 强制状态栏为深色
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Color(0xFF232946), // 与登录页一致的深色
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    return Scaffold(
      backgroundColor: Color(0xFF232946), // 与登录页一致的深色，彻底消除SafeArea白色
      body: Stack(
        children: [
          // 蓝紫渐变背景（与登录页一致）
          Container(
            decoration: BoxDecoration(
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
          // 毛玻璃+白色透明遮罩（与登录页一致）
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              color: Colors.white.withOpacity(0.05),
            ),
          ),
          // 内容层（SafeArea 只包裹内容）
          SafeArea(
            child: Consumer<ArticleProvider>(
              builder: (context, articleProvider, child) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: _homeDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          '加载失败: ${snapshot.error}',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }
                    final data = snapshot.data!;
                    final topMonth = data['top_month'];
                    final topWeekList = List<Map<String, dynamic>>.from(data['top_week_list']);

                    // 过滤掉大卡片中已经显示的文章
                    final filteredWeekList = topMonth != null 
                        ? topWeekList.where((poem) => poem['id'] != topMonth['id']).toList()
                        : topWeekList;

                    return ListView(
                      padding: EdgeInsets.only(top: 48), // 整体内容上移
                      children: [
                        if (topMonth != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12, left: 8, right: 8, bottom: 6),
                            child: _buildTopMonthCard(context, topMonth),
                          ),
                        Container(
                          margin: EdgeInsets.only(left: 12, right: 12, top: 2, bottom: 2),
                          child: Text(
                            '本周热门',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.92),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        SizedBox(height: 4),
                        ...filteredWeekList.take(3).map((poem) => _buildWeekCard(context, poem)),
                        SizedBox(height: 24),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // 右上角登录按钮
          Positioned(
            top: 56,
            right: 16,
            child: IconButton(
              icon: Icon(Icons.person_outline, color: Colors.white, size: 28),
              tooltip: '登录',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMonthCard(BuildContext context, Map<String, dynamic> topMonth) {
    String content = topMonth['content'] ?? '';
    List<String> lines = content.split('\n');
    String previewText = lines.take(3).join('\n');
    return GestureDetector(
      onTap: () {
        try {
          print('topMonth: ' + topMonth.toString());
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                try {
                  return ArticleDetailScreen(
                    article: Article.fromJson(topMonth),
                  );
                } catch (e, stack) {
                  print('Article.fromJson error: $e\n$stack');
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('数据解析失败: $e')),
                    );
                  });
                  // 返回一个空页面防止崩溃
                  return Scaffold(
                    appBar: AppBar(title: Text('数据错误')),
                    body: Center(child: Text('数据解析失败: $e')),
                  );
                }
              },
            ),
          );
        } catch (e, stack) {
          print('打开文章失败: $e\n$stack');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打开文章失败: $e')),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 6, vertical: 8), // 距离屏幕边缘更近
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.18),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 32,
              offset: Offset(0, 12),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.25),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // 背景渐变
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667eea).withOpacity(0.7),
                      Color(0xFF764ba2).withOpacity(0.7),
                    ],
                  ),
                ),
              ),
              // 图片
              topMonth['image_url'] != null
                  ? Image.network(
                      ApiService.buildImageUrl(topMonth['image_url']),
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: double.infinity,
                      height: 220,
                      color: Colors.white.withOpacity(0.1),
                      child: Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.3), size: 40),
                    ),
              // 毛玻璃遮罩
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  width: double.infinity,
                  height: 220,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              // 渐变遮罩
              Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.82),
                    ],
                  ),
                ),
              ),
              // 内容
              Positioned(
                left: 18,
                bottom: 32,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topMonth['title'] ?? '',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            offset: Offset(0, 2),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      topMonth['author'] ?? '',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.4),
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      previewText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.95),
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            offset: Offset(0, 1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCard(BuildContext context, Map<String, dynamic> poem) {
    String content = poem['content'] ?? '';
    List<String> lines = content.split('\n');
    String previewText = lines.take(3).join('\n');
    return GestureDetector(
      onTap: () {
        try {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ArticleDetailScreen(
                article: Article.fromJson(poem),
              ),
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('打开文章失败: $e')),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.16),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.18),
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.all(14),
          leading: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.13),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: poem['image_url'] != null
                  ? Image.network(
                      ApiService.buildImageUrl(poem['image_url']),
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      color: Colors.white.withOpacity(0.1),
                      child: Icon(Icons.image_outlined, color: Colors.white.withOpacity(0.3), size: 28),
                    ),
            ),
          ),
          title: Text(
            poem['title'] ?? '',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 17,
              shadows: [
                Shadow(
                  color: Colors.black.withOpacity(0.18),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                poem['author'] ?? '',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.13),
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 4),
              Text(
                previewText,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
