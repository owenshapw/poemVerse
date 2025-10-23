# 🔍 Token 调试指南

## ❌ 问题现象

访问重置密码链接时提示：**"缺少重置令牌，请重新申请密码重置。"**

## 🛠️ 已添加的调试功能

### 1. **后端调试日志**
- 在 `/reset-password` 路由中添加了详细日志
- 可以在服务器日志中看到接收到的URL和参数

### 2. **前端调试信息**
- 在浏览器控制台显示URL和token信息
- 在错误页面显示完整请求URL

### 3. **URL编码修复**
- 对JWT token进行URL编码，防止特殊字符问题
- 添加前端URL解码逻辑

### 4. **测试页面**
- 新增 `/test-reset` 路由用于测试页面显示

## 🔧 调试步骤

### 1. **重新部署后端**
确保包含最新的调试功能：
```bash
git add .
git commit -m "Add token debugging and URL encoding"
git push
```

### 2. **测试基本页面显示**
访问测试页面验证模板正常：
```
https://your-domain.com/test-reset
```
应该显示重置密码页面，不会有token错误。

### 3. **生成新的重置邮件**
重新申请密码重置，获得新的邮件链接：
```bash
curl -X POST https://your-domain.com/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "your-email@example.com"}'
```

### 4. **检查邮件链接格式**
新邮件中的链接应该是：
```
https://your-domain.com/reset-password?token=eyJ...
```

### 5. **检查浏览器控制台**
打开链接时，按F12打开开发者工具，查看Console标签中的调试信息：
```
Current URL: https://...
URL Search: ?token=...
Token from backend: ...
```

### 6. **检查服务器日志**
在部署平台查看服务器日志，应该看到：
```
Reset password page accessed
Full URL: https://...
Query args: ImmutableMultiDict([('token', '...')])
Token received: Yes/No
Token length: ...
```

## 🐛 常见问题排查

### 问题1：Token被截断
**症状**：服务器日志显示token长度异常短

**解决**：
- 检查邮件客户端是否截断了长URL
- 尝试在不同的邮件客户端中打开
- 手动复制完整链接到浏览器

### 问题2：URL编码问题
**症状**：Token包含 `%20`, `%2B` 等编码字符

**解决**：
- 已添加URL编码/解码处理
- 检查浏览器是否正确解码URL

### 问题3：邮件格式问题
**症状**：邮件中的链接无法点击或格式异常

**解决**：
```bash
# 测试邮件发送功能
curl -X POST http://localhost:5001/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "test@example.com"}'
```

### 问题4：路由冲突
**症状**：访问重置页面返回404或其他错误

**解决**：
- 检查路由是否正确注册
- 验证 `/test-reset` 是否正常工作

## 📧 手动测试链接

如果邮件链接有问题，可以手动构造测试链接：

1. **获取有效token**：
```bash
# 申请重置，从服务器日志中复制token
curl -X POST https://your-domain.com/api/auth/forgot-password \
  -H "Content-Type: application/json" \
  -d '{"email": "your-email@example.com"}'
```

2. **手动访问重置页面**：
```
https://your-domain.com/reset-password?token=YOUR_TOKEN_HERE
```

## ✅ 验证修复成功

修复成功后应该看到：
- ✅ 浏览器控制台显示正确的token信息
- ✅ 服务器日志显示token接收成功
- ✅ 重置页面正常显示表单
- ✅ 可以成功重置密码

## 🆘 如果问题仍存在

提供以下信息：
1. 浏览器控制台的完整输出
2. 服务器日志中的相关条目
3. 邮件中实际收到的链接
4. 使用的邮件客户端类型

这样可以进一步定位问题原因。