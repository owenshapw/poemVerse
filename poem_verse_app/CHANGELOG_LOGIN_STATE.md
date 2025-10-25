# 登录状态持久化功能实现

## 功能需求
APP在非首次打开时，应该根据用户是否登录过决定展示的页面：
- **未曾登录用户**：显示 `LocalPoemsScreen`（本地作品列表）
- **登录过的用户**：显示 `MyArticlesScreen`（个人作品列表）

## 实现方案

### 1. AuthProvider 修改 (`lib/providers/auth_provider.dart`)

#### 新增功能
- 添加 `_isInitialized` 状态标识，表示是否已初始化
- 使用 `SharedPreferences` 持久化保存登录状态

#### 新增方法
```dart
// 初始化 - 从本地存储恢复登录状态
Future<void> init()

// 保存登录状态到本地
Future<void> _saveAuthState()

// 清除保存的登录状态
Future<void> _clearAuthState()
```

#### 修改的方法
- `login()`: 登录成功后调用 `_saveAuthState()` 保存状态
- `register()`: 注册成功后调用 `_saveAuthState()` 保存状态
- `logout()`: 改为异步方法，调用 `_clearAuthState()` 清除状态

#### 存储的数据
- `auth_token`: JWT token
- `auth_user`: 用户信息（JSON 字符串）

### 2. SplashScreen 修改 (`lib/screens/splash_screen.dart`)

#### 修改的逻辑
在 `_navigateToMainScreen()` 方法中：
1. **首先初始化 AuthProvider**，恢复保存的登录状态
2. 然后判断是否首次启动
3. 根据登录状态和首次启动标识决定跳转页面

#### 跳转逻辑
```
应用启动
  ↓
初始化 AuthProvider (恢复登录状态)
  ↓
判断是否首次启动
  ↓
├─ 首次启动 → LocalHomeScreen (欢迎页)
│
└─ 非首次启动
    ├─ 已登录 → MyArticlesScreen (个人作品列表)
    └─ 未登录 → LocalPoemsScreen (本地作品列表)
```

### 3. MyArticlesScreen 修改 (`lib/screens/my_articles_screen.dart`)

#### 修改的逻辑
- 退出登录按钮改为使用 `await authProvider.logout()`，因为 logout 现在是异步方法

## 用户体验流程

### 首次使用
1. 打开APP → 显示启动页（SplashScreen）
2. 标记为非首次启动
3. 跳转到欢迎页（LocalHomeScreen）

### 后续使用（未登录）
1. 打开APP → 显示启动页
2. 检测到非首次启动 + 未登录
3. 跳转到本地作品列表（LocalPoemsScreen）
4. 用户可以创作本地作品，或点击登录

### 登录后
1. 用户在登录页输入账号密码
2. 登录成功 → 保存登录状态到本地
3. 自动同步本地作品到云端
4. 跳转到个人作品列表（MyArticlesScreen）

### 再次打开APP（已登录）
1. 打开APP → 显示启动页
2. 初始化 AuthProvider → 从本地恢复登录状态
3. 检测到非首次启动 + 已登录
4. 直接跳转到个人作品列表（MyArticlesScreen）
5. 用户无需重新登录

### 退出登录
1. 用户在"我的作品"页面点击退出登录
2. 清除本地保存的登录状态
3. 跳转到欢迎页（LocalHomeScreen）

## 技术要点

### 数据持久化
- 使用 `shared_preferences` 包
- 保存 token 和用户信息
- 应用重启后自动恢复

### 安全性
- Token 存储在 SharedPreferences（iOS Keychain / Android SharedPreferences）
- 退出登录时自动清除敏感信息

### 同步机制
- 登录/注册成功后自动同步本地作品
- 支持图片上传到 Cloudflare
- 同步失败不影响登录状态

## 测试建议

1. **首次安装测试**
   - 安装APP → 确认显示欢迎页
   - 再次打开 → 确认显示本地作品列表

2. **登录状态测试**
   - 登录成功 → 关闭APP → 重新打开
   - 确认直接进入个人作品列表，无需重新登录

3. **退出登录测试**
   - 退出登录 → 关闭APP → 重新打开
   - 确认显示本地作品列表，需要重新登录

4. **切换账号测试**
   - 登录账号A → 退出 → 登录账号B
   - 确认显示账号B的作品

## 相关文件

- `lib/providers/auth_provider.dart` - 登录状态管理
- `lib/screens/splash_screen.dart` - 启动页面路由逻辑
- `lib/screens/my_articles_screen.dart` - 个人作品列表
- `lib/screens/local_poems_screen.dart` - 本地作品列表
- `lib/screens/login_screen.dart` - 登录页面
- `lib/screens/register_screen.dart` - 注册页面

## 依赖包

- `shared_preferences: ^2.x.x` - 本地数据持久化存储
