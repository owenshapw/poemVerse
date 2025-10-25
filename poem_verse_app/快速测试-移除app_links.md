# 快速测试：移除 app_links 包

## 🎯 假设

`app_links` 包可能是触发本地网络权限的罪魁祸首。

**理由**：
- app_links 用于监听深链接（Universal Links）
- Universal Links 需要与服务器通信验证
- 可能在某个时刻触发了本地网络检测

## 🧪 快速测试步骤

### 1. 临时移除 app_links

编辑 `pubspec.yaml`，注释掉 app_links：

```yaml
dependencies:
  # app_links: ^6.1.4  # 🔴 临时注释，测试是否是它触发的权限
```

### 2. 注释相关代码

编辑 `lib/main.dart`，注释掉所有 app_links 相关代码：

```dart
// import 'package:app_links/app_links.dart';  // 🔴 注释

class PoemVerseAppState extends State<PoemVerseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  // late AppLinks _appLinks;  // 🔴 注释
  // StreamSubscription<Uri>? _linkSubscription;  // 🔴 注释

  @override
  void initState() {
    super.initState();
    // 🔴 已经注释了 _initDeepLinks()
  }

  @override
  void dispose() {
    // _linkSubscription?.cancel();  // 🔴 注释
    super.dispose();
  }

  // 🔴 注释整个方法
  /*
  void _initDeepLinks() async {
    // ...
  }
  */

  // 🔴 注释整个方法
  /*
  void _handleDeepLink(Uri uri) {
    // ...
  }
  */

  // 🔴 注释整个方法
  /*
  void _navigateToResetPassword(String token) {
    // ...
  }
  */
```

### 3. 清除并重新测试

```bash
cd poem_verse_app

# 完全清除
flutter clean
rm -rf build/

# 更新依赖
flutter pub get

# 卸载应用
# 在设备上手动卸载，或：
xcrun simctl uninstall booted com.owensha.poemverse

# 重新安装
flutter run

# 🔍 观察：权限弹窗是否还出现？
```

## 📊 测试结果

### 如果权限弹窗消失了 ✅

**结论**：`app_links` 包触发了本地网络权限

**解决方案**：
1. 保持移除状态（如果不需要深链接功能）
2. 或者找替代方案
3. 或者延迟初始化到用户登录后

### 如果权限弹窗还在 ❌

**结论**：不是 app_links 触发的

**下一步**：
1. 恢复 app_links
2. 继续排查其他包（见下方）

## 🔄 恢复 app_links

如果测试后发现不是 app_links 触发的，恢复代码：

```bash
# 取消 git 中的修改
git checkout pubspec.yaml
git checkout lib/main.dart

# 或手动取消注释
```

## 📦 其他可疑包

如果不是 app_links，按顺序测试这些包：

### 优先级排序

1. **dio** - HTTP 客户端
2. **flutter_cache_manager** - 缓存管理
3. **cached_network_image** - 图片缓存
4. **share_plus** - 分享功能
5. **image_picker** - 图片选择

### 测试方法

```yaml
# 逐个注释，每次测试
dependencies:
  # dio: ^5.4.3+1  # 测试
```

## ⏱️ 预计时间

- 每次测试：5-10分钟
- 5个包测试完：30-50分钟

## 💡 提示

### 加快测试

使用 hot restart 而不是完全重装：

```bash
# 第一次完全安装
flutter run

# 之后修改代码后：
# 按 R (hot restart)
```

但**首次测试必须完全卸载重装**，确保权限状态清除。

## 📝 记录结果

| 包名 | 是否移除 | 权限弹窗 | 结论 |
|------|---------|---------|------|
| app_links | ✅ | ❌ 还出现 | 不是它 |
| dio | ✅ | ❌ 还出现 | 不是它 |
| flutter_cache_manager | ✅ | ❌ 还出现 | 不是它 |
| ... | | | |

---

**现在请先测试 app_links，这是最可疑的包！** 🎯
