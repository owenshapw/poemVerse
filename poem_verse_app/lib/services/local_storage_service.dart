import 'package:hive_flutter/hive_flutter.dart';
import 'package:poem_verse_app/models/poem.dart';

/// 本地存储服务 - 使用 Hive 管理本地诗文
class LocalStorageService {
  static const String _poemsBoxName = 'poems';
  static Box<Poem>? _poemsBox;
  static bool _isInitializing = false;
  static bool _isInitialized = false;

  /// 初始化 Hive
  static Future<void> init() async {
    // 如果已经初始化，直接返回
    if (_isInitialized) return;
    
    // 🚀 优化：如果正在初始化，等待初始化完成（最多等待3秒）
    if (_isInitializing) {
      int waitCount = 0;
      while (_isInitializing && waitCount < 40) { // 最多等待2秒 (40 * 50ms)
        await Future.delayed(const Duration(milliseconds: 50));
        waitCount++;
      }
      if (_isInitialized) return;
      // 如果超时仍未初始化，抛出异常
      throw Exception('初始化超时');
    }
    
    _isInitializing = true;
    
    try {
      await Hive.initFlutter();
      
      // 注册适配器（如果还未注册）
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(PoemAdapter());
      }
      
      // 打开 Box
      _poemsBox = await Hive.openBox<Poem>(_poemsBoxName);
      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      rethrow; // 重新抛出异常
    } finally {
      _isInitializing = false;
    }
  }

  /// 获取 Poems Box
  static Box<Poem> get poemsBox {
    if (_poemsBox == null || !_poemsBox!.isOpen) {
      throw Exception('LocalStorageService not initialized. Call init() first.');
    }
    return _poemsBox!;
  }

  /// 保存一首诗
  static Future<void> savePoem(Poem poem) async {
    await poemsBox.put(poem.id, poem);
  }

  /// 获取所有诗文
  static List<Poem> getAllPoems() {
    return poemsBox.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // 按创建时间倒序
  }

  /// 根据 ID 获取诗文
  static Poem? getPoemById(String id) {
    return poemsBox.get(id);
  }

  /// 更新诗文
  static Future<void> updatePoem(Poem poem) async {
    await poemsBox.put(poem.id, poem);
  }

  /// 删除诗文
  static Future<void> deletePoem(String id) async {
    await poemsBox.delete(id);
  }

  /// 获取所有未同步的诗文
  static List<Poem> getUnsyncedPoems() {
    return poemsBox.values.where((poem) => !poem.synced).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt)); // 按创建时间正序
  }

  /// 标记诗文为已同步
  static Future<void> markAsSynced(String id) async {
    final poem = poemsBox.get(id);
    if (poem != null) {
      poem.synced = true;
      await poem.save();
    }
  }

  /// 批量标记为已同步
  static Future<void> markMultipleAsSynced(List<String> ids) async {
    for (final id in ids) {
      await markAsSynced(id);
    }
  }

  /// 获取诗文总数
  static int getPoemsCount() {
    return poemsBox.length;
  }

  /// 获取未同步诗文数量
  static int getUnsyncedCount() {
    return poemsBox.values.where((poem) => !poem.synced).length;
  }

  /// 清空所有本地数据（慎用）
  static Future<void> clearAll() async {
    await poemsBox.clear();
  }

  /// 检查是否有未同步的诗文
  static bool hasUnsyncedPoems() {
    return poemsBox.values.any((poem) => !poem.synced);
  }

  /// 搜索诗文（根据标题或内容）
  static List<Poem> searchPoems(String query) {
    if (query.isEmpty) return getAllPoems();
    
    final lowerQuery = query.toLowerCase();
    return poemsBox.values.where((poem) {
      return poem.title.toLowerCase().contains(lowerQuery) ||
             poem.content.toLowerCase().contains(lowerQuery) ||
             (poem.author?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// 关闭数据库（应用退出时调用）
  static Future<void> close() async {
    await _poemsBox?.close();
  }
}
