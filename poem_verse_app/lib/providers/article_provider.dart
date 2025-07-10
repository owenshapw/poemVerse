// lib/providers/article_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';

class ArticleProvider with ChangeNotifier {
  List<Article> _articles = [];
  bool _isLoading = false;

  List<Article> get articles => _articles;
  bool get isLoading => _isLoading;

  Future<void> fetchArticles(String token) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.getArticles(token);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> articlesData = data['articles'] ?? [];
      _articles = articlesData.map((item) => Article.fromJson(item)).toList();
    } else {
      // Handle error
      print('获取文章失败: ${response.statusCode} - ${response.body}');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createArticle(String token, String title, String content, List<String> tags, {String? previewImageUrl}) async {
    _isLoading = true;
    notifyListeners();

    final response = await ApiService.createArticle(token, title, content, tags, previewImageUrl: previewImageUrl);

    if (response.statusCode == 201) {
      // Article created successfully, refresh the list
      await fetchArticles(token);
    } else {
      // Handle error
      print('创建文章失败: ${response.statusCode} - ${response.body}');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<String?> generateImage(String token, String articleId) async {
    final response = await ApiService.generateImage(token, articleId);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['image_url'];
    } else {
      print('生成图片失败: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  Future<String?> generatePreview(String token, String title, String content, List<String> tags) async {
    final response = await ApiService.generatePreview(token, title, content, tags);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['preview_url'];
    } else {
      print('生成预览失败: ${response.statusCode} - ${response.body}');
      return null;
    }
  }

  Future<void> deleteArticle(String token, String articleId) async {
    final response = await ApiService.deleteArticle(token, articleId);
    
    if (response.statusCode == 200) {
      // 删除成功，刷新文章列表
      await fetchArticles(token);
    } else {
      // 处理错误
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? '删除失败');
    }
  }
}
