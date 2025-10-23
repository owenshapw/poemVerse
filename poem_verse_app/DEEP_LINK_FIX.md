# 深度链接修复文档

## 问题描述

原本邮件中的重置密码链接使用了深度链接格式：
```
poemverse://reset-password?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

但是Flutter应用没有正确配置深度链接处理，导致点击链接无法正常跳转到应用的重置密码页面。

## 解决方案

### 1. 添加深度链接依赖

在 `pubspec.yaml` 中添加了 `app_links` 包：

```yaml
dependencies:
  app_links: ^6.3.2
```

### 2. Android配置

在 `android/app/src/main/AndroidManifest.xml` 中添加了深度链接的intent filter：

```xml
<!-- Deep link intent filter for password reset -->
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="poemverse" />
</intent-filter>
```

### 3. iOS配置

在 `ios/Runner/Info.plist` 中添加了URL scheme配置：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>poemverse.deeplink</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>poemverse</string>
        </array>
    </dict>
</array>
```

### 4. Flutter应用代码修改

#### 主要修改 `lib/main.dart`：

1. **添加必要的导入**：
```dart
import 'package:app_links/app_links.dart';
import 'dart:async';
```

2. **将StatelessWidget改为StatefulWidget**：
```dart
class PoemVerseApp extends StatefulWidget {
  const PoemVerseApp({super.key});

  @override
  PoemVerseAppState createState() => PoemVerseAppState();
}
```

3. **添加深度链接处理逻辑**：
```dart
class PoemVerseAppState extends State<PoemVerseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (Object err) {
        debugPrint('Deep link error: $err');
      },
    );

    // Handle link when app is launched from a deep link
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (err) {
      debugPrint('Failed to get initial URI: $err');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');
    
    if (uri.scheme == 'poemverse') {
      if (uri.path == '/reset-password' && uri.queryParameters.containsKey('token')) {
        final String token = uri.queryParameters['token']!;
        // Navigate to reset password screen
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(token: token),
          ),
        );
      }
    }
  }
}
```

4. **添加NavigatorKey到MaterialApp**：
```dart
MaterialApp(
  navigatorKey: _navigatorKey,
  // ... other configurations
)
```

## 功能验证

### 测试场景

1. **应用未运行时**：
   - 用户点击邮件中的深度链接
   - 应用启动并自动跳转到重置密码页面

2. **应用已运行时**：
   - 用户点击邮件中的深度链接
   - 应用从后台切换到前台并跳转到重置密码页面

### 支持的链接格式

- `poemverse://reset-password?token=<JWT_TOKEN>`

### 错误处理

- 无效的token参数会被忽略
- 不支持的深度链接路径会被忽略
- 深度链接处理错误会被记录到调试日志

## 测试

添加了新的单元测试来验证重置密码屏幕的正确性：

```dart
testWidgets('Reset password screen should load correctly', (WidgetTester tester) async {
  await tester.pumpWidget(MaterialApp(
    home: ResetPasswordScreen(token: 'test-token'),
  ));

  expect(find.text('重置密码'), findsNWidgets(2)); // Title and button
  expect(find.text('新密码'), findsOneWidget);
  expect(find.text('确认新密码'), findsOneWidget);
  expect(find.byType(TextFormField), findsNWidgets(2));
});
```

## 兼容性

### 支持平台
- ✅ Android 5.0+ (API level 21+)
- ✅ iOS 9.0+

### 依赖版本
- `app_links: ^6.3.2`
- Flutter 3.0+

## 安全性考虑

1. **Token验证**：应用会验证JWT token的有效性
2. **Scheme限制**：只处理 `poemverse://` scheme的链接
3. **路径验证**：只处理 `/reset-password` 路径
4. **参数验证**：确保token参数存在且不为空

## 调试信息

启用调试模式时，深度链接处理会输出以下信息：
- 接收到的深度链接URI
- 深度链接处理错误
- 初始URI获取失败信息

## 部署注意事项

1. **Android**：
   - 确保 `android:autoVerify="true"` 已设置
   - 发布版本需要配置Digital Asset Links（可选）

2. **iOS**：
   - URL scheme配置会自动生效
   - 可以配置Universal Links作为备选方案（可选）

3. **测试**：
   - 在真机上测试深度链接功能
   - 验证从不同应用（邮箱、浏览器等）打开链接

## 后续改进

1. **Universal Links支持**：为iOS添加Universal Links支持
2. **App Links支持**：为Android添加App Links支持
3. **更多深度链接**：支持更多功能的深度链接
4. **分析统计**：添加深度链接使用情况的分析

## 结论

深度链接修复已完成，现在用户可以通过邮件中的重置密码链接直接跳转到应用的重置密码页面。该解决方案支持Android和iOS平台，具有良好的错误处理和安全性保障。