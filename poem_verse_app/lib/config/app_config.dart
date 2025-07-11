// lib/config/app_config.dart
import 'package:flutter/foundation.dart';
import 'dart:io';

class AppConfig {
  static String get backendBaseUrl {
    // 根据运行环境返回不同的URL
    if (kDebugMode) {
      // 调试模式
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS真机必须用电脑的局域网IP
        return 'http://192.168.14.18:8080';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android模拟器使用10.0.2.2
        return 'http://10.0.2.2:8080';
      } else {
        return 'http://localhost:8080';
      }
    } else {
      // 生产模式 - 也用本地IP，方便开发测试
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'http://192.168.14.18:8080';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8080';
      } else {
        return 'http://localhost:8080';
      }
      // 正式生产时改为：return 'http://your-production-server.com';
    }
  }

  // 备用URL配置，用于处理网络问题
  static String get backupBackendBaseUrl {
    if (kDebugMode) {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS真机备用配置 - 依然用真实IP
        return 'http://192.168.14.18:8080';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8080';
      } else {
        return 'http://127.0.0.1:8080';
      }
    } else {
      // 生产模式备用配置
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return 'http://192.168.14.18:8080';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        return 'http://10.0.2.2:8080';
      } else {
        return 'http://localhost:8080';
      }
    }
  }

  static String get backendApiUrl {
    return '$backendBaseUrl/api';
  }

  static String buildImageUrl(String imagePath) {
    if (imagePath.isEmpty) return '';
    
    // 如果已经是完整URL，直接返回
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    return '$backendBaseUrl$imagePath';
  }

  // 获取本机IP地址（用于真机调试）
  static Future<String> getLocalIpAddress() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && 
              !addr.address.startsWith('127.') &&
              !addr.address.startsWith('169.254.')) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      // 忽略网络接口获取错误，使用默认地址
    }
    return 'localhost';
  }

  // 构建用于真机调试的URL
  static Future<String> buildImageUrlForDevice(String imagePath) async {
    if (imagePath.isEmpty) return '';
    
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      return imagePath;
    }
    
    // 如果是真机，使用本机IP地址
    if (defaultTargetPlatform == TargetPlatform.android || 
        defaultTargetPlatform == TargetPlatform.iOS) {
      final localIp = await getLocalIpAddress();
      return 'http://$localIp:8080$imagePath';
    }
    
    return buildImageUrl(imagePath);
  }
} 