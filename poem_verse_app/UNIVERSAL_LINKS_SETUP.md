# Universal Links / App Links 配置指南

## 概述

现在应用支持两种链接格式：

1. **Custom Scheme** (向后兼容):
   - `poemverse://reset-password?token=xxx`

2. **Universal Links / App Links** (新增):
   - `https://poemverse.example.com/reset-password?token=xxx`

## 后端服务器配置

### 1. 域名配置

请将 `poemverse.example.com` 替换为您的实际域名，例如：
- `api.poemverse.com`
- `poemverse.herokuapp.com` 
- `your-domain.com`

### 2. iOS Universal Links 配置

将 `server_config/apple-app-site-association` 文件部署到您的服务器：

```bash
# 文件路径（注意没有文件扩展名）
https://your-domain.com/.well-known/apple-app-site-association

# 或者直接放在根目录
https://your-domain.com/apple-app-site-association
```

**重要配置**:
1. 将 `TEAM_ID` 替换为您的 Apple Developer Team ID
2. 确保文件通过 HTTPS 访问
3. Content-Type 应该是 `application/json`

### 3. Android App Links 配置

将 `server_config/assetlinks.json` 文件部署到：

```bash
https://your-domain.com/.well-known/assetlinks.json
```

**获取 SHA256 指纹**:
```bash
# Debug版本
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release版本
keytool -list -v -keystore your-release-key.keystore -alias your-key-alias
```

## 应用配置更新

### 1. 更新域名

在以下文件中将 `poemverse.example.com` 替换为实际域名：

- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`  
- `lib/main.dart`

### 2. Android 配置

```xml
<!-- AndroidManifest.xml -->
<data android:scheme="https"
      android:host="YOUR_ACTUAL_DOMAIN"
      android:pathPrefix="/reset-password" />
```

### 3. iOS 配置

```xml
<!-- Info.plist -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:YOUR_ACTUAL_DOMAIN</string>
</array>
```

### 4. Flutter 代码

```dart
// main.dart
else if (uri.scheme == 'https' && uri.host == 'YOUR_ACTUAL_DOMAIN') {
```

## 后端邮件模板更新

现在可以在邮件中使用 HTTPS 链接：

```html
<!DOCTYPE html>
<html>
<body>
    <h2>重置密码</h2>
    <p>点击下面的链接重置您的密码：</p>
    
    <!-- Universal Link - 在浏览器中可用，在应用中自动打开应用 -->
    <a href="https://your-domain.com/reset-password?token={{token}}">
        重置密码
    </a>
    
    <p>此链接将在24小时后失效。</p>
    
    <!-- 可选：提供应用下载链接 -->
    <p>
        <small>
            没有安装PoemVerse应用？
            <a href="https://apps.apple.com/app/poemverse">iOS下载</a> |
            <a href="https://play.google.com/store/apps/details?id=com.owensha.poemverse">Android下载</a>
        </small>
    </p>
</body>
</html>
```

## 测试

### 1. 本地测试（开发环境）

由于需要HTTPS域名验证，本地开发时仍使用custom scheme：
```bash
# iOS模拟器
xcrun simctl openurl booted "poemverse://reset-password?token=xxx"

# Android模拟器  
adb shell am start -W -a android.intent.action.VIEW -d "poemverse://reset-password?token=xxx" com.owensha.poemverse
```

### 2. 生产环境测试

部署后可以测试Universal Links：
- 在Safari/Chrome中打开：`https://your-domain.com/reset-password?token=xxx`
- 应用已安装：自动打开应用
- 应用未安装：在浏览器中显示网页版重置页面

## 验证配置

### iOS Universal Links 验证工具:
- [Apple Universal Links Validator](https://search.developer.apple.com/appsearch-validation-tool/)

### Android App Links 验证工具:
- [Google Digital Asset Links Tester](https://developers.google.com/digital-asset-links/tools/generator)

## 故障排除

### 常见问题:

1. **Universal Links不工作**:
   - 检查HTTPS证书是否有效
   - 验证 apple-app-site-association 文件格式
   - 确保Team ID正确

2. **App Links不工作**:
   - 验证SHA256指纹是否正确
   - 检查assetlinks.json文件访问权限
   - 确保包名匹配

3. **链接在浏览器中打开而不是应用**:
   - iOS: 长按链接选择"Open in App"  
   - Android: 检查App Links验证状态

## 部署检查清单

- [ ] 将验证文件部署到服务器
- [ ] 更新应用中的域名配置  
- [ ] 获取并配置正确的证书指纹
- [ ] 更新邮件模板使用HTTPS链接
- [ ] 在真机上测试Universal Links
- [ ] 验证浏览器回退功能正常

配置完成后，用户就可以在电脑浏览器中点击邮件链接完成密码重置了！