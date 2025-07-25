// lib/providers/article_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/article.dart';
import 'dart:developer' as developer;

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
      final articlesData = await ApiService.fetchArticlesByAuthorCount(limit: 10);
      developer.log('API Response: ${jsonEncode(articlesData)}', name: 'ArticleProvider');

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

      developer.log('Processed Articles Count: ${_articles.length}', name: 'ArticleProvider');
      developer.log('Top Article: ${_topArticle?.title}', name: 'ArticleProvider');

    } catch (e, stackTrace) {
      _errorMessage = 'Failed to load articles. Please try again.';
      developer.log('Error fetching articles: $e', name: 'ArticleProvider', error: e, stackTrace: stackTrace);
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
    } catch (e, stackTrace) {
      developer.log('Error fetching more articles: $e', name: 'ArticleProvider', error: e, stackTrace: stackTrace);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<bool> createArticle(String token, String title, String content, List<String> tags, String author, {String? previewImageUrl, double? textPositionX, double? textPositionY}) async {
    _isLoading = true;
    notifyListeners();

    final newArticle = await ApiService.createArticle(token, title, content, tags, author, previewImageUrl: previewImageUrl, textPositionX: textPositionX, textPositionY: textPositionY);

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

  Future<void> updateArticle(String token, String articleId, String title, String content, List<String> tags, String author, String userId, {String? previewImageUrl, double? textPositionX, double? textPositionY}) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Step 1: Delete the old article.
      final deleteResponse = await ApiService.deleteArticle(token, articleId);
      if (deleteResponse.statusCode != 200) {
        throw Exception('Failed to delete the old article to update.');
      }

      // Step 2: Create a new article with all the updated information.
      final newArticle = await ApiService.createArticle(
        token, title, content, tags, author, 
        previewImageUrl: previewImageUrl, 
        textPositionX: textPositionX, 
        textPositionY: textPositionY
      );

      if (newArticle == null) {
        throw Exception('Failed to create the new article during update.');
      }

      // Step 3: Refresh the entire list to show the new article at the top.
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
    
    if (response.statusCode == 200) {
      await fetchArticles(token);
    } else {
      final errorData = json.decode(response.body);
      throw Exception(errorData['error'] ?? '删除失败');
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