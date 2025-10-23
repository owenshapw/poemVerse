# Universal Links 部署指南

## 🎉 功能完成

后端已成功添加网页版密码重置功能！现在支持：

1. ✅ **网页版重置密码页面** (`/reset-password`)
2. ✅ **HTML邮件模板** (美观的邮件设计)
3. ✅ **Universal Links支持** (iOS/Android)
4. ✅ **向后兼容** (仍支持原有API)

## 🚀 立即测试

### 1. 设置环境变量

在 `.env` 文件中添加：
```bash
BASE_URL=http://localhost:5001  # 本地测试
# 或生产环境: BASE_URL=https://your-domain.com
```

### 2. 重启后端服务

```bash
cd poem_app_backend
python3 app.py
# 或使用你的常用启动命令
```

### 3. 测试密码重置流程

1. **发送重置邮件**：
```bash
curl -X POST http://localhost:5001/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "your-email@example.com"}'
```

2. **检查邮件** - 现在会收到包含以下链接的美观HTML邮件：
```
http://localhost:5001/reset-password?token=xxx
```

3. **在浏览器中打开链接** - 会看到美观的重置密码页面 ✨

4. **输入新密码并提交** - 完成重置流程

## 📧 邮件示例

新的邮件格式：
```html
📝 诗篇
重置密码

您好，

我们收到了您的密码重置请求。点击下面的按钮重置您的密码：

[🔑 重置密码] <- 这是一个美观的按钮

如果按钮无法点击，请复制以下链接到浏览器：
http://localhost:5001/reset-password?token=xxx

此链接将在1小时后失效。如果您没有申请密码重置，请忽略此邮件。

下载诗篇应用获得更好体验：
App Store | Google Play
```

## 🔧 配置更新

### 修改的文件：

1. **`routes/auth.py`**:
   - ✅ 添加 `/reset-password` GET 路由（显示重置页面）
   - ✅ 更新邮件模板为HTML格式
   - ✅ 使用BASE_URL生成重置链接

2. **`templates/reset-password.html`**:
   - ✅ 美观的重置密码页面
   - ✅ 前端JavaScript验证
   - ✅ 实时表单验证
   - ✅ 加载状态提示

3. **`utils/mail.py`**:
   - ✅ 支持HTML邮件发送
   - ✅ 保持纯文本备用版本

4. **`app.py`**:
   - ✅ 添加Universal Links验证文件路由
   - ✅ 注册新的认证路由

5. **`config.py`**:
   - ✅ 添加BASE_URL配置

6. **`static/`**:
   - ✅ `apple-app-site-association` (iOS验证)
   - ✅ `assetlinks.json` (Android验证)

## 🌐 生产部署

### 1. 更新域名配置

在生产环境的 `.env` 文件中设置：
```bash
BASE_URL=https://your-production-domain.com
```

### 2. 配置Universal Links验证文件

更新以下文件中的占位符：

**`static/apple-app-site-association`**:
```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["YOUR_TEAM_ID.com.owensha.poemverse"],
        "components": [
          {
            "/": "/reset-password*",
            "comment": "Password reset links"
          }
        ]
      }
    ]
  }
}
```

**`static/assetlinks.json`**:
```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.owensha.poemverse",
      "sha256_cert_fingerprints": [
        "YOUR_APP_SHA256_FINGERPRINT"
      ]
    }
  }
]
```

### 3. 验证部署

部署后验证以下端点：

1. **重置页面**: `https://your-domain.com/reset-password?token=test`
2. **iOS验证**: `https://your-domain.com/.well-known/apple-app-site-association`
3. **Android验证**: `https://your-domain.com/.well-known/assetlinks.json`

## 🔄 用户体验流程

现在的完整流程：

1. **用户申请重置** → 在应用中点击"忘记密码"
2. **系统发送邮件** → 包含 `https://your-domain.com/reset-password?token=xxx`
3. **用户点击链接**:
   - 在电脑上 → 在浏览器中打开重置页面 ✅
   - 在手机上且已安装应用 → 直接打开应用 ✅
   - 在手机上且未安装应用 → 在浏览器中打开重置页面 ✅
4. **重置成功** → 使用新密码登录应用

## 🐛 故障排除

### 常见问题：

1. **邮件中仍然是旧链接格式**:
   - 检查 `BASE_URL` 环境变量是否设置
   - 重启后端服务

2. **重置页面显示错误**:
   - 检查JWT token是否有效
   - 查看浏览器开发者工具的错误信息

3. **Universal Links不工作**:
   - 确保验证文件可访问
   - 更新移动应用中的域名配置

4. **HTML邮件不显示**:
   - 检查邮件客户端是否支持HTML
   - 查看纯文本版本是否正常

## 📱 移动应用配置

记得同步更新Flutter应用中的域名：

**`lib/main.dart`**:
```dart
else if (uri.scheme == 'https' && uri.host == 'your-production-domain.com') {
```

**Android `AndroidManifest.xml`**:
```xml
<data android:scheme="https"
      android:host="your-production-domain.com"
      android:pathPrefix="/reset-password" />
```

**iOS `Info.plist`**:
```xml
<string>applinks:your-production-domain.com</string>
```

## ✅ 测试清单

- [ ] 本地测试重置密码邮件发送
- [ ] 浏览器中打开重置链接
- [ ] 完成密码重置流程
- [ ] 验证新密码可登录
- [ ] 部署验证文件到生产环境
- [ ] 在真机上测试Universal Links
- [ ] 检查邮件在不同客户端的显示效果

现在您可以在浏览器中正常使用重置密码链接了！🎉