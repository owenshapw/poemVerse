// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/screens/article_detail_screen.dart';
import 'package:poem_verse_app/config/app_config.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    Provider.of<ArticleProvider>(context, listen: false)
        .fetchArticles(authProvider.token!);
  }

  String _buildImageUrl(String imageUrl) {
    return AppConfig.buildImageUrl(imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    final articleProvider = Provider.of<ArticleProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('诗篇'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              articleProvider.fetchArticles(authProvider.token!);
            },
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              authProvider.logout();
            },
          ),
        ],
      ),
      body: articleProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : articleProvider.articles.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.article, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('还没有诗篇', style: TextStyle(fontSize: 18, color: Colors.grey)),
                      SizedBox(height: 8),
                      Text('点击右下角按钮发布第一首诗篇', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await articleProvider.fetchArticles(authProvider.token!);
                  },
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: articleProvider.articles.length,
                    itemBuilder: (context, index) {
                      final article = articleProvider.articles[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: 16),
                        elevation: 4,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ArticleDetailScreen(article: article),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
                          highlightColor: Theme.of(context).primaryColor.withOpacity(0.05),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 图片部分
                              if (article.imageUrl.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  height: 200,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                                    child: Image.network(
                                      _buildImageUrl(article.imageUrl),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.grey[200],
                                          child: Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                                                Text('图片加载失败'),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              
                              // 内容部分
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      article.title,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    ExpandableText(
                                      text: article.content,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(Icons.person, size: 16, color: Colors.grey),
                                        SizedBox(width: 4),
                                        Text(article.author, style: TextStyle(color: Colors.grey)),
                                        Spacer(),
                                        if (article.tags.isNotEmpty) ...[
                                          Icon(Icons.label, size: 16, color: Colors.grey),
                                          SizedBox(width: 4),
                                          Text(article.tags.join(', '), style: TextStyle(color: Colors.grey)),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => CreateArticleScreen()),
          );
        },
        icon: Icon(Icons.add),
        label: Text('发布诗篇'),
      ),
    );
  }
}

// 可展开文本组件
class ExpandableText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int maxLines;

  const ExpandableText({
    super.key,
    required this.text,
    this.style,
    this.maxLines = 3,
  });

  @override
  ExpandableTextState createState() => ExpandableTextState();
}

class ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // 过滤特殊字符，解决Flutter Text渲染提前截断问题
    final safeText = widget.text
        .replaceAll('\u2028', '') // 行分隔符
        .replaceAll('\u0000', '') // 空字符
        .replaceAll('\r', '')     // 回车符
        .replaceAll('\t', '  ')   // 制表符替换为两个空格
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F-\u009F]'), ''); // 其他控制字符
    
    return LayoutBuilder(builder: (context, size) {
      final TextSpan textSpan = TextSpan(
        text: safeText,
        style: widget.style,
      );

      final TextPainter textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        maxLines: widget.maxLines,
      );
      textPainter.layout(maxWidth: size.maxWidth);

      if (textPainter.didExceedMaxLines) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 使用IgnorePointer包装SelectableText，允许点击事件传递到父级
            IgnorePointer(
              child: SelectableText(
                safeText,
                style: widget.style,
                maxLines: _expanded ? null : widget.maxLines,
                textWidthBasis: TextWidthBasis.parent,
                enableInteractiveSelection: false,
              ),
            ),
            SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Text(
                _expanded ? '收起' : '展开',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      } else {
        return IgnorePointer(
          child: SelectableText(
            safeText,
            style: widget.style,
            textWidthBasis: TextWidthBasis.parent,
            enableInteractiveSelection: false,
          ),
        );
      }
    });
  }
}
