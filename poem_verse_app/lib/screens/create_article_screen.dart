// lib/screens/create_article_screen.dart
// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/config/app_config.dart';
import 'package:poem_verse_app/models/article.dart';
import 'package:poem_verse_app/widgets/interactive_image_preview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:poem_verse_app/screens/article_preview_screen.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:poem_verse_app/api/api_service.dart';

class CreateArticleScreen extends StatefulWidget {
  final Article? article;
  final bool isEdit;
  const CreateArticleScreen({super.key, this.article, this.isEdit = false});

  @override
  CreateArticleScreenState createState() => CreateArticleScreenState();
}

class CreateArticleScreenState extends State<CreateArticleScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String? _previewImageUrl;
  bool _isCreating = false;
  double _textPositionX = 15.0; // Default to a centered position
  double _textPositionY = 200.0;
  
  // 图片变换参数
  double _imageOffsetX = 0.0;
  double _imageOffsetY = 0.0;
  double _imageScale = 1.0;

  // Preview area — for debounced transform values
  double? _previewOffsetX;
  double? _previewOffsetY;
  double? _previewScale;

  @override
  void initState() {
    super.initState();
    if (widget.isEdit && widget.article != null) {
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
      _previewOffsetX = _imageOffsetX;
      _previewOffsetY = _imageOffsetY;
      _previewScale = _imageScale;
    } else {
      // ensure defaults finite
      if (!_imageScale.isFinite) _imageScale = 1.0;
      if (!_imageOffsetX.isFinite) _imageOffsetX = 0.0;
      if (!_imageOffsetY.isFinite) _imageOffsetY = 0.0;
      
      // 新建时也初始化预览值
      _previewOffsetX = _imageOffsetX;
      _previewOffsetY = _imageOffsetY;
      _previewScale = _imageScale;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  Future<void> _saveArticle() async {
  if (_isCreating) return;
  setState(() { _isCreating = true; });

  try {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.token ?? '';

    debugPrint('DEBUG article id=${widget.article?.id}');
    debugPrint('DEBUG token=${token.isEmpty ? "EMPTY" : (token.length>16 ? token.replaceRange(8, token.length-8, "...") : token)}');

    if (token.isEmpty || token.contains('<') || token.contains('>')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('登录信息无效，请重新登录')));
      }
      setState(() { _isCreating = false; });
      return;
    }

    // 验证 article id（编辑模式）
    final articleId = widget.article?.id ?? '';
    if (widget.isEdit == true && articleId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('编辑数据异常，将以新建方式保存')));
      // 这里选择直接返回或走 create 路径，这里示例选择返回并重置状态
      setState(() { _isCreating = false; });
      return;
    }

    // 合并：优先使用 preview_ 的临时值，否则使用现有 widget.article 中保存的值，最后备选默认
    final previewUrl = _previewImageUrl ?? widget.article?.imageUrl ?? '';
    final finalImageOffsetX = _previewOffsetX ?? _imageOffsetX;
    final finalImageOffsetY = _previewOffsetY ?? _imageOffsetY;
    final finalImageScale = _previewScale ?? _imageScale;
    
    // 调试信息：打印实际要保存的偏移量数据
    debugPrint('=== 保存图片偏移量数据 ===');
    debugPrint('_previewOffsetX: $_previewOffsetX');
    debugPrint('_previewOffsetY: $_previewOffsetY');
    debugPrint('_imageOffsetX: $_imageOffsetX');
    debugPrint('_imageOffsetY: $_imageOffsetY');
    debugPrint('finalImageOffsetX: $finalImageOffsetX');
    debugPrint('finalImageOffsetY: $finalImageOffsetY');
    debugPrint('finalImageScale: $finalImageScale');
    debugPrint('========================');

    final body = {
      'title': _titleController.text,
      'content': _contentController.text,
      'author': widget.article?.author ?? auth.userId ?? '',
      'preview_image_url': previewUrl,
      'image_offset_x': finalImageOffsetX,
      'image_offset_y': finalImageOffsetY,
      'image_scale': finalImageScale,
      // 如果后端需要 text position，也一并传（可选）
      'text_position_x': _textPositionX,
      'text_position_y': _textPositionY,
    };
    
    debugPrint('保存的body数据: $body');

    // 防御性检查：articleId 不能是一个 URL（避免误把图片 URL 当 id）
    if (widget.isEdit == true) {
      if (articleId.startsWith('http')) {
        debugPrint('Refusing to update article: article.id looks like a URL -> $articleId');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('文章 id 异常，无法更新，请重试或重新打开编辑界面')));
        setState(() { _isCreating = false; });
        return;
      }
    }

    debugPrint('发送到服务器的数据: $body');
    
    http.Response resp;
    if (widget.isEdit == true && articleId.isNotEmpty) {
      // 编辑模式
      debugPrint('使用编辑模式，articleId=$articleId');
      resp = await ApiService.updateArticleWithBody(articleId, body, token: token);
    } else {
      // 创建模式
      debugPrint('使用创建模式');
      resp = await ApiService.createArticleWithBody(body, token: token);
    }
    
    debugPrint('API调用结果 status=${resp.statusCode} body=${resp.body}');

    if (resp.statusCode == 200 || resp.statusCode == 204 || resp.statusCode == 201) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存成功')));
        
        // 强制清除图片缓存
        try {
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
          debugPrint('图片缓存已清理');
        } catch (e) {
          debugPrint('清理图片缓存失败: $e');
        }
        
        // 发布成功后的导航处理
        if (widget.isEdit) {
          // 编辑模式：返回true通知上级页面刷新
          Navigator.of(context).pop(true);
        } else {
          // 创建模式：返回true，让调用者决定导航
          Navigator.of(context).pop(true);
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：${resp.statusCode}')));
      }
    }

  } catch (e) {
    debugPrint('Save article error: $e');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存出错')));
  } finally {
    if (mounted) setState(() { _isCreating = false; });
  }
}

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    
    // 检查widget是否仍然有效
    if (!mounted) return;
    
    final file = File(pickedFile.path);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('请先登录')),
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
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('图片上传成功！')),
            );
            return;
          }
        }
      }
      
      // 上传失败
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑诗篇' : '发布诗篇'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: NeverScrollableScrollPhysics(), // 临时用于调试
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 标题输入
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(labelText: '标题', border: OutlineInputBorder()),
                  contextMenuBuilder: (context, editableTextState) {
                    return AdaptiveTextSelectionToolbar.buttonItems(
                      anchors: editableTextState.contextMenuAnchors,
                      buttonItems: editableTextState.contextMenuButtonItems.map((item) {
                        switch (item.label) {
                          case 'Cut':
                            return ContextMenuButtonItem(onPressed: item.onPressed, label: '剪切');
                          case 'Copy':
                            return ContextMenuButtonItem(onPressed: item.onPressed, label: '复制');
                          case 'Paste':
                            return ContextMenuButtonItem(onPressed: item.onPressed, label: '粘贴');
                          case 'Select all':
                            return ContextMenuButtonItem(onPressed: item.onPressed, label: '全选');
                          default:
                            return item;
                        }
                      }).toList(),
                    );
                  },
                ),
                SizedBox(height: 16),
                // 内容输入
                Container(
                  height: 200,
                  child: TextField(
                    controller: _contentController,
                    decoration: InputDecoration(
                      labelText: '内容',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    contextMenuBuilder: (context, editableTextState) {
                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: editableTextState.contextMenuAnchors,
                        buttonItems: editableTextState.contextMenuButtonItems.map((item) {
                          switch (item.label) {
                            case 'Cut':
                              return ContextMenuButtonItem(onPressed: item.onPressed, label: '剪切');
                            case 'Copy':
                              return ContextMenuButtonItem(onPressed: item.onPressed, label: '复制');
                            case 'Paste':
                              return ContextMenuButtonItem(onPressed: item.onPressed, label: '粘贴');
                            case 'Select all':
                              return ContextMenuButtonItem(onPressed: item.onPressed, label: '全选');
                            default:
                              return item;
                          }
                        }).toList(),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),

                // 预览图片区域
                if (_previewImageUrl != null && _previewImageUrl!.isNotEmpty) ...[
                  Row(
                    children: [
                      Text('图片预览:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Spacer(),
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('图片调整帮助'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• 双指缩放：使用两个手指来放大或缩小图片'),
                                  SizedBox(height: 8),
                                  Text('• 单指移动：使用一个手指来移动图片位置'),
                                  SizedBox(height: 8),
                                  Text('• 重置图片：点击“重置图片”按钮恢复原始尺寸和位置'),
                                ],
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('知道了')),
                              ],
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Icon(Icons.help_outline, size: 16, color: Colors.grey[600]),
                            SizedBox(width: 4),
                            Text('上下拖动调整图片位置（发布后保持此位置）', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  // Preview area — set height to match myArticles card image height (200)
                  SizedBox(
                    width: double.infinity,
                    height: 200, // match card height
                    child: InteractiveImagePreview(
                      // 使用 public 变体
                      imageUrl: ApiService.getImageUrlWithVariant(_previewImageUrl ?? '', 'public'),
                      width: double.infinity,
                      height: 200, // ensure preview uses same height
                      initialOffsetX: _previewOffsetX ?? _imageOffsetX,
                      initialOffsetY: _previewOffsetY ?? _imageOffsetY,
                      initialScale: _previewScale ?? _imageScale,
                      onTransformChanged: (ox, oy, s) {
                        debugPrint('图片位置变化: offsetX=$ox, offsetY=$oy, scale=$s');
                        _previewOffsetX = ox;
                        _previewOffsetY = oy;
                        _previewScale = s;
                        
                        // 实时更新主值，保证下次打开时位置正确
                        _imageOffsetX = ox;
                        _imageOffsetY = oy;
                        _imageScale = s;
                      },
                      isInteractive: true,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final newPosition = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ArticlePreviewScreen(
                                  title: _titleController.text,
                                  content: _contentController.text,
                                  author: Provider.of<AuthProvider>(context, listen: false).username ?? '佚名',
                                  imageUrl: _previewImageUrl,
                                  initialTextPositionX: _textPositionX,
                                  initialTextPositionY: _textPositionY,
                                ),
                              ),
                            );
                            if (newPosition != null) {
                              setState(() {
                                _textPositionX = (newPosition['x'] as num?)?.toDouble() ?? 15.0;
                                _textPositionY = (newPosition['y'] as num?)?.toDouble() ?? 200.0;
                              });
                            }
                          },
                          icon: Icon(Icons.tune, size: 18),
                          label: Text('调整文字'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.deepPurple,
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickAndUploadImage,
                          icon: Icon(Icons.refresh, size: 18),
                          label: Text('重新上传'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.deepPurple),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],

                // 底部按钮区域
                if (_previewImageUrl == null || _previewImageUrl!.isEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _pickAndUploadImage,
                      icon: Icon(Icons.image_outlined, size: 20),
                      label: Text('上传配图', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.deepPurple,
                        side: BorderSide(color: Colors.deepPurple, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isCreating ? null : _saveArticle,
                    icon: _isCreating ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.send_rounded, size: 20),
                    label: Text(_isCreating ? '发布中...' : '发布诗篇', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}