import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:poem_verse_app/config/app_config.dart';

class ApiService {
  static String get baseUrl {
    // 优先使用环境变量，如果没有则使用配置类
    final url = dotenv.env['BACKEND_URL'];
    if (url != null) {
      return url;
    }
    return AppConfig.backendApiUrl;
  }

  static final Map<String, String> headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };

  static Future<http.Response> login(String email, String password) async {
    return await http.post(
      Uri.parse('$baseUrl/login'),
      headers: headers,
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<http.Response> register(
      String username, String email, String password) async {
    return await http.post(
      Uri.parse('$baseUrl/register'),
      headers: headers,
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );
  }

  static Future<http.Response> getArticles(String token) async {
    return await http.get(
      Uri.parse('$baseUrl/articles'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
    );
  }

  static Future<http.Response> createArticle(
      String token, String title, String content, List<String> tags) async {
    return await http.post(
      Uri.parse('$baseUrl/articles'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'content': content,
        'tags': tags,
      }),
    );
  }

  static Future<http.Response> generateImage(String token, String articleId) async {
    return await http.post(
      Uri.parse('$baseUrl/generate'),
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
      String token, String title, String content, List<String> tags) async {
    return await http.post(
      Uri.parse('$baseUrl/generate/preview'),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token'
      },
      body: jsonEncode(<String, dynamic>{
        'title': title,
        'content': content,
        'tags': tags,
      }),
    );
  }
}
