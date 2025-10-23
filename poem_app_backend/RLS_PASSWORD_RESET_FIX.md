# 🔐 RLS权限问题修复 - 密码重置

## ❌ 问题根因

您说得对！重置密码确实与数据库行权限(RLS)有关。当用户重置密码时：

1. **用户未登录** - 没有有效的认证session
2. **RLS策略阻止** - Supabase的行级安全策略可能不允许匿名用户更新user记录
3. **权限不足** - 需要管理员权限来更新密码

## ✅ 解决方案

### 1. **双客户端架构**

现在使用两个Supabase客户端：
```python
# 普通客户端（anon key）- 受RLS限制
self.supabase = create_client(url, anon_key)

# 服务客户端（service role key）- 绕过RLS
self.service_supabase = create_client(url, service_role_key)
```

### 2. **优先使用Supabase Auth API**

```python
def update_user_password_via_auth(self, user_id: str, new_password: str):
    # 使用Admin API直接更新Supabase Auth的密码
    response = self.supabase.auth.admin.update_user_by_id(
        user_id, 
        {"password": new_password}
    )
```

### 3. **备用方案：服务端权限**

如果Auth API失败，使用服务端客户端直接更新：
```python
def update_user_password_hash(self, user_id: str, new_password: str):
    # 使用service role key客户端，可以绕过RLS
    client_to_use = self.service_supabase if self.service_supabase else self.supabase
    result = client_to_use.table('users').update({...}).eq('id', user_id).execute()
```

## 🔧 配置要求

### 1. **添加Service Role Key**

在环境变量中添加：
```bash
# .env文件
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_KEY=your-anon-key                    # 现有的
SUPABASE_SERVICE_KEY=your-service-role-key    # 新增的
```

### 2. **获取Service Role Key**

1. 打开Supabase项目控制台
2. 进入 **Settings** > **API** 
3. 复制 **service_role** key（⚠️ 保密！）
4. 添加到生产环境的环境变量中

### 3. **验证RLS策略**

在Supabase控制台检查 `users` 表的RLS策略：

```sql
-- 查看现有策略
SELECT * FROM pg_policies WHERE tablename = 'users';

-- 可能需要的策略（仅供参考）
CREATE POLICY "Users can update own profile" ON users
FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Service role can update any user" ON users
FOR ALL USING (current_setting('role') = 'service_role');
```

## 🚀 部署步骤

### 1. **更新环境变量**

在Render或其他部署平台添加：
```
SUPABASE_SERVICE_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2. **重新部署**

部署最新的代码，包含RLS修复。

### 3. **测试验证**

1. **申请密码重置**：
```bash
curl -X POST https://poemverse.onrender.com/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "your-email@example.com"}'
```

2. **使用邮件中的链接重置密码**

3. **检查日志**，应该看到：
```
Password update result: [{'id': '...', 'updated_at': '...'}]
```

## 📊 调试信息

### 成功的日志应该显示：
```
Password update result: [{'id': 'user-uuid', 'updated_at': '2024-...'}]
```

### 失败的日志可能显示：
```
Error updating password hash: new row violates row-level security policy
```

## 🔒 安全性说明

### Service Role Key的使用：
- ✅ **仅用于服务端操作**（密码重置、管理功能）
- ✅ **不暴露给前端**
- ✅ **严格权限控制**
- ❌ **不用于常规用户操作**

### 权限分离：
- **Anon Key**: 用户注册、登录、查看公开内容
- **Service Role Key**: 管理员操作、系统级更新、绕过RLS

## 🐛 故障排除

### 1. 如果仍然失败：

检查Supabase项目设置：
- API Settings中是否有Service Role Key
- RLS是否正确配置
- users表结构是否正确

### 2. 临时禁用RLS测试：

```sql
-- 临时禁用users表RLS（仅测试用）
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- 测试完成后重新启用
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
```

### 3. 检查网络连接：

确保部署环境可以访问Supabase API。

现在重新部署并测试，应该可以解决密码重置的权限问题了！