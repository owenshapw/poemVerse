// lib/providers/auth_provider.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dio/dio.dart';
import 'package:poem_verse_app/config/app_config.dart';

class AuthProvider with ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _isInitialized = false;
  bool _isSyncing = false; // 是否正在同步
  int _syncProgress = 0; // 同步进度
  int _syncTotal = 0; // 总共需要同步的数量

  // SharedPreferences keys
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  String? get username => _user?['username'];
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  int get syncProgress => _syncProgress;
  int get syncTotal => _syncTotal;
  
  // 从JWT token中解析用户ID
  String? get userId {
    if (_token == null) return null;
    try {
      final parts = _token!.split('.');
      if (parts.length != 3) return null;
      
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      final payloadMap = json.decode(resp);
      
      return payloadMap['user_id'];
    } catch (e) {
      return null;
    }
  }

  /// 初始化 - 从本地存储恢复登录状态
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString(_keyToken);
      final savedUserJson = prefs.getString(_keyUser);
      
      if (savedToken != null && savedUserJson != null) {
        _token = savedToken;
        _user = json.decode(savedUserJson) as Map<String, dynamic>;
        debugPrint('已恢复登录状态: ${_user?['username']}');
      } else {
        debugPrint('未找到保存的登录状态');
      }
    } catch (e) {
      debugPrint('恢复登录状态失败: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// 保存登录状态到本地
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_token != null && _user != null) {
        await prefs.setString(_keyToken, _token!);
        await prefs.setString(_keyUser, json.encode(_user));
        debugPrint('登录状态已保存');
      }
    } catch (e) {
      debugPrint('保存登录状态失败: $e');
    }
  }

  /// 清除保存的登录状态
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
      debugPrint('登录状态已清除');
    } catch (e) {
      debugPrint('清除登录状态失败: $e');
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.login(email, password);
      if (response.containsKey('token')) {
        _token = response['token'];
        _user = response['user'];
        
        // 保存登录状态
        await _saveAuthState();
        
        debugPrint('登录成功，在后台同步本地作品...');
        
        // 登录成功后在后台异步同步本地作品到云端（不阻塞登录流程）
        _syncLocalPoemsInBackground();
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String username) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await ApiService.register(email, password, username);
      if (response.containsKey('token')) {
        _token = response['token'];
        _user = response['user'];
        
        // 保存登录状态
        await _saveAuthState();
        
        // 注册成功后在后台同步本地作品
        _syncLocalPoemsInBackground();
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await ApiService.forgotPassword(email);
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    
    // 清除保存的登录状态
    await _clearAuthState();
    
    notifyListeners();
  }

  /// 后台同步本地作品（不阻塞UI）
  void _syncLocalPoemsInBackground() {
    _syncLocalPoems().then((result) {
      debugPrint('后台同步完成: ${result.message}');
    }).catchError((error) {
      debugPrint('后台同步出错: $error');
    });
  }

  /// 同步本地作品到云端
  Future<SyncResult> _syncLocalPoems() async {
    if (_token == null) {
      return SyncResult(success: false, message: '未登录');
    }

    // 设置同步状态
    _isSyncing = true;
    _syncProgress = 0;
    notifyListeners();
    
    try {
      final unsyncedPoems = LocalStorageService.getUnsyncedPoems();
      _syncTotal = unsyncedPoems.length;
      debugPrint('找到 ${unsyncedPoems.length} 首未同步的作品');
      
      if (unsyncedPoems.isEmpty) {
        _isSyncing = false;
        _syncProgress = 0;
        _syncTotal = 0;
        notifyListeners();
        return SyncResult(success: true, syncedCount: 0, message: '没有需要同步的作品');
      }

      final dio = Dio();
      int successCount = 0;
      
      debugPrint('开始同步本地作品到云端...');
      notifyListeners();
      
      for (final poem in unsyncedPoems) {
        try {
          final apiUrl = '${AppConfig.backendApiUrl}/articles';
          debugPrint('正在同步作品 "${poem.title}"');
          
          // 🔥 检查是否有本地图片需要上传
          String? cloudImageUrl;
          if (poem.imageUrl != null && poem.imageUrl!.isNotEmpty) {
            final imageUrl = poem.imageUrl!;
            final isLocalFile = imageUrl.startsWith('/') || 
                               imageUrl.startsWith('file://') || 
                               !imageUrl.startsWith('http');
            
            if (isLocalFile) {
              debugPrint('检测到本地图片，开始上传到Cloudflare: $imageUrl');
              cloudImageUrl = await _uploadLocalImageWithRetry(imageUrl, _token!);
              
              if (cloudImageUrl != null) {
                debugPrint('✅ 图片上传成功: $cloudImageUrl');
              } else {
                debugPrint('❌ 图片上传失败（已重试），跳过该作品');
                // 图片上传失败，跳过该作品，稍后手动同步
                continue;
              }
            } else {
              // 已经是云端URL，直接使用
              cloudImageUrl = imageUrl;
              debugPrint('使用已有的云端图片URL: $cloudImageUrl');
            }
          }
          
          final requestData = {
            'title': poem.title,
            'content': poem.content,
            'author': poem.author ?? username ?? '',
            'preview_image_url': cloudImageUrl ?? '',
            'image_offset_x': poem.imageOffsetX,
            'image_offset_y': poem.imageOffsetY,
            'image_scale': poem.imageScale,
            'text_position_x': poem.textPositionX,
            'text_position_y': poem.textPositionY,
            'tags': [], // 本地作品默认无标签
          };
          
          debugPrint('发送数据: {'
            'title: ${poem.title}, '
            'author: ${poem.author ?? username ?? ''}, '
            'hasImage: ${poem.imageUrl?.isNotEmpty ?? false}'
          '}');
          
          final response = await dio.post(
            apiUrl,
            data: requestData,
            options: Options(
              headers: {
                'Authorization': 'Bearer $_token',
                'Content-Type': 'application/json',
              },
            ),
          );
          
          debugPrint('同步作品 "${poem.title}" 成功，状态码: ${response.statusCode}');
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            // 上传成功，标记为已同步
            await LocalStorageService.markAsSynced(poem.id);
            successCount++;
            _syncProgress++;
            debugPrint('作品 "${poem.title}" 已标记为已同步 ($_syncProgress/$_syncTotal)');
            debugPrint('服务器返回数据: ${response.data}');
            notifyListeners(); // 通知UI更新进度
          } else {
            debugPrint('作品 "${poem.title}" 同步失败，状态码: ${response.statusCode}');
            debugPrint('错误响应: ${response.data}');
          }
        } catch (e) {
          // 单个作品上传失败，继续下一个
          debugPrint('同步作品 "${poem.title}" 失败: $e');
          if (e is DioException) {
            debugPrint('请求详情: ${e.response?.data}');
          }
          continue;
        }
      }
      
      debugPrint('同步完成: $successCount/${unsyncedPoems.length} 首作品成功');
      
      return SyncResult(
        success: true,
        syncedCount: successCount,
        totalCount: unsyncedPoems.length,
        message: '成功同步 $successCount 首作品到云端',
      );
    } catch (e) {
      debugPrint('同步过程出错: $e');
      return SyncResult(success: false, message: '同步失败: $e');
    } finally {
      // 重置同步状态
      _isSyncing = false;
      _syncProgress = 0;
      _syncTotal = 0;
      notifyListeners();
    }
  }

  /// 手动同步本地作品
  Future<SyncResult> syncLocalPoems() async {
    return await _syncLocalPoems();
  }

  /// 上传本地图片到Cloudflare（带重试机制）
  /// [localPath] 本地图片路径
  /// [token] 认证token
  /// [maxRetries] 最大重试次数，默认3次
  /// 返回：云端图片URL，失败返回null
  Future<String?> _uploadLocalImageWithRetry(
    String localPath, 
    String token, {
    int maxRetries = 3,
  }) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      debugPrint('📤 尝试上传图片 (第 $attempt/$maxRetries 次): $localPath');
      
      final result = await _uploadLocalImage(localPath, token);
      
      if (result != null) {
        return result;
      }
      
      if (attempt < maxRetries) {
        // 等待一段时间后重试（指数退避）
        final waitTime = Duration(seconds: attempt * 2);
        debugPrint('⏳ 等待 ${waitTime.inSeconds} 秒后重试...');
        await Future.delayed(waitTime);
      }
    }
    
    debugPrint('❌ 图片上传失败，已重试 $maxRetries 次');
    return null;
  }

  /// 上传本地图片到Cloudflare
  /// [localPath] 本地图片路径
  /// [token] 认证token
  /// 返回：云端图片URL，失败返回null
  Future<String?> _uploadLocalImage(String localPath, String token) async {
    try {
      final file = File(localPath);
      
      // 检查文件是否存在
      if (!await file.exists()) {
        debugPrint('❌ 本地图片不存在: $localPath');
        return null;
      }

      debugPrint('📤 开始上传图片: ${file.path}');
      final dio = Dio();
      
      // 配置超时
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.sendTimeout = const Duration(seconds: 60); // 上传可能需要更长时间
      
      // 构建表单数据
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });
      
      debugPrint('📡 发送上传请求到: ${AppConfig.backendApiUrl}/upload_image');
      
      // 发送上传请求
      final response = await dio.post(
        '${AppConfig.backendApiUrl}/upload_image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => status! < 500,
        ),
      );
      
      debugPrint('📥 上传响应: ${response.statusCode}');
      
      // 检查响应
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        debugPrint('响应数据: $responseData');
        
        if (responseData is Map && responseData.containsKey('url')) {
          final url = responseData['url'];
          if (url != null && url.toString().isNotEmpty) {
            debugPrint('✅ 图片上传成功: $url');
            return url.toString();
          }
        }
      }
      
      debugPrint('❌ 图片上传失败: HTTP ${response.statusCode}, 响应: ${response.data}');
      return null;
    } catch (e) {
      debugPrint('❌ 图片上传异常: $e');
      if (e is DioException) {
        debugPrint('详细错误: ${e.response?.data}');
      }
      return null;
    }
  }
}

/// 同步结果
class SyncResult {
  final bool success;
  final int syncedCount;
  final int totalCount;
  final String message;

  SyncResult({
    required this.success,
    this.syncedCount = 0,
    this.totalCount = 0,
    required this.message,
  });
}