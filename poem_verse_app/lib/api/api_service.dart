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
      final url = '${AppConfig.backendApiUrl}/articles/home';
      
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
        final backupUrl = '${AppConfig.backupBackendBaseUrl}/api/articles/home';
        
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

  static Future<http.Response> getArticles(String token) async {
    return await http.get(
      Uri.parse('${AppConfig.backendApiUrl}/articles'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );
  }

  static Future<http.Response> createArticle(
      String token, String title, String content, List<String> tags, String author, {String? previewImageUrl}) async {
    final Map<String, dynamic> body = {
      'title': title,
      'content': content,
      'tags': tags,
      'author': author,
    };
    
    // 如果提供了预览图片URL，添加到请求体中
    if (previewImageUrl != null) {
      body['preview_image_url'] = previewImageUrl;
    }
    
    return await http.post(
      Uri.parse('${AppConfig.backendApiUrl}/articles'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(body),
    );
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

  static String buildImageUrl(String? imageUrl) {
    print('🔗 buildImageUrl 输入: $imageUrl');
    
    if (imageUrl == null || imageUrl.isEmpty) {
      print('🔗 返回空字符串');
      return '';
    }
    
    if (imageUrl.startsWith('http')) {
      print('🔗 已经是完整URL，直接返回: $imageUrl');
      return imageUrl;
    }
    
    final fullUrl = '${AppConfig.backendBaseUrl}$imageUrl';
    print('🔗 构建完整URL: $fullUrl');
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
}
