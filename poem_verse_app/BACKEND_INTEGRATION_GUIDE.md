# 后端集成指南 - Universal Links支持

## 当前问题

用户收到的邮件链接仍然是：
```
poemverse://reset-password?token=xxx
```

这种深度链接只能在移动设备上工作，无法在电脑浏览器中使用。

## 需要后端实现的功能

### 1. 网页版重置密码端点

**新增API端点**:
```
GET  /reset-password?token=xxx     # 显示重置密码页面
POST /api/auth/reset-password      # 处理密码重置请求
```

**实现示例 (Node.js/Express)**:
```javascript
// 显示重置密码页面
app.get('/reset-password', (req, res) => {
  const token = req.query.token;
  
  if (!token) {
    return res.status(400).send('缺少重置令牌');
  }
  
  // 验证token是否有效（可选，也可以在前端提交时验证）
  try {
    jwt.verify(token, process.env.JWT_SECRET);
    // Token有效，返回重置密码页面
    res.sendFile(path.join(__dirname, 'public', 'reset-password.html'));
  } catch (error) {
    res.status(400).send('无效或已过期的重置链接');
  }
});

// 处理密码重置
app.post('/api/auth/reset-password', async (req, res) => {
  try {
    const { token, new_password } = req.body;
    
    // 验证token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const userId = decoded.user_id;
    
    // 验证密码强度
    if (!new_password || new_password.length < 6) {
      return res.status(400).json({ error: '密码至少需要6位字符' });
    }
    
    // 更新用户密码
    const hashedPassword = await bcrypt.hash(new_password, 10);
    await updateUserPassword(userId, hashedPassword);
    
    res.json({ message: '密码重置成功' });
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      res.status(400).json({ error: '重置链接已过期' });
    } else if (error.name === 'JsonWebTokenError') {
      res.status(400).json({ error: '无效的重置链接' });
    } else {
      res.status(500).json({ error: '服务器错误' });
    }
  }
});
```

### 2. 更新邮件模板

**当前邮件模板** (需要修改):
```html
<!-- 旧版本 - 只有深度链接 -->
<a href="poemverse://reset-password?token={{token}}">重置密码</a>
```

**新邮件模板** (推荐):
```html
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px; text-align: center; color: white;">
        <h1 style="margin: 0; font-size: 28px;">📝 诗篇</h1>
        <h2 style="margin: 10px 0 0; font-weight: normal;">重置密码</h2>
    </div>
    
    <div style="padding: 40px 20px;">
        <p>您好，</p>
        <p>我们收到了您的密码重置请求。点击下面的按钮重置您的密码：</p>
        
        <div style="text-align: center; margin: 30px 0;">
            <!-- Universal Link - 关键更改在这里 -->
            <a href="https://{{your-domain.com}}/reset-password?token={{token}}" 
               style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                      color: white; 
                      padding: 12px 30px; 
                      text-decoration: none; 
                      border-radius: 25px; 
                      font-weight: bold; 
                      display: inline-block;">
                重置密码
            </a>
        </div>
        
        <p><small>如果按钮无法点击，请复制以下链接到浏览器：<br>
        <code>https://{{your-domain.com}}/reset-password?token={{token}}</code></small></p>
        
        <p><small>此链接将在24小时后失效。如果您没有申请密码重置，请忽略此邮件。</small></p>
        
        <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
        
        <div style="text-align: center;">
            <p><small>下载诗篇应用获得更好体验：</small></p>
            <a href="https://apps.apple.com/app/poemverse" style="margin: 0 10px; color: #667eea;">App Store</a>
            <a href="https://play.google.com/store/apps/details?id=com.owensha.poemverse" style="margin: 0 10px; color: #667eea;">Google Play</a>
        </div>
    </div>
</body>
</html>
```

### 3. 静态文件部署

将以下文件部署到服务器：

1. **重置密码页面**:
```
/public/reset-password.html  (来源: web_template/reset-password.html)
```

2. **Universal Links验证文件**:
```
/.well-known/apple-app-site-association  (来源: server_config/apple-app-site-association)
/.well-known/assetlinks.json            (来源: server_config/assetlinks.json)
```

### 4. 域名配置

**重要**: 将以下配置中的域名替换为实际域名：

1. **邮件模板**: `{{your-domain.com}}` → `api.poemverse.com`
2. **验证文件**: 更新Team ID和包名
3. **Flutter应用**: 更新 `lib/main.dart` 中的域名

## 测试验证

### 1. 本地测试
```bash
# 测试重置页面
curl http://localhost:3000/reset-password?token=test

# 测试API端点
curl -X POST http://localhost:3000/api/auth/reset-password \
  -H "Content-Type: application/json" \
  -d '{"token":"test","new_password":"newpass123"}'
```

### 2. 生产环境测试
```bash
# 验证Universal Links配置
curl https://your-domain.com/.well-known/apple-app-site-association
curl https://your-domain.com/.well-known/assetlinks.json

# 测试重置页面
curl https://your-domain.com/reset-password?token=test
```

## 部署清单

- [ ] 实现 `/reset-password` GET 路由
- [ ] 实现 `/api/auth/reset-password` POST API
- [ ] 部署重置密码HTML页面
- [ ] 更新邮件模板使用HTTPS链接
- [ ] 部署Universal Links验证文件
- [ ] 更新域名配置
- [ ] 测试邮件发送
- [ ] 在真机上测试Universal Links

## 向后兼容

为了保持向后兼容，可以暂时同时支持两种格式：

```html
<!-- 主要链接 - Universal Link -->
<a href="https://your-domain.com/reset-password?token={{token}}">重置密码</a>

<!-- 备用链接 - 深度链接 (用于旧版本应用) -->
<p><small>或在手机应用中打开：<br>
<a href="poemverse://reset-password?token={{token}}">在应用中重置</a></small></p>
```

完成这些更改后，用户就可以在电脑浏览器中正常使用重置密码链接了！