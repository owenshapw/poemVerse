import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart'; // added for debugPrint
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String get baseUrl {
    try {
      final url = dotenv.env['BACKEND_API_URL'];
      if (url != null && url.isNotEmpty) return url;
    } catch (e) {
      debugPrint('dotenv not initialized, falling back to AppConfig.backendApiUrl');
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
        debugPrint('API fetchHomeArticles body=${response.body}');
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
      String token, String title, String content, List<String> tags, String author, 
      {String? previewImageUrl, double? textPositionY, double? textPositionX, 
       double? imageOffsetX, double? imageOffsetY, double? imageScale}) async {
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
    if (imageOffsetX != null) {
      body['image_offset_x'] = imageOffsetX;
    }
    if (imageOffsetY != null) {
      body['image_offset_y'] = imageOffsetY;
    }
    if (imageScale != null) {
      body['image_scale'] = imageScale;
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

  // helper: 构造 headers 并可选加入 token
  static Map<String, String> _buildHeaders({String? token}) {
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Future<http.Response> createArticleWithBody(Map<String,dynamic> body, {String? token}) async {
    final base = dotenv.env['BACKEND_API_URL'] ?? AppConfig.backendApiUrl;
    final normalized = base.replaceAll(RegExp(r'/$'), '');
    final url = normalized.endsWith('/api') ? '$normalized/articles' : '$normalized/api/articles';
    final headers = _buildHeaders(token: token);

    debugPrint('ApiService.createArticleWithBody -> URL: $url');
    debugPrint('ApiService.createArticleWithBody -> Headers: $headers');
    debugPrint('ApiService.createArticleWithBody -> Body keys: ${body.keys}');

    return await http.post(Uri.parse(url), headers: headers, body: jsonEncode(body));
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

  static String getImageUrlWithVariant(String src, String variant) {
  if (src.trim().isEmpty) return '';

  // Ensure absolute URL
  String maybeSrc = src;
  if (!maybeSrc.startsWith(RegExp(r'https?://'))) {
    maybeSrc = '${AppConfig.backendBaseUrl}$maybeSrc';
  }

  final uri = Uri.tryParse(maybeSrc);
  if (uri == null) return maybeSrc;

  if (variant.trim().isEmpty) {
    debugPrint('ApiService.getImageUrlWithVariant src=$src variant=<none> out=${uri.toString()}');
    return uri.toString();
  }

  // Replace the last path segment with the requested variant
  final segments = List<String>.from(uri.pathSegments);
  if (segments.isEmpty) {
    segments.add(variant);
  } else {
    segments[segments.length - 1] = variant;
  }

  final outUri = uri.replace(pathSegments: segments);
  debugPrint('ApiService.getImageUrlWithVariant src=$src variant=$variant out=${outUri.toString()}');
  return outUri.toString();
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

  // 点赞相关API方法（待后端实现）
  
  /// 切换文章点赞状态
  /// [articleId] 文章ID
  /// [isLiked] 是否点赞
  /// [deviceId] 设备ID（匿名用户标识）
  static Future<Map<String, dynamic>> toggleArticleLike(
    String articleId, 
    bool isLiked, 
    {String? deviceId}
  ) async {
    try {
      final finalDeviceId = deviceId ?? await _getDeviceId();
      final response = await http.post(
        Uri.parse('${AppConfig.backendApiUrl}/articles/$articleId/like'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'action': isLiked ? 'like' : 'unlike',
          'device_id': finalDeviceId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('点赞操作失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('点赞操作失败: $e');
    }
  }

  /// 获取文章点赞信息
  /// [articleId] 文章ID
  /// [deviceId] 设备ID（可选）
  static Future<Map<String, dynamic>> getArticleLikes(
    String articleId, 
    {String? deviceId}
  ) async {
    try {
      final finalDeviceId = deviceId ?? await _getDeviceId();
      final queryParams = '?device_id=$finalDeviceId';
      final response = await http.get(
        Uri.parse('${AppConfig.backendApiUrl}/articles/$articleId/likes$queryParams'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('获取点赞信息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('获取点赞信息失败: $e');
    }
  }

  /// 批量获取多篇文章的点赞信息
  /// [articleIds] 文章ID列表
  /// [deviceId] 设备ID（可选）
  static Future<Map<String, dynamic>> getBatchArticleLikes(
    List<String> articleIds, 
    {String? deviceId}
  ) async {
    try {
      final finalDeviceId = deviceId ?? await _getDeviceId();
      final response = await http.post(
        Uri.parse('${AppConfig.backendApiUrl}/articles/likes/batch'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'article_ids': articleIds,
          'device_id': finalDeviceId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('批量获取点赞信息失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('批量获取点赞信息失败: $e');
    }
  }

  /// 获取设备唯一标识（用于匿名点赞）
  /// 
  /// 每个设备/应用安装都会生成唯一的ID，存储在本地。
  /// 应用卸载重装后会重新生成新的ID。
  static Future<String> _getDeviceId() async {
    const String key = 'unique_device_id';
    final prefs = await SharedPreferences.getInstance();
    
    // 尝试获取已存储的设备ID
    String? deviceId = prefs.getString(key);
    
    if (deviceId == null || deviceId.isEmpty) {
      // 如果没有存储的ID，生成一个新的唯一ID
      deviceId = _generateUniqueDeviceId();
      await prefs.setString(key, deviceId);
    }
    
    return deviceId;
  }
  
  /// 生成唯一的设备ID
  static String _generateUniqueDeviceId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomNum = random.nextInt(999999);
    return 'device_${timestamp}_$randomNum';
  }

  static Future<http.Response> updateArticleWithBody(
      String id, Map<String, dynamic> body, {
      required String token,
    }) async {
    if (id.isEmpty) throw ArgumentError('updateArticleWithBody: id is empty');
    if (token.isEmpty) throw ArgumentError('updateArticleWithBody: token is empty');

    final base = dotenv.env['BACKEND_API_URL'] ?? AppConfig.backendApiUrl;
    final normalized = base.replaceAll(RegExp(r'/$'), '');
    final url = normalized.endsWith('/api') ? '$normalized/articles/$id' : '$normalized/api/articles/$id';
    final headers = _buildHeaders(token: token);

    final maskedHeaders = Map<String, String>.from(headers);
    if (maskedHeaders.containsKey('Authorization')) {
      final v = maskedHeaders['Authorization']!;
      if (v.length > 20) maskedHeaders['Authorization'] = v.replaceRange(10, v.length-6, '...'); 
    }
    debugPrint('ApiService.updateArticleWithBody -> URL: $url');
    debugPrint('ApiService.updateArticleWithBody -> Headers: $maskedHeaders');
    debugPrint('ApiService.updateArticleWithBody -> Body: $body');

    final resp = await http.put(Uri.parse(url), headers: headers, body: jsonEncode(body));
    debugPrint('PUT Status=${resp.statusCode} body=${resp.body}');
    return resp;
  }
}