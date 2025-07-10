# 预览图片重用功能优化

## 问题描述

在之前的版本中，用户发布文章时会生成两次图片：
1. **预览阶段**：生成预览图片（文件名以 `preview_` 开头）
2. **发布阶段**：重新生成正式图片（文件名以 `ai_generated_` 开头）

这导致了：
- 重复的AI API调用
- 浪费时间和资源
- 预览图片和发布图片可能不一致

## 解决方案

### 1. 前端修改

#### Flutter端修改

**文件：`poem_verse_app/lib/providers/article_provider.dart`**
- 修改 `createArticle` 方法，添加可选的 `previewImageUrl` 参数
- 支持传递预览图片URL给后端

**文件：`poem_verse_app/lib/api/api_service.dart`**
- 修改 `createArticle` API调用，支持传递 `preview_image_url` 参数

**文件：`poem_verse_app/lib/screens/create_article_screen.dart`**
- 修改 `_createArticle` 方法，传递预览图片URL

### 2. 后端修改

**文件：`poem_app_backend/routes/articles.py`**
- 修改 `create_article` 函数，支持接收 `preview_image_url` 参数
- 如果提供了预览图片URL，直接使用；否则才生成新图片

## 工作流程

### 优化前
```
用户预览 → 生成预览图片 → 用户发布 → 重新生成图片 → 保存文章
```

### 优化后
```
用户预览 → 生成预览图片 → 用户发布 → 使用预览图片 → 保存文章
```

## 代码变更

### 前端变更

```dart
// ArticleProvider
Future<void> createArticle(String token, String title, String content, List<String> tags, {String? previewImageUrl}) async {
  final response = await ApiService.createArticle(token, title, content, tags, previewImageUrl: previewImageUrl);
  // ...
}

// ApiService
static Future<http.Response> createArticle(String token, String title, String content, List<String> tags, {String? previewImageUrl}) async {
  final Map<String, dynamic> body = {
    'title': title,
    'content': content,
    'tags': tags,
  };
  
  if (previewImageUrl != null) {
    body['preview_image_url'] = previewImageUrl;
  }
  
  return await http.post(/* ... */);
}
```

### 后端变更

```python
@articles_bp.route('/articles', methods=['POST'])
@token_required
def create_article(current_user_id):
    # ...
    preview_image_url = data.get('preview_image_url')
    
    # 处理图片
    try:
        image_url = None
        
        # 如果提供了预览图片URL，直接使用
        if preview_image_url:
            print(f"使用预览图片: {preview_image_url}")
            image_url = preview_image_url
        else:
            # 否则生成新图片
            print("未提供预览图片，生成新图片")
            image_url = ai_generator.generate_poem_image(article)
            # ...
```

## 测试验证

### 测试脚本：`test_preview_reuse.py`

测试步骤：
1. 登录获取token
2. 生成预览图片
3. 使用预览图片URL发布文章
4. 验证发布的文章图片与预览图片相同
5. 获取文章列表验证

### 测试结果

```
✅ 成功：发布的文章使用了预览图片！
✅ 验证成功：文章列表中显示的是预览图片
```

## 优势

1. **节省资源**：避免重复的AI图片生成
2. **提高效率**：发布速度更快
3. **保持一致性**：预览和发布使用相同图片
4. **用户体验**：用户看到的预览就是最终效果

## 兼容性

- 向后兼容：如果不传递 `preview_image_url`，仍会生成新图片
- 不影响现有功能：所有原有功能保持不变

## 部署说明

1. 更新Flutter应用代码
2. 更新后端API代码
3. 重新编译Flutter应用
4. 重启后端服务

## 注意事项

1. 预览图片URL必须是有效的图片路径
2. 预览图片会在服务器上保留，不会被自动清理
3. 如果预览图片生成失败，仍会回退到生成新图片的逻辑 