# 编辑文章功能修复说明

## 问题描述

用户反馈：直接发布新的诗篇图片没问题，但编辑修改页面无法发布，会报错。

## 问题原因

经过代码分析发现，后端的更新文章接口（PUT `/articles/<article_id>`）缺少对预览图片URL的处理：

### 前端发送的数据
```json
{
  "title": "更新后的标题",
  "content": "更新后的内容", 
  "tags": ["标签1", "标签2"],
  "author": "作者",
  "preview_image_url": "https://imagedelivery.net/xxx/public"
}
```

### 后端处理逻辑对比

#### 创建文章接口（POST）- 正常
```python
@articles_bp.route('/articles', methods=['POST'])
def create_article(current_user_id):
    data = request.get_json()
    preview_image_url = data.get('preview_image_url')  # ✅ 有处理
    
    # 创建文章后处理图片
    if preview_image_url:
        image_url = preview_image_url
        updated_article = supabase_client.update_article_image(article['id'], image_url)
```

#### 更新文章接口（PUT）- 修复前
```python
@articles_bp.route('/articles/<article_id>', methods=['PUT'])
def update_article(current_user_id, article_id):
    data = request.get_json()
    # ❌ 缺少 preview_image_url 处理
    
    # 只更新基本信息，不处理图片
    update_data = {
        'title': title,
        'content': content,
        'tags': tags,
        'author': author
    }
```

## 修复方案

在更新文章接口中添加对 `preview_image_url` 的处理：

```python
@articles_bp.route('/articles/<article_id>', methods=['PUT'])
@token_required
def update_article(current_user_id, article_id):
    """更新文章"""
    try:
        data = request.get_json()
        title = data.get('title')
        content = data.get('content')
        tags = data.get('tags', [])
        author = data.get('author', '')
        preview_image_url = data.get('preview_image_url')  # ✅ 新增处理
        
        # ... 验证逻辑 ...
        
        # 更新文章基本信息
        update_data = {
            'title': title,
            'content': content,
            'tags': tags,
            'author': author
        }
        updated_article = supabase_client.update_article_fields(article_id, update_data)
        
        # ✅ 新增：处理图片更新
        try:
            if preview_image_url:
                print(f"更新文章图片: {preview_image_url}")
                updated_article = supabase_client.update_article_image(article_id, preview_image_url)
        except Exception as e:
            print(f"图片处理失败: {str(e)}")
            # 图片处理失败不影响文章更新
        
        return jsonify({
            'message': '文章更新成功',
            'article': updated_article
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500
```

## 修复效果

### 测试结果
- ✅ 创建文章：正常（原有功能）
- ✅ 更新文章：正常（修复后）
- ✅ 预览图片URL：正确处理
- ✅ 图片URL更新：成功保存到数据库

### 测试数据
```json
{
  "article": {
    "id": "6ac173a5-468e-471e-bd70-3f3f056fe314",
    "title": "更新后的测试文章",
    "content": "这是更新后的测试内容",
    "tags": ["更新", "测试", "文章"],
    "author": "更新后的作者",
    "image_url": "https://imagedelivery.net/4RSIo06aA9cYqJB6iDeiUA/test-image/public"
  },
  "message": "文章更新成功"
}
```

## 影响范围

### 修复的文件
- `poem_app_backend/routes/articles.py` - 更新文章接口

### 相关功能
- 编辑诗篇功能
- 预览图片更新
- 图片URL保存

## 验证方法

1. 在Flutter应用中编辑现有诗篇
2. 修改标题、内容、标签
3. 生成新的预览图片
4. 点击发布
5. 验证文章和图片是否正确更新

## 总结

通过在后端更新文章接口中添加对 `preview_image_url` 参数的处理，解决了编辑修改页面无法发布的问题。现在编辑功能与创建功能保持一致，都能正确处理预览图片URL。 