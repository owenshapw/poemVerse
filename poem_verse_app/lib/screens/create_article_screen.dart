// lib/screens/create_article_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/config/app_config.dart';

class CreateArticleScreen extends StatefulWidget {
  const CreateArticleScreen({super.key});

  @override
  _CreateArticleScreenState createState() => _CreateArticleScreenState();
}

class _CreateArticleScreenState extends State<CreateArticleScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  List<String> _tags = [];
  String? _previewImageUrl;
  bool _isGeneratingPreview = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagsController.clear();
      });
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _generatePreview() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请先填写标题和内容')),
      );
      return;
    }

    setState(() {
      _isGeneratingPreview = true;
    });

    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final previewUrl = await articleProvider.generatePreview(
      authProvider.token!,
      _titleController.text,
      _contentController.text,
      _tags,
    );

    setState(() {
      _previewImageUrl = previewUrl;
      _isGeneratingPreview = false;
    });

    if (previewUrl != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预览图片生成成功！')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('预览图片生成失败')),
      );
    }
  }

  String _buildImageUrl(String imageUrl) {
    return AppConfig.buildImageUrl(imageUrl);
  }

  void _createArticle() async {
    if (_titleController.text.isEmpty || _contentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('请填写标题和内容')),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final articleProvider = Provider.of<ArticleProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    await articleProvider.createArticle(
      authProvider.token!,
      _titleController.text,
      _contentController.text,
      _tags,
    );

    setState(() {
      _isCreating = false;
    });

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('发布诗篇'),
        actions: [
          if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.preview),
              onPressed: _isGeneratingPreview ? null : _generatePreview,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '标题',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 8,
            ),
            SizedBox(height: 16),
            
            // 标签输入
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagsController,
                    decoration: InputDecoration(
                      labelText: '添加标签',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addTag,
                  child: Text('添加'),
                ),
              ],
            ),
            
            // 标签显示
            if (_tags.isNotEmpty) ...[
              SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag),
                  onDeleted: () => _removeTag(tag),
                )).toList(),
              ),
            ],
            
            SizedBox(height: 16),
            
            // 预览图片
            if (_previewImageUrl != null) ...[
              Text('预览效果:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _buildImageUrl(_previewImageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, color: Colors.red, size: 48),
                            Text('图片加载失败'),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
            
            // 生成预览按钮
            if (_previewImageUrl == null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isGeneratingPreview ? null : _generatePreview,
                  icon: _isGeneratingPreview 
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(Icons.preview),
                  label: Text(_isGeneratingPreview ? '生成中...' : '生成预览'),
                ),
              ),
            
            SizedBox(height: 16),
            
            // 发布按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createArticle,
                icon: _isCreating 
                  ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.send),
                label: Text(_isCreating ? '发布中...' : '发布诗篇'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
