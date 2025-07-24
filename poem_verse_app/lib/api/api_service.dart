import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/models/article.dart';

class ApiService {
  static String get baseUrl {
    // 优先使用环境变量，如果没有则使用配置类
    final url = dotenv.env['BACKEND_URL'];
    if (url != null) {
      return url;
    }
    return AppConfig.backendApiUrl;
  }

  static Future<Map<String, dynamic>> fetchHomeArticles() async {
    // 尝试主URL
    try {
      final url = '${AppConfig.backendApiUrl}/articles'; // Use the standard articles endpoint
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'PoemVerse/1.0 (iOS)',
          'Connection': 'keep-alive',
        },
      );


      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 418) {
        throw Exception('418 error, trying backup URL');
      } else {
        throw Exception('Failed to load home articles: ${response.statusCode}');
      }
    } catch (e) {
      
      // 如果是418错误或其他网络错误，尝试备用URL
      try {
        final backupUrl = '${AppConfig.backupBackendBaseUrl}/api/articles'; // Use the standard articles endpoint
        
        final backupResponse = await http.get(
          Uri.parse(backupUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'PoemVerse/1.0 (iOS)',
            'Connection': 'keep-alive',
          },
        );


        if (backupResponse.statusCode == 200) {
          return json.decode(backupResponse.body);
        } else {
          throw Exception('Both URLs failed: ${backupResponse.statusCode}');
        }
      } catch (backupError) {
        throw Exception('Failed to load home articles: $e -> $backupError');
      }
    }
  }

  static Future<Map<String, dynamic>> fetchArticlesByAuthorCount({int limit = 10}) async {
    try {
      final url = '${AppConfig.backendApiUrl}/articles/grouped/by-author-count?limit=$limit';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'PoemVerse/1.0 (iOS)',
          'Connection': 'keep-alive',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load articles by author count: ${response.statusCode}');
      }
    } catch (e) {
      // 尝试备用URL
      try {
        final backupUrl = '${AppConfig.backupBackendBaseUrl}/api/articles/grouped/by-author-count?limit=$limit';
        
        final backupResponse = await http.get(
          Uri.parse(backupUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'PoemVerse/1.0 (iOS)',
            'Connection': 'keep-alive',
          },
        );

        if (backupResponse.statusCode == 200) {
          return json.decode(backupResponse.body);
        } else {
          throw Exception('Both URLs failed: ${backupResponse.statusCode}');
        }
      } catch (backupError) {
        throw Exception('Failed to load articles by author count: $e -> $backupError');
      }
    }
  }

  static Future<Map<String, dynamic>> fetchArticlesByAuthor(String author) async {
    try {
      final url = '${AppConfig.backendApiUrl}/articles/grouped/by-author/${Uri.encodeComponent(author)}';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'User-Agent': 'PoemVerse/1.0 (iOS)',
          'Connection': 'keep-alive',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load articles by author: ${response.statusCode}');
      }
    } catch (e) {
      // 尝试备用URL
      try {
        final backupUrl = '${AppConfig.backupBackendBaseUrl}/api/articles/grouped/by-author/${Uri.encodeComponent(author)}';
        
        final backupResponse = await http.get(
          Uri.parse(backupUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'User-Agent': 'PoemVerse/1.0 (iOS)',
            'Connection': 'keep-alive',
          },
        );

        if (backupResponse.statusCode == 200) {
          return json.decode(backupResponse.body);
        } else {
          throw Exception('Both URLs failed: ${backupResponse.statusCode}');
        }
      } catch (backupError) {
        throw Exception('Failed to load articles by author: $e -> $backupError');
      }
    }
  }

  static Future<List<Article>> fetchArticles({int page = 1, int perPage = 10}) async {
    final response = await http.get(
      Uri.parse('${AppConfig.backendApiUrl}/articles?page=$page&per_page=$perPage'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final articlesJson = data['articles'] as List;
      return articlesJson.map((json) => Article.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load articles');
    }
  }

  static Future<Map<String, dynamic>> getMyArticles(String token, String userId) async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.backendApiUrl}/articles/user/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load my articles: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load my articles: $e');
    }
  }

  static final Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };
  
  static get textPositionX => null;

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? '登录失败');
    }
  }

  static Future<Map<String, dynamic>> register(String email, String password, String username) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password, 'username': username}),
    );
    if (response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception(json.decode(response.body)['error'] ?? '注册失败');
    }
  }

  static Future<void> forgotPassword(String email) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/forgot-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );
    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? '发送邮件失败');
    }
  }

  static Future<void> resetPassword(String token, String newPassword) async {
    final url = Uri.parse('${AppConfig.backendApiUrl}/auth/reset-password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'token': token, 'new_password': newPassword}),
    );
    if (response.statusCode != 200) {
      throw Exception(json.decode(response.body)['error'] ?? '重置密码失败');
    }
  }

  static Future<http.Response> getArticles(String token) async {
    return await http.get(
      Uri.parse('${AppConfig.backendApiUrl}/articles'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );
  }

  static Future<Article?> createArticle(
      String token, String title, String content, List<String> tags, String author, {String? previewImageUrl, double? textPositionY, double? textPositionX}) async {
    final Map<String, dynamic> body = {
      'title': title,
      'content': content,
      'tags': tags,
      'author': author,
    };
    
    if (previewImageUrl != null) {
      body['preview_image_url'] = previewImageUrl;
    }
    if (textPositionX != null) {
      body['text_position_x'] = textPositionX;
    }
    if (textPositionY != null) {
      body['text_position_y'] = textPositionY;
    }
    
    final response = await http.post(
      Uri.parse('${AppConfig.backendApiUrl}/articles'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      return Article.fromJson(data['article']);
    } else {
      return null;
    }
  }

  static Future<http.Response> generateImage(String token, String articleId) async {
    return await http.post(
      Uri.parse('${AppConfig.backendApiUrl}/generate'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(<String, String>{
        'article_id': articleId,
      }),
    );
  }

  static Future<http.Response> generatePreview(
      String token, String title, String content, List<String> tags, String author) async {
    return await http.post(
      Uri.parse('${AppConfig.backendApiUrl}/generate/preview'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'content': content,
        'tags': tags,
        'author': author,
      }),
    );
  }

  static Future<http.Response> deleteArticle(String token, String articleId) async {
    return await http.delete(
      Uri.parse('${AppConfig.backendApiUrl}/articles/$articleId'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );
  }

  static Future<http.Response> put(Uri url, {required Map<String, String> headers, required Map<String, dynamic> body}) async {
    return await http.put(
      url,
      headers: headers,
      body: jsonEncode(body),
    );
  }

  static String getImageUrlWithVariant(String? imageUrl, String variant) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    String fullUrl = buildImageUrl(imageUrl);
    return fullUrl.replaceAll('headphoto', variant);
  }

  static String buildImageUrl(String? imageUrl) {
    
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }
    
    if (imageUrl.startsWith('http')) {
      return imageUrl;
    }
    
    final fullUrl = '${AppConfig.backendBaseUrl}$imageUrl';
    return fullUrl;
  }

  static Future<Article> getArticleDetail(String articleId) async {
    final response = await http.get(
      Uri.parse('${AppConfig.backendApiUrl}/articles/$articleId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // 兼容返回结构 {"article": {...}}
      final articleJson = data['article'] ?? data;
      return Article.fromJson(articleJson);
    } else {
      throw Exception('获取详情失败: ${response.statusCode}');
    }
  }

  static Future updateArticle(String token, String articleId, String title, String content, List<String> tags, String author, {String? previewImageUrl, double? textPositionX, double? textPositionY}) async {}
}