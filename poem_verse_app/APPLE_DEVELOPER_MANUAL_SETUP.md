# Apple Developer 手动配置指南

## 问题描述
Xcode中只显示个人团队"Owen Sha"，而不是付费开发者团队"Owen Sha (7ZZD98JY62)"

## 解决方案

### 方法1：Xcode账号重新同步

1. **清理并重新同步**：
   ```bash
   ./fix_developer_team_sync.sh
   ```

2. **在Xcode中重新配置账号**：
   - Xcode → Settings → Accounts
   - 删除现有Apple ID
   - 重新添加Apple ID
   - 点击"Download Manual Profiles"
   - 等待同步完成

### 方法2：Apple Developer网站手动配置

如果Xcode同步失败，直接在Apple Developer网站配置：

#### 1. 访问Apple Developer网站
- 登录：https://developer.apple.com
- 进入：Account → Certificates, Identifiers & Profiles

#### 2. 创建App ID（如果不存在）
- 点击：Identifiers → App IDs → "+"
- Description: PoemVerse
- Bundle ID: `com.owensha.poemverse`
- Capabilities: 根据需要选择（如Push Notifications等）

#### 3. 创建Development证书（如果需要）
- 点击：Certificates → Development → "+"
- 选择：iOS App Development
- 上传CSR文件（在钥匙串访问中生成）

#### 4. 注册设备
- 点击：Devices → "+"
- 添加你的iPhone UDID
- 获取UDID方法：连接设备，在Xcode → Window → Devices and Simulators中查看

#### 5. 创建Provisioning Profile
- 点击：Profiles → Development → "+"
- 选择：iOS App Development
- App ID: 选择刚创建的com.owensha.poemverse
- Certificate: 选择开发证书
- Devices: 选择你的设备
- 下载配置文件

#### 6. 在Xcode中使用手动配置文件
- 双击下载的.mobileprovision文件安装
- 在Xcode项目中：
  - Code Signing Style: Manual
  - Provisioning Profile: 选择刚安装的配置文件
  - Code Signing Identity: iPhone Developer

### 方法3：临时解决方案

如果急需测试，可以临时修改Bundle ID：

1. **修改为唯一ID**：
   ```
   原：com.owensha.poemverse
   改为：com.owensha.poemverse.test2024
   ```

2. **在以下位置修改**：
   - `ios/Runner/Info.plist`
   - Xcode项目设置中的Bundle Identifier
   - Apple Developer网站创建新的App ID

### 验证步骤

配置完成后：

1. **清理项目**：
   ```bash
   flutter clean
   flutter pub get
   ```

2. **重新构建**：
   ```bash
   flutter build ios --debug
   ```

3. **运行到设备**：
   ```bash
   flutter run --debug
   ```

### 常见问题解决

#### 问题：Xcode不显示付费团队
**解决**：
- 重启Xcode
- 重新登录Apple ID
- 检查网络连接
- 确认Apple Developer账号状态

#### 问题：配置文件不匹配
**解决**：
- 确保Bundle ID一致
- 重新生成配置文件
- 删除旧的配置文件

#### 问题：设备未注册
**解决**：
- 在Apple Developer网站添加设备UDID
- 重新生成配置文件

## 联系信息

如果问题仍然存在：
1. 检查Apple Developer账号续订状态（你的到期日：2026年7月1日）
2. 确认团队ID：7ZZD98JY62
3. 联系Apple Developer支持