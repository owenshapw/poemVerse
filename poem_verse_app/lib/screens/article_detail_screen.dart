// lib/screens/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart'; // Added import for CreateArticleScreen

class ArticleDetailScreen extends StatefulWidget {
  Article article;

  ArticleDetailScreen({super.key, required this.article});

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  String _buildImageUrl(BuildContext context, String imageUrl) {
    return AppConfig.buildImageUrl(imageUrl);
  }

  // 检查是否为文章作者
  bool _isAuthor(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    print('[DEBUG] 当前登录userId: \'${authProvider.userId}\', 文章userId: \'${widget.article.userId}\'');
    return authProvider.userId == widget.article.userId;
  }

  // 删除文章
  Future<void> _deleteArticle(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    final token = authProvider.token!;
    final articleId = widget.article.id;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('确认删除'),
          content: Text('确定要删除这篇诗篇吗？删除后无法恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text('删除'),
            ),
          ],
        );
      },
    );
    if (confirmed == true) {
      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(child: CircularProgressIndicator());
          },
        );
        await articleProvider.deleteArticle(token, articleId);
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pop(); // 关闭 Dialog
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('诗篇删除成功'), backgroundColor: Colors.green),
        );
        navigator.pop();
      } catch (e) {
        if (!mounted) return;
        navigator.pop();
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('删除失败：${e.toString()}'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // 分享文章
  void _shareArticle() {
    final shareText = '''
${widget.article.title}

作者：${widget.article.author}
发布时间：${_formatDate(widget.article.createdAt)}

${widget.article.content}

${widget.article.tags.isNotEmpty ? '标签：${widget.article.tags.join('、')}' : ''}

来自诗篇App
''';
    
    SharePlus.instance.share(ShareParams(text: shareText));
  }

  Future<void> _refreshArticle() async {
    try {
      final updated = await ApiService.getArticleDetail(widget.article.id);
      setState(() {
        widget.article = updated;
      });
    } catch (e) {
      // 可选：弹窗提示刷新失败
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    print('[DEBUG] build: 当前登录userId: \'${authProvider.userId}\', 文章userId: \'${widget.article.userId}\'');
    return Scaffold(
      appBar: AppBar(
        title: Text('诗篇详情'),
        actions: [
          if (_isAuthor(context)) ...[
            IconButton(
              icon: Icon(Icons.edit_outlined),
              tooltip: '编辑',
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateArticleScreen(
                      article: widget.article,
                      isEdit: true,
                    ),
                  ),
                );
                if (updated == true) {
                  await _refreshArticle();
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.black87),
              tooltip: '删除',
              onPressed: () => _deleteArticle(context),
            ),
          ],
          IconButton(
            icon: Icon(Icons.share_outlined),
            tooltip: '分享',
            onPressed: _shareArticle,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片部分
            if (widget.article.imageUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 260, // 调整了
                child: Image.network(
                  ApiService.buildImageUrl(widget.article.imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                            Text('图片加载失败'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            // 内容部分
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    widget.article.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 作者信息
                  Row(
                    children: [
                      Icon(Icons.person, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        '作者：${widget.article.author}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 8),
                  
                  // 创建时间
                  Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.grey, size: 16),
                      SizedBox(width: 8),
                      Text(
                        '发布时间：${_formatDate(widget.article.createdAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 标签
                  if (widget.article.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      children: widget.article.tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                      )).toList(),
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  // 分隔线
                  Divider(),
                  SizedBox(height: 16),
                  
                  // 内容
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6FF), // 非常浅的紫色背景
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.withOpacity(0.1)),
                    ),
                    child: Text(
                      widget.article.content,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        letterSpacing: 0.5,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  
                  // 操作按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // TODO: 实现点赞功能
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('点赞功能开发中...')),
                            );
                          },
                          icon: Icon(Icons.favorite_border),
                          label: Text('点赞'),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 收藏功能待实现
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('收藏功能开发中...')),
                            );
                          },
                          icon: Icon(Icons.bookmark_border),
                          label: Text('收藏'),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }
} 