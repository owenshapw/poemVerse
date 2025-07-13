import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  print('开始测试图片加载...');
  
  // 测试Cloudflare图片URL
  final imageUrl = 'https://imagedelivery.net/4RSIo06aA9cYqJB6iDeiUA/92f2a304-8ada-441a-115e-aeaabff62d00/public';
  
  print('测试URL: $imageUrl');
  
  final dio = Dio();
  dio.options.connectTimeout = const Duration(seconds: 10);
  dio.options.receiveTimeout = const Duration(seconds: 15);
  
  try {
    print('正在请求图片...');
    final response = await dio.get(
      imageUrl,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
          'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
          'Accept-Encoding': 'gzip, deflate, br',
          'Accept-Language': 'en-US,en;q=0.9',
          'Connection': 'keep-alive',
        },
      ),
    );
    
    print('响应状态码: ${response.statusCode}');
    print('响应头: ${response.headers}');
    print('数据大小: ${response.data?.length ?? 0} bytes');
    
    if (response.statusCode == 200 && response.data != null) {
      print('✅ 图片加载成功!');
      
      // 保存图片到本地测试
      final file = File('test_image.jpg');
      await file.writeAsBytes(response.data);
      print('图片已保存到: ${file.absolute.path}');
    } else {
      print('❌ 图片加载失败: HTTP ${response.statusCode}');
    }
    
  } catch (e) {
    print('❌ 请求失败: $e');
  }
} 