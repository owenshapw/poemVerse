// lib/screens/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';

class ArticleDetailScreen extends StatelessWidget {
  final Article article;

  const ArticleDetailScreen({super.key, required this.article});

  String _buildImageUrl(BuildContext context, String imageUrl) {
    return AppConfig.buildImageUrl(imageUrl);
  }

  // 检查是否为文章作者
  bool _isAuthor(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userId == article.userId;
  }

  // 删除文章
  Future<void> _deleteArticle(BuildContext context) async {
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
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
        
        // 显示加载指示器
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        // 调用删除API
        await articleProvider.deleteArticle(authProvider.token!, article.id);
        
        // 关闭加载指示器
        Navigator.of(context).pop();
        
        // 显示成功消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('诗篇删除成功'),
            backgroundColor: Colors.green,
          ),
        );
        
        // 返回上一页
        Navigator.of(context).pop();
        
      } catch (e) {
        // 关闭加载指示器
        Navigator.of(context).pop();
        
        // 显示错误消息
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败：${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('诗篇详情'),
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // TODO: 实现分享功能
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('分享功能开发中...')),
              );
            },
          ),
          // 仅对文章作者显示删除按钮
          if (_isAuthor(context))
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteArticle(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 图片部分
            if (article.imageUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 260, // 调整了
                child: Image.network(
                  _buildImageUrl(context, article.imageUrl),
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
                    article.title,
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
                        '作者：${article.author}',
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
                        '发布时间：${_formatDate(article.createdAt)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 16),
                  
                  // 标签
                  if (article.tags.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      children: article.tags.map((tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(color: Theme.of(context).primaryColor),
                      )).toList(),
                    ),
                    SizedBox(height: 16),
                  ],
                  
                  // 分隔线
                  Divider(),
                  SizedBox(height: 16),
                  
                  // 内容
                  Text(
                    '内容',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Text(
                      article.content,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.8,
                        letterSpacing: 0.5,
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
                            // TODO: 实现收藏功能
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
                  
                  // 仅对文章作者显示删除按钮
                  if (_isAuthor(context)) ...[
                    SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _deleteArticle(context),
                        icon: Icon(Icons.delete, color: Colors.white),
                        label: Text('删除诗篇'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
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