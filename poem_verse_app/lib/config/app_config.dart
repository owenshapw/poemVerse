// lib/config/app_config.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class AppConfig {
  static String get backendBaseUrl {
    // 根据运行环境返回不同的URL
    if (kDebugMode) {
      // 调试模式
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        // iOS真机使用本机IP地址
        return 'http://192.168.2.105:5001';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        // Android模拟器使用10.0.2.2
        return 'http://10.0.2.2:5001';
      } else {
        return 'http://localhost:5001';
      }
    } else {
      // 生产模式 - 使用实际的服务器地址
      return 'http://your-production-server.com';
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
      print('获取IP地址失败: $e');
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
      return 'http://$localIp:5001$imagePath';
    }
    
    return buildImageUrl(imagePath);
  }
} 