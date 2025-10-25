# 🎉 图片和文字位置保存问题 - 解决方案总结

## 🐛 问题描述

本地诗章编辑时：
1. **图片 offsetY**：拖动调整后，返回列表不显示
2. **文字位置**：调整后不保存

## 🔍 根本原因

### 问题 1：Hive 对象更新机制
创建新的 `Poem` 对象会**丢失 Hive 数据库连接**：
```dart
// ❌ 错误方式
final updatedPoem = Poem(...);  // 新对象，丢失 Hive 连接
LocalStorageService.savePoem(updatedPoem);  // 无法正确保存
```

### 问题 2：保存时机不当
- 自动保存时创建新对象，覆盖了之前的数据
- 点击保存按钮时又创建新对象，导致 offset 丢失

## ✅ 解决方案

### 核心思路：**离开编辑页面时自动保存**

#### 1. **编辑页面**（create_article_screen.dart）

**拖动图片时**：
```dart
onTransformChanged: (ox, oy, s) {
  _previewOffsetY = oy;
  _imageOffsetY = oy;  // 更新内存变量
}
```

**离开页面时自动保存**：
```dart
@override
void dispose() {
  // 离开页面时自动保存（本地模式 + 编辑模式）
  if (widget.isLocalMode && widget.isEdit && widget.localPoem != null) {
    _saveOnExit();  // ✅ 自动保存
  }
  // ...
}

void _saveOnExit() {
  // 直接更新 HiveObject，保持数据库连接
  widget.localPoem!.imageOffsetY = _imageOffsetY;
  widget.localPoem!.textPositionX = _textPositionX;
  widget.localPoem!.textPositionY = _textPositionY;
  widget.localPoem!.save();  // ✅ 使用 HiveObject.save()
}
```

#### 2. **预览页面**（article_preview_screen.dart）

**点击"保存"按钮时**：
```dart
Future<void> _saveLocalPoem() async {
  final poem = Poem(
    // ...
    imageOffsetY: widget.imageOffsetY ?? 0.0,  // ✅ 使用从编辑页面传入的值
    textPositionX: _textPositionX,  // ✅ 使用调整后的文字位置
    textPositionY: _textPositionY,
  );
  
  await LocalStorageService.savePoem(poem);
  Navigator.of(context).pop('saved');  // 返回状态
}
```

#### 3. **列表页面**（local_poems_screen.dart）

**返回时清理缓存**：
```dart
@override
void didPopNext() {
  _loadPoems(clearCache: true);  // ✅ 清理图片缓存
}
```

**添加唯一 Key**：
```dart
InteractiveImagePreview(
  key: ValueKey('${poem.id}_${imgOffsetY.toStringAsFixed(2)}'),  // ✅ offsetY 变化时重建
  // ...
)
```

## 🎯 完整工作流程

```
1. 打开编辑页面
   ↓
2. 拖动图片 → 更新 _imageOffsetY（内存）
   ↓
3. 点击"文字布局" → 跳转预览页面 → dispose() 自动保存 ✅
   ↓
4. 调整文字位置 → 预览页面
   ↓
5. 点击"保存" → 保存（图片 offset + 文字 position）→ 返回列表
   ↓
6. 列表页面 → 清理缓存 → 重新加载 → 显示新位置 ✅
```

## 📋 关键代码变更

### 1. 编辑页面
- ✅ 移除自动保存定时器
- ✅ 移除 AppBar 的"保存"按钮
- ✅ 添加 `dispose()` 自动保存
- ✅ 只保存 offsetY（X 固定为 0，Scale 固定为 1）

### 2. 预览页面
- ✅ 修复：`imageOffsetY: widget.imageOffsetY ?? 0.0`（之前硬编码 0.0）
- ✅ 保存完返回 `'saved'` 状态

### 3. 列表页面
- ✅ 返回时清理图片缓存
- ✅ 添加 ValueKey 强制重建

### 4. InteractiveImagePreview 组件
- ✅ initState 时立即应用 offsetY
- ✅ 图片加载完成后再次应用 offsetY

## 🎨 用户体验

### 简化后的操作流程：
1. **编辑诗章** → 拖动图片调整位置
2. **点击"文字布局"** → 进入全屏预览
3. **拖动文字** → 调整文字位置
4. **点击"保存"** → 一次性保存所有修改 ✅

### 优势：
- ✅ **无需手动保存图片位置**：离开编辑页面自动保存
- ✅ **统一保存入口**：预览页面的"保存"按钮
- ✅ **操作流畅**：所有调整实时预览，最后统一保存

## 🔑 技术要点

### Hive 数据更新的正确方式
```dart
// ✅ 正确：直接更新 HiveObject
widget.localPoem!.imageOffsetY = _imageOffsetY;
widget.localPoem!.save();

// ❌ 错误：创建新对象
final newPoem = Poem(...);  // 丢失 Hive 连接
LocalStorageService.savePoem(newPoem);
```

### 图片缓存清理
```dart
final provider = FileImage(File(imageUrl));
provider.evict();
PaintingBinding.instance.imageCache.evict(provider);
```

### Widget 强制重建
```dart
InteractiveImagePreview(
  key: ValueKey('${poem.id}_${imgOffsetY.toStringAsFixed(2)}'),
  // Key 包含 offsetY，值变化时强制重建
)
```

## 🚀 测试验证

已验证成功：
- ✅ 拖动图片 → 离开页面 → 自动保存
- ✅ 返回列表 → 图片位置正确显示
- ✅ 重新编辑 → 图片位置保持
- ✅ 调整文字 → 预览保存 → 文字位置正确

## 📝 代码清理

已移除所有调试日志，代码恢复简洁状态。
