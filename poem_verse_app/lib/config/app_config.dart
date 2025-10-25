// lib/config/app_config.dart

class AppConfig {
  static String get backendBaseUrl {
    // 生产模式 - 使用部署在Render上的服务
    return 'https://poemverse.onrender.com';
  }

  // 备用URL配置，用于处理网络问题
  static String get backupBackendBaseUrl {
    // 备用也使用生产环境
    return 'https://poemverse.onrender.com';
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
} 