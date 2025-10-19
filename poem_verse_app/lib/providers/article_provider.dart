// lib/providers/article_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';


class ArticleProvider with ChangeNotifier {
  List<Article> _articles = [];
  Article? _topArticle;
  bool _isLoading = false;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  String? _errorMessage;

  List<Article> get articles => _articles;
  Article? get topArticle => _topArticle;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;

  Future<void> fetchArticles([String? token]) async {
    _isLoading = true;
    _page = 1;
    _hasMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 传递token以支持可见性过滤
      final articlesData = await ApiService.fetchArticlesByAuthorCount(limit: 10, token: token);

      final articlesList = articlesData['articles'] as List?;
      final newArticles = articlesList
          ?.map((data) => Article.fromJson(data))
          .toList() ?? [];
      
      if (newArticles.isNotEmpty) {
        _topArticle = newArticles.first;
        _articles = newArticles.sublist(1);
      } else {
        _topArticle = null;
        _articles = [];
      }

    } catch (e) {
      _errorMessage = 'Failed to load articles. Please try again.';
      _articles = [];
      _topArticle = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreArticles() async {
    if (_isLoading || !_hasMore || _isLoadingMore) return;

    _isLoadingMore = true;
    notifyListeners();

    _page++;
    try {
      final newArticles = await ApiService.fetchArticles(page: _page);
      if (newArticles.isEmpty) {
        _hasMore = false;
      } else {
        _articles.addAll(newArticles);
      }
    } catch (e) {
      // 加载更多文章失败时不做任何处理，保持当前状态
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createArticle(String token, String title, String content, List<String> tags, String author, 
      {String? previewImageUrl, double? textPositionX, double? textPositionY, 
       double? imageOffsetX, double? imageOffsetY, double? imageScale}) async {
    _isLoading = true;
    notifyListeners();

    final newArticle = await ApiService.createArticle(token, title, content, tags, author, 
        previewImageUrl: previewImageUrl, textPositionX: textPositionX, textPositionY: textPositionY,
        imageOffsetX: imageOffsetX, imageOffsetY: imageOffsetY, imageScale: imageScale);

    _isLoading = false;
    if (newArticle != null) {
      // Add the new article to the beginning of the list
      _articles.insert(0, newArticle);
      notifyListeners();
      return true;
    } else {
      notifyListeners();
      return false;
    }
  }

  Future<String?> generateImage(String token, String articleId) async {
    final response = await ApiService.generateImage(token, articleId);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['image_url'];
    } else {
      return null;
    }
  }

  Future<String?> generatePreview(String token, String title, String content, List<String> tags, String author) async {
    final response = await ApiService.generatePreview(token, title, content, tags, author);
    
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return data['preview_url'];
    } else {
      return null;
    }
  }

  Future<void> updateArticle(String token, String articleId, String title, String content, List<String> tags, String author, String userId, 
      {String? previewImageUrl, double? textPositionX, double? textPositionY, 
       double? imageOffsetX, double? imageOffsetY, double? imageScale}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 使用真正的更新API而不是删除后重建
      final body = {
        'title': title,
        'content': content,
        'tags': tags,
        'author': author,
        'preview_image_url': previewImageUrl,
        'text_position_x': textPositionX,
        'text_position_y': textPositionY,
        'image_offset_x': imageOffsetX,
        'image_offset_y': imageOffsetY,
        'image_scale': imageScale,
      };
      
      final response = await ApiService.updateArticleWithBody(articleId, body, token: token);
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('更新文章失败: ${response.statusCode}');
      }

      // 更新成功后刷新数据
      await refreshAllData(token, userId);

    } catch (e) {
      // Re-throw to allow the UI to catch it
      rethrow;
    } finally {
      _isLoading = false;
      // The final notifyListeners is called within refreshAllData
    }
  }

  Future<void> refreshAllData(String token, String userId) async {
    // This is the correct refresh logic. It fetches the articles for the current user.
    await getMyArticles(token, userId);
  }

  Future<void> deleteArticle(String token, String articleId) async {
    final response = await ApiService.deleteArticle(token, articleId);
    
    if (response.statusCode == 200 || response.statusCode == 204) {
      // 删除成功后，从本地列表中移除该文章
      _articles.removeWhere((article) => article.id == articleId);
      
      // 如果删除的是顶部文章，更新顶部文章
      if (_topArticle?.id == articleId) {
        if (_articles.isNotEmpty) {
          _topArticle = _articles.first;
          _articles = _articles.sublist(1);
        } else {
          _topArticle = null;
        }
      }
      
      notifyListeners();
    } else {
      try {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? '删除失败');
      } catch (e) {
        throw Exception('删除失败: ${response.statusCode}');
      }
    }
  }

  Future<void> getMyArticles(String token, String userId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final articlesData = await ApiService.getMyArticles(token, userId);
      final articlesList = articlesData['articles'] as List?;
      final newArticles = articlesList?.map((data) => Article.fromJson(data)).toList() ?? [];
      
      if (newArticles.isNotEmpty) {
        _topArticle = newArticles.first;
        _articles = newArticles.sublist(1);
      } else {
        _topArticle = null;
        _articles = [];
      }
    } catch (e) {
      _errorMessage = 'Failed to load your articles. Please try again.';
      _articles = [];
      _topArticle = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}