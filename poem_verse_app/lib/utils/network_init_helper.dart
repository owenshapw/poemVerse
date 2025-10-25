import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';

/// 网络服务按需初始化助手
/// 在用户首次使用网络功能时才初始化 AuthProvider
/// 避免启动时触发"允许查找本地网络"权限弹窗
class NetworkInitHelper {
  /// 确保网络服务已初始化
  /// 如果未初始化，显示加载提示并初始化
  /// 返回是否初始化成功
  static Future<bool> ensureNetworkInitialized(BuildContext context) async {
    if (!context.mounted) return false;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // 如果已经初始化，直接返回
      if (authProvider.isInitialized) {
        debugPrint('✅ 网络服务已初始化');
        return true;
      }
      
      debugPrint('🌐 首次使用网络功能，开始初始化...');
      
      // 显示初始化提示
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => PopScope(
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '正在连接云端服务...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '首次连接可能需要授权',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
      
      // 初始化 AuthProvider（这里可能触发权限弹窗）
      await authProvider.init().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('⚠️ AuthProvider 初始化超时');
        },
      );
      
      debugPrint('✅ AuthProvider 初始化完成');
      
      // 关闭初始化提示
      if (context.mounted) {
        Navigator.of(context).pop();
      }
      
      return true;
    } catch (e) {
      debugPrint('❌ 网络服务初始化失败: $e');
      
      // 关闭初始化提示
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // 显示错误提示
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('初始化失败'),
            content: Text('云端服务初始化失败：$e\n\n您可以继续使用本地功能。'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
      
      return false;
    }
  }
  
  /// 快速检查是否已初始化（不显示UI）
  static bool isNetworkInitialized(BuildContext context) {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      return authProvider.isInitialized;
    } catch (e) {
      return false;
    }
  }
}
