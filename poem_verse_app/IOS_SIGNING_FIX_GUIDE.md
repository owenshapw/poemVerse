# iOS 签名问题解决指南

## 问题描述
```
ERROR: Failed to install the app on the device. (com.apple.dt.CoreDeviceError error 3002)
Failed to install embedded profile for com.owensha.poemverse : 0xe800801f 
(Attempted to install a Beta profile without the proper entitlement.)
```

## 解决方案

### 方法1：自动修复脚本
```bash
cd poem_verse_app
./fix_ios_signing.sh
```

### 方法2：手动修复步骤

#### 1. 清理项目
```bash
cd poem_verse_app
flutter clean
rm -rf ios/Pods ios/Podfile.lock
flutter pub get
cd ios && pod install && cd ..
```

#### 2. 在Xcode中配置签名
1. 打开项目：
   ```bash
   open ios/Runner.xcworkspace
   ```

2. 选择 **Runner** target

3. 进入 **Signing & Capabilities** 标签页

4. **重要配置**：
   - **Code Signing Style**: 改为 `Automatic`
   - **Team**: 选择你的开发团队 (7ZZD98JY62)
   - **Bundle Identifier**: 确认为 `com.owensha.poemverse`

#### 3. 设备配置
确保你的设备：
- 已连接到Mac
- 已信任开发者证书
- 已添加到Apple Developer账号的设备列表

### 方法3：使用免费开发者账号

如果使用免费Apple ID：

1. **修改Bundle ID**：
   ```
   原ID：com.owensha.poemverse
   改为：com.你的姓名.poemverse.unique
   ```

2. **在Xcode中**：
   - Code Signing Style: `Automatic`
   - Team: 选择你的个人团队
   - Bundle Identifier: 使用修改后的唯一ID

3. **修改Flutter项目中的Bundle ID**：
   编辑 `ios/Runner/Info.plist`：
   ```xml
   <key>CFBundleIdentifier</key>
   <string>com.你的姓名.poemverse.unique</string>
   ```

### 方法4：命令行快速修复

```bash
# 进入项目目录
cd poem_verse_app

# 清理并重新构建
flutter clean
flutter pub get

# 使用Flutter重新构建iOS
flutter build ios --debug

# 运行到设备
flutter run --debug
```

### 常见问题排除

#### 问题1：配置文件过期
**解决**：在Xcode中删除旧的配置文件，重新生成

#### 问题2：设备未信任证书
**解决**：
1. 设备设置 → 通用 → VPN与设备管理
2. 找到开发者应用，点击信任

#### 问题3：Bundle ID冲突
**解决**：修改为唯一的Bundle ID

#### 问题4：开发者账号权限不足
**解决**：
- 升级到付费开发者账号，或
- 使用免费账号但修改Bundle ID

### 验证修复

修复后运行：
```bash
flutter run --debug
```

如果仍有问题，可以尝试：
```bash
flutter run --debug --verbose
```

## 预防措施

1. **定期更新证书**：开发者证书有过期时间
2. **保持Xcode更新**：使用最新版本的Xcode
3. **备份配置**：保存工作的签名配置
4. **使用版本控制**：不要提交证书文件到Git

## 联系支持

如果问题仍然存在：
1. 检查Apple Developer账号状态
2. 确认设备UDID已注册
3. 考虑重新生成所有证书和配置文件