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

import 'dart:io';
import 'package:dio/dio.dart';

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
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  // 保存本地图片偏移数据（不发布到服务器）
  void _saveLocalImageData() {
    // 更新本地图片偏移数据
    _imageOffsetX = _previewOffsetX ?? _imageOffsetX;
    _imageOffsetY = _previewOffsetY ?? _imageOffsetY;
    _imageScale = _previewScale ?? _imageScale;
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
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
    return InteractiveImagePreview(
      imageUrl: ApiService.getImageUrlWithVariant(_previewImageUrl ?? '', 'public'),
      width: double.infinity,
      height: 180,
      initialOffsetX: _previewOffsetX ?? _imageOffsetX,
      initialOffsetY: _previewOffsetY ?? _imageOffsetY,
      initialScale: _previewScale ?? _imageScale,
      onTransformChanged: (ox, oy, s) {
        _previewOffsetX = ox;
        _previewOffsetY = oy;
        _previewScale = s;
        
        _imageOffsetX = ox;
        _imageOffsetY = oy;
        _imageScale = s;
      },
      isInteractive: true,
      fit: BoxFit.cover,
    );
  }

  // 空状态预览 - 纯净的浅色占位符
  Widget _buildEmptyPreview() {
    return Container(
      color: Color(0xFFFAFAFA), // 非常浅的灰色占位符
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(widget.isEdit ? '编辑诗篇' : '发布诗篇'),
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
                          case 'Select All':
                            return ContextMenuButtonItem(onPressed: item.onPressed, label: '全选');
                          case 'Look Up':
                            return ContextMenuButtonItem(onPressed: item.onPressed, label: '查询');
                          case 'Search Web':
                            return ContextMenuButtonItem(onPressed: item.onPressed, label: '网页搜索');
                          case 'Share':
                            return ContextMenuButtonItem(onPressed: item.onPressed, label: '分享');
                          default:
                            return item;
                        }
                      }).toList(),
                    );
                  },
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
                            case 'Select All':
                              return ContextMenuButtonItem(onPressed: item.onPressed, label: '全选');
                            case 'Look Up':
                              return ContextMenuButtonItem(onPressed: item.onPressed, label: '查询');
                            case 'Search Web':
                              return ContextMenuButtonItem(onPressed: item.onPressed, label: '网页搜索');
                            case 'Share':
                              return ContextMenuButtonItem(onPressed: item.onPressed, label: '分享');
                            default:
                              return item;
                          }
                        }).toList(),
                      );
                    },
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
                            // 保存本地图片偏移数据并跳转预览页面
                            _saveLocalImageData();
                            if (mounted) {
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
                                    articleId: widget.isEdit ? widget.article?.id : null,
                                    isEdit: widget.isEdit,
                                    imageOffsetX: _previewOffsetX ?? _imageOffsetX,
                                    imageOffsetY: _previewOffsetY ?? _imageOffsetY,
                                    imageScale: _previewScale ?? _imageScale,
                                  ),
                                ),
                              );
                              if (newPosition != null) {
                                if (newPosition == 'published') {
                                  // 从预览页面发布成功，关闭当前页面
                                  // 注意：预览页面现在会直接跳转到作品集，不会返回这个状态
                                  Navigator.of(context).pop(true);
                                } else if (newPosition is Map) {
                                  // 返回文字位置更新
                                  setState(() {
                                    _textPositionX = (newPosition['x'] as num?)?.toDouble() ?? 15.0;
                                    _textPositionY = (newPosition['y'] as num?)?.toDouble() ?? 200.0;
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