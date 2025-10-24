# 在Xcode中添加付费开发者账号

## 步骤1：在项目中添加账号

1. **在Runner target的Signing & Capabilities页面**
2. **点击Team下拉菜单**
3. **选择最下面的 "Add an Account..."**
4. **输入你的Apple ID**（付费开发者账号的邮箱）
5. **输入密码并登录**

## 步骤2：等待同步

登录后：
- Xcode会自动下载证书和配置文件
- 等待1-2分钟让同步完成
- Team选项应该会更新显示付费团队

## 步骤3：如果还是不显示

可能需要：
1. **重启Xcode**
2. **重新打开项目**
3. **或者直接使用现有选项**（配置文件已强制使用正确团队ID）

## 验证方法

无论界面显示什么，配置文件中的强制设置会确保使用正确的团队ID：
- Debug.xcconfig: `DEVELOPMENT_TEAM = 7ZZD98JY62`
- Release.xcconfig: `DEVELOPMENT_TEAM = 7ZZD98JY62`