// lib/screens/create_article_screen.dart
// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';

import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/widgets/interactive_image_preview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poem_verse_app/screens/article_preview_screen.dart';
import 'package:poem_verse_app/utils/text_menu_utils.dart';

import 'dart:io';
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:poem_verse_app/api/api_service.dart';
import 'package:poem_verse_app/models/poem.dart';
import 'package:poem_verse_app/services/local_storage_service.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
import 'package:poem_verse_app/utils/network_init_helper.dart';

class CreateArticleScreen extends StatefulWidget {
  final Article? article;
  final Poem? localPoem; // 本地作品（用于编辑）
  final bool isEdit;
  final bool isLocalMode; // 本地模式标记
  const CreateArticleScreen({
    super.key,
    this.article,
    this.localPoem,
    this.isEdit = false,
    this.isLocalMode = false,
  });

  @override
  CreateArticleScreenState createState() => CreateArticleScreenState();
}

class CreateArticleScreenState extends State<CreateArticleScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  String? _previewImageUrl;

  bool _isUploadingImage = false; // 添加上传状态追踪
  double _textPositionX = 15.0; // Default to a centered position
  double _textPositionY = 200.0;
  
  // 图片变换参数
  double _imageOffsetX = 0.0;
  double _imageOffsetY = 0.0;
  double _imageScale = 1.0;

  // Preview area — for debounced transform values
  double? _previewOffsetY;

  @override
  void initState() {
    super.initState();
    // 初始化数据：优先使用本地作品，然后是云端作品
    if (widget.isEdit) {
      if (widget.localPoem != null) {
        // 编辑本地作品
        _titleController.text = widget.localPoem!.title;
        _contentController.text = widget.localPoem!.content;
        _previewImageUrl = widget.localPoem!.imageUrl;
        
        final rawOffsetX = widget.localPoem!.imageOffsetX ?? 0.0;
        final rawOffsetY = widget.localPoem!.imageOffsetY ?? 0.0;
        final rawScale = widget.localPoem!.imageScale ?? 1.0;
        _imageOffsetX = rawOffsetX.isFinite ? rawOffsetX : 0.0;
        _imageOffsetY = rawOffsetY.isFinite ? rawOffsetY : 0.0;
        _imageScale = rawScale.isFinite ? rawScale : 1.0;
        
        _previewOffsetY = _imageOffsetY;
        
        // 加载文字位置
        _textPositionX = widget.localPoem!.textPositionX ?? 15.0;
        _textPositionY = widget.localPoem!.textPositionY ?? 200.0;
        









      } else if (widget.article != null) {
        // 编辑云端作品
        _titleController.text = widget.article!.title;
        _contentController.text = widget.article!.content;

        // 保证预览直接使用 public 变体
        _previewImageUrl = ApiService.getImageUrlWithVariant(widget.article!.imageUrl, 'public');

        // Load existing positions, otherwise the default is used
        _textPositionX = (widget.article!.textPositionX ?? 15.0).toDouble();
        _textPositionY = (widget.article!.textPositionY ?? 200.0).toDouble();

        // Load existing image transform, otherwise the default is used
        // 强制校验有限性，避免 NaN/inf 传入
        final rawOffsetX = widget.article!.imageOffsetX ?? 0.0;
        final rawOffsetY = widget.article!.imageOffsetY ?? 0.0;
        final rawScale = widget.article!.imageScale ?? 1.0;
        _imageOffsetX = rawOffsetX.isFinite ? rawOffsetX.toDouble() : 0.0;
        _imageOffsetY = rawOffsetY.isFinite ? rawOffsetY.toDouble() : 0.0;
        _imageScale = rawScale.isFinite ? rawScale.toDouble() : 1.0;
        
        // 初始化预览偏移量为数据库中的值
        _previewOffsetY = _imageOffsetY;
      }
    } else {
      // ensure defaults finite
      if (!_imageScale.isFinite) _imageScale = 1.0;
      if (!_imageOffsetX.isFinite) _imageOffsetX = 0.0;
      if (!_imageOffsetY.isFinite) _imageOffsetY = 0.0;
      
      // 新建时也初始化预览值
      _previewOffsetY = _imageOffsetY;
    }
  }

  @override
  void dispose() {
    // 离开页面时自动保存（本地模式 + 编辑模式）
    if (widget.isLocalMode && widget.isEdit && widget.localPoem != null) {
      _saveOnExit();
    }
    
    _titleController.dispose();
    _contentController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }
  
  // 离开页面时保存
  void _saveOnExit() {




    // 直接更新 HiveObject
    widget.localPoem!.title = _titleController.text.trim().isNotEmpty 
        ? _titleController.text.trim() 
        : widget.localPoem!.title;
    widget.localPoem!.content = _contentController.text.trim().isNotEmpty 
        ? _contentController.text.trim() 
        : widget.localPoem!.content;
    widget.localPoem!.imageUrl = _previewImageUrl ?? widget.localPoem!.imageUrl;
    widget.localPoem!.synced = false;
    widget.localPoem!.imageOffsetX = 0.0;
    widget.localPoem!.imageOffsetY = _imageOffsetY;
    widget.localPoem!.imageScale = 1.0;
    widget.localPoem!.textPositionX = _textPositionX;
    widget.localPoem!.textPositionY = _textPositionY;
    
    // 同步保存（不能用 async，因为在 dispose 中）
    widget.localPoem!.save();



  }


  


  

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    
    // 检查widget是否仍然有效
    if (!mounted) return;
    
    // 开始上传状态
    setState(() {
      _isUploadingImage = true;
    });
    
    final file = File(pickedFile.path);
    
    // 本地模式：将图片复制到永久目录
    if (widget.isLocalMode) {
      try {
        // 获取应用文档目录
        final appDocDir = await getApplicationDocumentsDirectory();
        final imagesDir = Directory('${appDocDir.path}/images');
        
        // 确保图片目录存在
        if (!await imagesDir.exists()) {
          await imagesDir.create(recursive: true);
        }
        
        // 生成唯一文件名
        final fileName = '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
        final permanentPath = '${imagesDir.path}/$fileName';
        
        // 复制文件到永久目录
        final permanentFile = await file.copy(permanentPath);
        
        if (mounted) {
          setState(() {
            _previewImageUrl = permanentFile.path; // 使用永久路径
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片选择成功！')),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isUploadingImage = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('图片保存失败: $e')),
          );
        }
      }
      return;
    }
    
    // 云端模式：需要上传到服务器
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录')),
        );
      }
      return;
    }
    try {
      final dio = Dio();
      
      // 配置Dio以避免网络字典错误
      dio.options.connectTimeout = const Duration(seconds: 30);
      dio.options.receiveTimeout = const Duration(seconds: 30);
      dio.options.sendTimeout = const Duration(seconds: 30);
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path, 
          filename: file.path.split('/').last,
        ),
      });
      
      final response = await dio.post(
        '${AppConfig.backendApiUrl}/upload_image',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'multipart/form-data',
          },
          validateStatus: (status) => status! < 500, // 允许4xx状态码
        ),
      );
      
      // 再次检查widget是否仍然有效
      if (!mounted) return;
      
      // 安全检查响应数据
      if (response.statusCode == 200 && response.data != null) {
        final responseData = response.data;
        if (responseData is Map && responseData.containsKey('url')) {
          final url = responseData['url'];
          if (url != null && url.toString().isNotEmpty) {
            setState(() {
              // 使用后端可访问的 public 变体作为预览 URL
              _previewImageUrl = ApiService.getImageUrlWithVariant(url.toString(), 'public');
              _isUploadingImage = false; // 上传成功，停止动画
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('图片上传成功！')),
            );
            return;
          }
        }
      }
      
      // 上传失败
      setState(() {
        _isUploadingImage = false; // 上传失败，停止动画
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('图片上传失败：服务器响应异常')),
      );
    } catch (e) {
      if (mounted) {
        String errorMessage = '图片上传失败';
        if (e is DioException) {
          switch (e.type) {
            case DioExceptionType.connectionTimeout:
              errorMessage = '连接超时，请检查网络';
              break;
            case DioExceptionType.sendTimeout:
              errorMessage = '上传超时，请重试';
              break;
            case DioExceptionType.receiveTimeout:
              errorMessage = '接收超时，请重试';
              break;
            case DioExceptionType.badResponse:
              errorMessage = '服务器错误：${e.response?.statusCode}';
              break;
            case DioExceptionType.cancel:
              errorMessage = '上传已取消';
              break;
            default:
              errorMessage = '网络错误，请重试';
          }
        }
        setState(() {
          _isUploadingImage = false; // 上传出错，停止动画
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  // 构建图片预览区域
  Widget _buildImagePreviewArea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('图片预览（上下拖动调整图片位置）:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: _buildImageContent(),
          ),
        ),
      ],
    );
  }

  // 构建图片内容
  Widget _buildImageContent() {
    if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty) {
      // 显示上传的图片
      return _buildInteractivePreview();
    } else {
      // 显示浅灰色占位
      return _buildEmptyPreview();
    }
  }



  // 交互式图片预览
  Widget _buildInteractivePreview() {
    final imageUrl = _previewImageUrl ?? '';
    final isLocalFile = imageUrl.startsWith('/') || imageUrl.startsWith('file://');
    
    final finalOffsetY = _previewOffsetY ?? _imageOffsetY;
    
    if (isLocalFile) {
      // 本地文件预览
      return InteractiveImagePreview(
        key: ValueKey('edit_local_${imageUrl}_${finalOffsetY.toStringAsFixed(2)}'),
        imageFile: File(imageUrl),
        width: double.infinity,
        height: 180,
        initialOffsetX: 0.0,
        initialOffsetY: finalOffsetY,
        initialScale: 1.0,
        onTransformChanged: (ox, oy, s) {
          // 只使用 Y 方向偏移（ox 总是 0）
          _previewOffsetY = oy;
          _imageOffsetY = oy;

        },
        isInteractive: true,
        fit: BoxFit.cover,
      );
    } else {
      // 网络图片预览
      return InteractiveImagePreview(
        key: ValueKey('edit_network_${imageUrl}_${finalOffsetY.toStringAsFixed(2)}'),
        imageUrl: ApiService.getImageUrlWithVariant(imageUrl, 'public'),
        width: double.infinity,
        height: 180,
        initialOffsetX: 0.0,
        initialOffsetY: finalOffsetY,
        initialScale: 1.0,
        onTransformChanged: (ox, oy, s) {
          // 只使用 Y 方向偏移（ox 总是 0）
          _previewOffsetY = oy;
          _imageOffsetY = oy;

        },
        isInteractive: true,
        fit: BoxFit.cover,
      );
    }
  }

  // 空状态预览 - 纯净的浅色占位符
  Widget _buildEmptyPreview() {
    return Container(
      color: Color(0xFFFAFAFA), // 非常浅的灰色占位符
    );
  }

  /// 云朵按钮（简洁风格）
  Widget _buildCloudButton() {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isAuthenticated;
    final unsyncedCount = LocalStorageService.getUnsyncedCount();
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _navigateToLogin(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isLoggedIn 
                      ? (unsyncedCount > 0 ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined)
                      : Icons.cloud_off_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  isLoggedIn ? '同步' : '登录',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 导航到登录页面（按需初始化网络）
  Future<void> _navigateToLogin() async {
    if (!mounted) return;
    
    // 按需初始化网络服务
    final success = await NetworkInitHelper.ensureNetworkInitialized(context);
    
    if (!success || !mounted) return;
    
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
        // 刷新状态
        if (mounted) {
          setState(() {});
        }
      }
      return;
    }
    
    // 已登录，执行同步
    _performSync(authProvider);
  }
  
  /// 执行同步操作
  Future<void> _performSync(AuthProvider authProvider) async {
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
        duration: Duration(seconds: 30),
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
          // 刷新状态
          setState(() {});
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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.isLocalMode 
          ? (widget.isEdit ? '编辑诗章' : '创作诗章')
          : (widget.isEdit ? '编辑诗章' : '发布诗章')),
        actions: [
          // 云朵按钮（本地模式下始终显示）
          if (widget.isLocalMode) _buildCloudButton(),
        ],
      ),
      body: GestureDetector(
        // 点击空白区域收回键盘
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 16.0,
            ),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题输入
                TextField(
                  controller: _titleController,
                  focusNode: _titleFocusNode,
                  decoration: InputDecoration(
                    labelText: '标题', 
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _titleController.clear();
                        FocusScope.of(context).unfocus(); // 清除后收回键盘
                      },
                    ),
                  ),
                  textInputAction: TextInputAction.next, // 键盘显示“下一项”
                  contextMenuBuilder: TextMenuUtils.buildChineseContextMenu,
                ),
                SizedBox(height: 16),
                // 内容输入 - 使用固定高度但可滚动
                Container(
                  height: 200, // 减少高度防止溢出
                  child: TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    decoration: InputDecoration(
                      labelText: '内容',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                      suffixIcon: Padding(
                        padding: EdgeInsets.only(top: 8, right: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _contentController.clear();
                                FocusScope.of(context).unfocus();
                              },
                            ),
                            GestureDetector(
                              onTap: () async {
                                // 直接取消所有焦点
                                _titleFocusNode.unfocus();
                                _contentFocusNode.unfocus();
                                FocusScope.of(context).unfocus();
                                FocusManager.instance.primaryFocus?.unfocus();
                                
                                // 使用系统方法隐藏键盘
                                try {
                                  SystemChannels.textInput.invokeMethod('TextInput.hide');
                                } catch (e) {
                                  // 静默处理失败
                                }
                                
                                // 延迟后再次确保
                                await Future.delayed(Duration(milliseconds: 50));
                                if (mounted) {
                                  FocusScope.of(context).requestFocus(FocusNode());
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.all(8),
                                child: Icon(Icons.keyboard_hide, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textInputAction: TextInputAction.newline, // 键盘显示“换行”
                                      contextMenuBuilder: TextMenuUtils.buildChineseContextMenu,
                  ),
                ),
                SizedBox(height: 24),

                // 图片预览区域 - 始终显示
                _buildImagePreviewArea(),
                SizedBox(height: 20),

                // 如果有图片则显示功能按钮
                if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty) ...[
                  Row(
                    children: [
                      // 文字布局按钮 - 先保存数据再跳转
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (mounted) {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ArticlePreviewScreen(
                                    title: _titleController.text,
                                    content: _contentController.text,
                                    author: Provider.of<AuthProvider>(context, listen: false).username ?? '',
                                    imageUrl: _previewImageUrl,
                                    initialTextPositionX: _textPositionX,
                                    initialTextPositionY: _textPositionY,
                                    articleId: widget.isEdit ? widget.article?.id : null,
                                    isEdit: widget.isEdit,
                                    imageOffsetX: 0.0,
                                    imageOffsetY: _imageOffsetY, // 传递当前图片偏移
                                    imageScale: 1.0,
                                    isLocalMode: widget.isLocalMode,
                                    localPoem: widget.localPoem,
                                  ),
                                ),
                              );
                              
                              // 从预览页面返回
                              if (result != null) {
                                if (result == 'saved' || result == 'published') {
                                  // 预览页面已保存，关闭编辑页面
                                  Navigator.of(context).pop(true);
                                } else if (result is Map) {
                                  // 返回文字位置更新（更新内存，离开时会自动保存）
                                  setState(() {
                                    _textPositionX = (result['x'] as num?)?.toDouble() ?? _textPositionX;
                                    _textPositionY = (result['y'] as num?)?.toDouble() ?? _textPositionY;
                                  });


                                }
                              }
                            }
                          },
                          icon: Icon(Icons.tune, size: 18),
                          label: Text(
                            '文字布局',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                            side: BorderSide(color: Colors.deepPurple, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      // 重新上传按钮
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                          icon: _isUploadingImage 
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                                  ),
                                )
                              : Icon(Icons.refresh, size: 18),
                          label: Text(
                            _isUploadingImage ? '上传中...' : '重新上传',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _isUploadingImage ? Colors.grey : Colors.deepPurple,
                            side: BorderSide(
                              color: _isUploadingImage ? Colors.grey : Colors.deepPurple, 
                              width: 1.5
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  // 如果没有图片，显示上传按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                      icon: _isUploadingImage 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
                              ),
                            )
                          : Icon(Icons.image_outlined, size: 20),
                      label: Text(
                        _isUploadingImage ? '正在上传...' : '上传配图',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _isUploadingImage ? Colors.grey : Colors.deepPurple,
                        side: BorderSide(
                          color: _isUploadingImage ? Colors.grey : Colors.deepPurple, 
                          width: 1.5
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}