import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/models/poem.dart';
import 'package:poem_verse_app/services/local_storage_service.dart';
import 'package:poem_verse_app/common/route_observer.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/screens/local_poem_detail_screen.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
import 'package:poem_verse_app/widgets/interactive_image_preview.dart';

class LocalPoemsScreen extends StatefulWidget {
  const LocalPoemsScreen({super.key});

  @override
  LocalPoemsScreenState createState() => LocalPoemsScreenState();
}

class LocalPoemsScreenState extends State<LocalPoemsScreen> with WidgetsBindingObserver, RouteAware {
  List<Poem> _poems = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPoems();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    try {
      routeObserver.unsubscribe(this);
    } catch (_) {}
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    // 从详情/创建页返回时刷新列表，清理缓存
    _loadPoems(clearCache: true);
  }

  void _loadPoems({bool clearCache = false}) {
    if (clearCache) {
      // 清理本地图片缓存
      try {
        for (final poem in _poems) {
          if (poem.imageUrl != null && poem.imageUrl!.isNotEmpty) {
            final imageUrl = poem.imageUrl!;
            final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://') || !imageUrl.startsWith('http');
            
            if (isLocalFile) {
              final provider = FileImage(File(imageUrl));
              provider.evict();
              PaintingBinding.instance.imageCache.evict(provider);
            } else {
              final provider = NetworkImage(imageUrl);
              provider.evict();
              PaintingBinding.instance.imageCache.evict(provider);
            }
          }
        }
      } catch (_) {}
    }
    
    setState(() {
      if (_searchQuery.isEmpty) {
        _poems = LocalStorageService.getAllPoems();
      } else {
        _poems = LocalStorageService.searchPoems(_searchQuery);
      }
    });
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
      _loadPoems();
    });
  }

  Future<void> _deletePoem(Poem poem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除确认'),
        content: Text('确定要删除《${poem.title}》吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await LocalStorageService.deletePoem(poem.id);
      _loadPoems();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除')),
        );
      }
    }
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  Widget _buildContent() {
    if (_searchQuery.isNotEmpty && _poems.isEmpty) {
      return _buildSearchEmptyState();
    }
    if (_poems.isEmpty) {
      return _buildEmptyState();
    }
    return RefreshIndicator(
      onRefresh: () async {
        _loadPoems();
      },
      color: Colors.white,
      backgroundColor: Colors.transparent,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: _poems.length,
        itemBuilder: (context, index) => _buildPoemCard(_poems[index], index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: Colors.grey[900],
      letterSpacing: 1.2,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(child: Text('我的诗章', style: titleStyle)),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 搜索按钮
                          IconButton(
                            icon: Icon(
                              _searchQuery.isEmpty ? Icons.search : Icons.clear,
                              size: 22,
                              color: Colors.grey[800],
                            ),
                            tooltip: _searchQuery.isEmpty ? '搜索' : '清除搜索',
                            onPressed: () {
                              if (_searchQuery.isEmpty) {
                                _showSearchDialog();
                              } else {
                                _searchController.clear();
                                _onSearch('');
                              }
                            },
                          ),
                          // 云朵同步按钮（始终显示）
                          _buildCloudButton(),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, size: 22, color: Colors.grey[800]),
                            tooltip: '创作诗章',
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final result = await navigator.push(
                                MaterialPageRoute(
                                  builder: (_) => const CreateArticleScreen(isLocalMode: true),
                                ),
                              );
                              if (result == true) {
                                _loadPoems();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
            // 单击顶部区域返回顶部
            Positioned(
              top: 0,
              left: 0,
              right: 180, // 增加右侧留白区域，避免与按钮冲突
              height: 40,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  _scrollController.animateTo(
                    0.0,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  color: Colors.transparent,
                ),
              ),
          ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
                context: context,
          builder: (context) => AlertDialog(
            title: const Text('搜索诗章'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: '输入标题、内容或作者...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            _onSearch(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _onSearch(_searchController.text);
            },
            child: const Text('搜索'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off, color: Colors.purple.shade200, size: 80),
        const SizedBox(height: 24),
        Text('没有找到匹配的诗章', style: TextStyle(color: Colors.grey[700], fontSize: 20, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        Text('试试其他关键词', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontSize: 16, height: 1.5)),
        const SizedBox(height: 32),
        ElevatedButton.icon(
          onPressed: () {
            _searchController.clear();
            _onSearch('');
          },
          icon: const Icon(Icons.clear),
          label: const Text('清除搜索'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple.shade100,
            foregroundColor: Colors.purple.shade700,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            color: const Color(0xFF8A5AFF).withValues(alpha: 0.6), // 半透明紫色
            size: 100,
          ),
          const SizedBox(height: 24),
          Text(
            '还没有诗章',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '点击右上角的 + 按钮开始创作',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildPoemCard(Poem poem, int index) {
    final title = poem.title.trim();
    // extract first four non-empty lines from content
    final raw = poem.content.replaceAll('\r', '');
    final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final firstFour = lines.isEmpty ? '' : 
        (lines.length == 1 ? lines[0] : 
         lines.length == 2 ? '${lines[0]}\n${lines[1]}' :
         lines.length == 3 ? '${lines[0]}\n${lines[1]}\n${lines[2]}' :
         '${lines[0]}\n${lines[1]}\n${lines[2]}\n${lines[3]}');

    final imgOffsetY = _toDouble(poem.imageOffsetY);
    // Not scaling images in card view (fill width, keep aspect ratio), so imgScale not used here.
    // X方向固定为0，不需要读取 imageOffsetX

    // 调整卡片尺寸
    const imageHeight = 180.0; // 图片高度保持80px
    const textAreaHeight = 80.0; // 减少文字区域高度，只显示2行正文
    const cardHeight = imageHeight + textAreaHeight; // 总卡片高度 260px，一屏约可显示3个

    Widget imageWidget;
    if (poem.imageUrl != null && poem.imageUrl!.isNotEmpty) {
      final imageUrl = poem.imageUrl!;
      final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://') || !imageUrl.startsWith('http');
      
      if (isLocalFile) {
        // 本地文件图片
        imageWidget = InteractiveImagePreview(
          key: ValueKey('${poem.id}_${imgOffsetY.toStringAsFixed(2)}'), // 根据 ID 和 offsetY 生成唯一 Key
          imageFile: File(imageUrl),
          width: double.infinity,
          height: imageHeight,
          initialOffsetX: 0.0,
          initialOffsetY: imgOffsetY,
          initialScale: 1.0,
          onTransformChanged: null,
          isInteractive: false,
          fit: BoxFit.cover,
        );
      } else {
        // 网络图片
        imageWidget = InteractiveImagePreview(
          key: ValueKey('${poem.id}_${imgOffsetY.toStringAsFixed(2)}'), // 根据 ID 和 offsetY 生成唯一 Key
          imageUrl: imageUrl,
          width: double.infinity,
          height: imageHeight,
          initialOffsetX: 0.0,
          initialOffsetY: imgOffsetY,
          initialScale: 1.0,
          onTransformChanged: null,
          isInteractive: false,
          fit: BoxFit.cover,
        );
      }
    } else{
      imageWidget = Container(
        height: imageHeight, 
        color: Colors.grey[300],
        child: Icon(
          Icons.image_not_supported,
          size: 60,
          color: Colors.grey[500],
        ),
      );
    }

    return GestureDetector(
      onTap: () async {
        final navigator = Navigator.of(context);
        await navigator.push(
          MaterialPageRoute(
            builder: (_) => LocalPoemDetailScreen(
              poems: _poems,
              initialIndex: index,
            ),
          ),
        );
        _loadPoems();
      },
      child: Card(
        clipBehavior: Clip.hardEdge,
        margin: EdgeInsets.only(
          top: index == 0 ? 2 : 6,
          bottom: 6,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          height: cardHeight,
          child: Column(
            children: [
              // Top half: image
              SizedBox(
                height: imageHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    imageWidget,
                    // 渐变遮罩
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color.fromRGBO(0, 0, 0, 0.6), Color.fromRGBO(0, 0, 0, 0.0)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: [0.0, 0.7],
                        ),
                      ),
                    ),
                    // 标题覆盖在图片上
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(1, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // 同步状态和更多选项
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                poem.synced ? Icons.cloud_done : Icons.cloud_off,
                                color: poem.synced 
                                    ? Colors.green[300]
                                    : Colors.orange[300],
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () => _showMoreOptions(poem),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.more_vert,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom part: 正文预览
              SizedBox(
                height: textAreaHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          firstFour,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // 底部信息行
                      Row(
                        children: [
                          if (poem.author?.isNotEmpty == true) ...[
                            Icon(
                              Icons.person_outline,
                              size: 12,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 2),
                            Text(
                              poem.author!,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Icon(
                            Icons.access_time,
                            size: 12,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatDate(poem.createdAt),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMoreOptions(Poem poem) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(Icons.edit, color: Colors.purple.shade600),
                title: Text('编辑', style: TextStyle(color: Colors.grey[800])),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateArticleScreen(
                        localPoem: poem,
                        isEdit: true,
                        isLocalMode: true,
                      ),
                    ),
                  );
                  if (result == true) {
                    _loadPoems();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deletePoem(poem);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return '${diff.inMinutes}分钟前';
      }
      return '${diff.inHours}小时前';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}天前';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  /// 云朵同步按钮（始终显示）
  Widget _buildCloudButton() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final unsyncedCount = LocalStorageService.getUnsyncedCount();
    
    return IconButton(
      icon: Icon(
        isLoggedIn 
            ? (unsyncedCount > 0 ? Icons.cloud_upload : Icons.cloud_done)
            : Icons.cloud_off,
        size: 22,
        color: isLoggedIn
            ? (unsyncedCount > 0 ? Colors.blue[700] : Colors.green[700])
            : Colors.grey[600],
      ),
      tooltip: isLoggedIn 
          ? (unsyncedCount > 0 ? '同步' : '已同步')
          : '登录',
      onPressed: () => _handleCloudButtonTap(),
    );
  }
  
  /// 处理云朵按钮点击
  Future<void> _handleCloudButtonTap() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLoggedIn = authProvider.isAuthenticated;
    
    // 如果未登录，跳转到登录页面
    if (!isLoggedIn) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      
      // 登录成功后会自动触发同步
      if (result == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('登录成功，后台正在同步本地作品...'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // 刷新列表
        _loadPoems();
      }
      return;
    }
    
    // 已登录，执行同步
    final unsyncedCount = LocalStorageService.getUnsyncedCount();
    if (unsyncedCount > 0) {
      _manualSync(authProvider);
    } else {
      // 已经同步完成
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 所有作品已同步'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// 手动同步本地作品
  Future<void> _manualSync(AuthProvider authProvider) async {
    // 显示同步中提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('正在同步本地作品到云端...')),
          ],
        ),
        duration: Duration(seconds: 30), // 较长的时间以适应图片上传
      ),
    );

    try {
      final result = await authProvider.syncLocalPoems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${result.message}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
          // 刷新列表
          _loadPoems();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ ${result.message}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ 同步失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
