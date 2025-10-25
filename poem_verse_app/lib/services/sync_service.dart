import 'dart:io';
import 'package:dio/dio.dart';
import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/models/poem.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/services/local_storage_service.dart';
import 'package:flutter/foundation.dart';

/// 同步服务 - 负责将本地诗章同步到云端
class SyncService {
  /// 同步所有未同步的本地诗章到云端
  /// [token] 用户认证token
  /// [username] 用户名
  /// [onProgress] 进度回调 (当前进度, 总数)
  /// 返回：(成功数量, 失败数量, 错误列表)
  static Future<SyncResult> syncLocalPoems({
    required String token,
    required String username,
    Function(int current, int total)? onProgress,
  }) async {
    final unsyncedPoems = LocalStorageService.getUnsyncedPoems();
    
    if (unsyncedPoems.isEmpty) {
      return SyncResult(
        successCount: 0,
        failureCount: 0,
        total: 0,
        errors: [],
      );
    }

    int successCount = 0;
    int failureCount = 0;
    final List<String> errors = [];

    for (int i = 0; i < unsyncedPoems.length; i++) {
      final poem = unsyncedPoems[i];
      
      // 更新进度
      onProgress?.call(i + 1, unsyncedPoems.length);

      try {
        // 1. 检查是否有本地图片需要上传
        String? cloudImageUrl;
        if (poem.imageUrl != null && poem.imageUrl!.isNotEmpty) {
          final imageUrl = poem.imageUrl!;
          final isLocalFile = imageUrl.startsWith('/') || 
                             imageUrl.startsWith('file://') || 
                             !imageUrl.startsWith('http');
          
          if (isLocalFile) {
            // 上传本地图片到 Cloudflare
            debugPrint('正在上传本地图片: ${poem.title}');
            cloudImageUrl = await _uploadLocalImage(imageUrl, token);
            
            if (cloudImageUrl == null) {
              throw Exception('图片上传失败');
            }
            debugPrint('图片上传成功: $cloudImageUrl');
          } else {
            // 已经是云端URL，直接使用
            cloudImageUrl = imageUrl;
          }
        }

        // 2. 创建云端文章
        final article = await _createCloudArticle(
          token: token,
          title: poem.title,
          content: poem.content,
          author: poem.author ?? username,
          imageUrl: cloudImageUrl,
          imageOffsetX: poem.imageOffsetX,
          imageOffsetY: poem.imageOffsetY,
          imageScale: poem.imageScale,
        );

        if (article != null) {
          // 3. 标记为已同步
          await LocalStorageService.markAsSynced(poem.id);
          successCount++;
          debugPrint('诗章同步成功: ${poem.title}');
        } else {
          throw Exception('创建云端文章失败');
        }
      } catch (e) {
        failureCount++;
        final errorMsg = '《${poem.title}》: $e';
        errors.add(errorMsg);
        debugPrint('诗章同步失败: $errorMsg');
      }
    }

    return SyncResult(
      successCount: successCount,
      failureCount: failureCount,
      total: unsyncedPoems.length,
      errors: errors,
    );
  }

  /// 上传本地图片到云端
  /// [localPath] 本地图片路径
  /// [token] 认证token
  /// 返回：云端图片URL，失败返回null
  static Future<String?> _uploadLocalImage(String localPath, String token) async {
    try {
      final file = File(localPath);
      
      // 检查文件是否存在
      if (!await file.exists()) {
        debugPrint('本地图片不存在: $localPath');
        return null;
      }

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
      
      // 检查响应
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData.containsKey('url')) {
          final url = responseData['url'];
          if (url != null && url.toString().isNotEmpty) {
            return url.toString();
          }
        }
      }
      
      debugPrint('图片上传失败: HTTP ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('图片上传异常: $e');
      return null;
    }
  }

  /// 创建云端文章
  static Future<Article?> _createCloudArticle({
    required String token,
    required String title,
    required String content,
    required String author,
    String? imageUrl,
    double? imageOffsetX,
    double? imageOffsetY,
    double? imageScale,
  }) async {
    try {
      final article = await ApiService.createArticle(
        token,
        title,
        content,
        [], // tags
        author,
        previewImageUrl: imageUrl,
        imageOffsetX: imageOffsetX,
        imageOffsetY: imageOffsetY,
        imageScale: imageScale,
      );
      
      return article;
    } catch (e) {
      debugPrint('创建云端文章异常: $e');
      return null;
    }
  }

  /// 单独同步一首诗章（用于手动同步）
  static Future<bool> syncSinglePoem({
    required Poem poem,
    required String token,
    required String username,
  }) async {
    final result = await syncLocalPoems(
      token: token,
      username: username,
    );
    
    return result.successCount > 0;
  }
}

/// 同步结果
class SyncResult {
  final int successCount;  // 成功数量
  final int failureCount;  // 失败数量
  final int total;         // 总数
  final List<String> errors; // 错误列表

  SyncResult({
    required this.successCount,
    required this.failureCount,
    required this.total,
    required this.errors,
  });

  bool get isAllSuccess => failureCount == 0 && total > 0;
  bool get hasFailures => failureCount > 0;
  bool get isEmpty => total == 0;
}
