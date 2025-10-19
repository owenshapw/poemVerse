# 文章可见性控制功能部署指南

## 概述

此功能允许登录用户控制自己的作品是否在首页向未登录用户展示。用户可以将作品设置为"公开"（在首页展示）或"私密"（仅个人可见）。

## 数据库更改

### 1. 执行数据库迁移

运行以下SQL脚本来添加必要的数据库字段和索引：

```bash
# 连接到你的Supabase数据库，执行以下文件中的SQL：
psql -h [your-supabase-host] -d postgres -U postgres -f poem_app_backend/database_migrations/add_article_visibility.sql
```

或者在Supabase Dashboard的SQL编辑器中执行：

```sql
-- 为articles表添加可见性控制字段
ALTER TABLE articles ADD COLUMN IF NOT EXISTS is_public_visible BOOLEAN DEFAULT true;

-- 添加索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_articles_public_visible ON articles(is_public_visible);

-- 创建组合索引，用于首页查询优化
CREATE INDEX IF NOT EXISTS idx_articles_public_created ON articles(is_public_visible, created_at DESC);

-- 更新现有文章为公开可见
UPDATE articles SET is_public_visible = true WHERE is_public_visible IS NULL;
```

### 2. 验证数据库更改

确认以下内容已正确应用：
- `articles` 表包含 `is_public_visible` 字段（BOOLEAN类型，默认值为true）
- 索引已创建：`idx_articles_public_visible` 和 `idx_articles_public_created`
- 所有现有文章的 `is_public_visible` 字段都设置为 `true`

## 后端部署

### 1. 部署后端代码更改

确保以下文件的更改已部署到生产环境：

- `poem_app_backend/routes/articles.py` - 新增可见性控制API端点
- `poem_app_backend/models/supabase_client.py` - 更新数据库操作方法

### 2. 新增的API端点

#### PATCH `/articles/{article_id}/visibility`

**用途**: 更新文章的首页可见性

**认证**: 需要JWT token

**请求体**:
```json
{
  "is_public_visible": true  // 或 false
}
```

**响应**:
```json
{
  "success": true,
  "article_id": "文章ID",
  "is_public_visible": true,
  "message": "文章已设置为公开"
}
```

### 3. API行为更改

以下现有API的行为已更新，增加了可见性过滤：

- `GET /articles/home` - 现在只返回公开可见的文章
- `GET /articles/grouped/by-author-count` - 现在只返回公开可见的文章
- `GET /articles` - 现在只返回公开可见的文章

**注意**: `GET /articles/grouped/by-author/{author}` 和用户个人文章接口不受影响，仍返回所有文章。

## 前端部署

### 1. 部署前端代码更改

确保以下文件的更改已部署：

- `poem_verse_app/lib/models/article.dart` - 添加 `isPublicVisible` 字段
- `poem_verse_app/lib/api/api_service.dart` - 添加可见性更新API调用
- `poem_verse_app/lib/services/user_service.dart` - 新增用户认证服务
- `poem_verse_app/lib/screens/author_works_screen.dart` - 添加可见性控制UI

### 2. 新功能说明

**对于作者本人**（登录后查看自己的作品集）：
- 可以看到右上角的可见性控制图标（地球图标=公开，锁定图标=私密）
- 底部状态条显示当前可见性状态和切换按钮
- 点击任何控制元素都可以切换可见性

**对于其他用户**：
- 看不到可见性控制元素
- 只能看到作者设置为公开的作品

## 测试验证

### 1. 功能测试

1. **数据库测试**:
   ```sql
   -- 验证字段存在
   SELECT column_name, data_type, column_default 
   FROM information_schema.columns 
   WHERE table_name = 'articles' AND column_name = 'is_public_visible';
   
   -- 验证现有数据
   SELECT id, title, is_public_visible FROM articles LIMIT 5;
   ```

2. **API测试**:
   ```bash
   # 测试更新可见性
   curl -X PATCH "https://your-api-url/articles/{article_id}/visibility" \
        -H "Authorization: Bearer {your_token}" \
        -H "Content-Type: application/json" \
        -d '{"is_public_visible": false}'
   ```

3. **前端测试**:
   - 登录作者账号，查看自己的作品集
   - 确认可以看到可见性控制元素
   - 测试切换可见性功能
   - 验证首页是否正确过滤私密作品

### 2. 性能测试

- 验证新增的数据库索引是否提高了查询性能
- 测试大量数据下的首页加载速度

## 回滚计划

如果需要回滚此功能：

### 1. 前端回滚
- 恢复到之前版本的前端代码
- 移除 `UserService` 文件

### 2. 后端回滚
- 恢复 `routes/articles.py` 到之前版本
- 恢复 `models/supabase_client.py` 到之前版本

### 3. 数据库回滚（可选）
```sql
-- 如果需要完全移除字段（不推荐，因为会丢失数据）
ALTER TABLE articles DROP COLUMN IF EXISTS is_public_visible;

-- 如果只是想让所有文章都公开可见
UPDATE articles SET is_public_visible = true;
```

## 监控建议

1. **监控指标**:
   - API响应时间（特别是 `/articles/visibility` 端点）
   - 首页文章加载性能
   - 可见性切换操作的成功率

2. **日志监控**:
   - 可见性更新操作的日志
   - 权限验证失败的日志
   - 数据库查询性能日志

## 支持与维护

- 此功能需要用户登录才能使用
- 确保JWT token验证正常工作
- 定期检查数据库索引的性能
- 监控用户对此功能的使用情况

## 常见问题

**Q: 现有用户的文章默认是什么状态？**
A: 所有现有文章默认设置为公开可见（`is_public_visible = true`）

**Q: 未登录用户能看到什么？**
A: 未登录用户只能在首页看到设置为公开的文章，无法看到任何可见性控制元素

**Q: 文章作者能看到私密文章吗？**
A: 是的，作者在自己的作品集页面可以看到所有文章（包括私密的），但私密文章不会出现在首页

**Q: 性能影响如何？**
A: 通过添加数据库索引，对性能的影响最小化。首页查询会略有变化但应该保持高效。