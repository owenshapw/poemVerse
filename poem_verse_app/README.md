# PoemVerse App
诗章 - 一个优雅的诗歌分享与创作应用

## 功能特性

### 用户认证
- 用户注册与登录
- **找回密码功能** 📧
  - 通过邮箱重置密码
  - 安全的密码重置流程
  - 邮件验证机制
  - **Universal Links支持** - 邮件链接可在浏览器和应用中使用
- 安全的JWT令牌认证

### 诗歌创作与管理
- 创建、编辑和删除诗歌
- 支持标签分类
- 个人作品管理
- 作品可见性控制

### 浏览与发现
- 首页推荐文章
- 按作者浏览作品
- 文章详情页面
- 点赞功能

### 美观界面
- 现代化材料设计
- 响应式布局
- 优雅的毛玻璃效果
- 深色渐变背景

## 找回密码功能

新增的找回密码功能包括：

### 深度链接支持 🔗

应用现在支持通过邮件中的深度链接直接跳转：
- **链接格式**: `poemverse://reset-password?token=<JWT_TOKEN>`
- **自动跳转**: 点击邮件链接自动打开应用并跳转到重置页面
- **平台支持**: Android 和 iOS 全平台支持
- **安全验证**: JWT token 自动验证和处理

1. **忘记密码入口**
   - 在登录页面点击"忘记密码？"链接
   - 跳转到找回密码页面

2. **邮箱验证**
   - 输入注册邮箱地址
   - 系统发送重置密码邮件
   - 支持重新发送功能

3. **密码重置**
   - 通过邮件中的链接访问重置页面
   - 输入新密码并确认
   - 安全的密码重置流程

## 技术栈

- **前端**: Flutter 3.x
- **状态管理**: Provider
- **网络请求**: HTTP
- **本地存储**: SharedPreferences
- **UI组件**: Material Design
- **深度链接**: app_links 6.3.2+

### 深度链接配置
- **Android**: `AndroidManifest.xml` 中的 intent-filter 配置
- **iOS**: `Info.plist` 中的 CFBundleURLTypes 配置
- **Flutter**: `app_links` 包处理深度链接逻辑

## 安装与运行

### 前提条件
- Flutter SDK 3.0+
- Dart 3.0+
- iOS/Android 开发环境

### 安装步骤

1. 克隆项目
```bash
git clone <repository-url>
cd poem_verse_app
```

2. 安装依赖
```bash
flutter pub get
```

3. 配置深度链接（可选）
   - Android: 已在 `AndroidManifest.xml` 中配置
   - iOS: 已在 `Info.plist` 中配置
   - 无需额外配置即可使用

4. 配置环境变量
```bash
# 创建 .env 文件
cp .env.example .env
# 编辑 .env 文件，配置后端API地址
```

5. 运行应用
```bash
flutter run
```

## 项目结构

```
lib/
├── api/
│   └── api_service.dart          # API服务
├── config/
│   └── app_config.dart           # 应用配置
├── models/
│   └── article.dart              # 数据模型
├── providers/
│   ├── auth_provider.dart        # 认证状态管理
│   └── article_provider.dart     # 文章状态管理
├── screens/
│   ├── login_screen.dart         # 登录页面
│   ├── forgot_password_screen.dart # 找回密码页面 ✨
│   ├── reset_password_screen.dart  # 重置密码页面 ✨
│   ├── register_screen.dart      # 注册页面
│   ├── home_screen.dart          # 首页
│   └── ...
├── android/app/src/main/
│   └── AndroidManifest.xml       # Android 深度链接配置 🔧
├── ios/Runner/
│   └── Info.plist               # iOS 深度链接配置 🔧
├── utils/
│   └── text_menu_utils.dart      # 工具类
└── main.dart                     # 应用入口
```

## API 接口

### 认证相关
- `POST /auth/login` - 用户登录
- `POST /auth/register` - 用户注册
- `POST /auth/forgot-password` - 发送重置密码邮件 🆕
- `POST /auth/reset-password` - 重置密码 🆕

### 文章相关
- `GET /articles` - 获取文章列表
- `POST /articles` - 创建文章
- `PUT /articles/:id` - 更新文章
- `DELETE /articles/:id` - 删除文章

## 开发指南

### 添加新功能
1. 在相应的目录下创建新文件
2. 更新路由配置（如需要）
3. 更新状态管理（如需要）
4. 运行代码分析：`flutter analyze`

### 代码规范
- 使用 Dart 官方代码风格
- 添加适当的注释和文档
- 确保代码通过静态分析

## 许可证

MIT License
