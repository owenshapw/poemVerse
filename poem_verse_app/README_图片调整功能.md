# 图片预览滑动调整功能实现

## 功能概述

实现了在创建/编辑诗篇页面的图片预览区域允许用户通过手势调整图片显示部分，并且在所有相关页面以相同方式显示调整后的图片。

## 核心特性

### 🎯 交互式图片调整
- **双指缩放**：支持 0.5x - 3.0x 范围内的缩放
- **单指移动**：可以平移图片来选择显示区域
- **实时预览**：调整过程中实时看到效果
- **重置功能**：一键恢复图片原始状态

### 🔧 技术实现
- **InteractiveImagePreview** 组件：可交互的图片预览组件
- **TransformedImage** 组件：应用已保存变换的静态显示组件
- **数据模型扩展**：Article 模型新增图片变换参数
- **API 集成**：创建和更新文章时保存图片变换信息

## 文件修改列表

### 新增文件
- `lib/widgets/interactive_image_preview.dart` - 交互式图片预览组件

### 修改的文件

#### 数据模型
- `lib/models/article.dart`
  - 新增 `imageOffsetX`, `imageOffsetY`, `imageScale` 字段

#### API 层
- `lib/api/api_service.dart`
  - 更新 `createArticle` 方法支持图片变换参数

#### Provider 层
- `lib/providers/article_provider.dart`
  - 更新 `createArticle` 和 `updateArticle` 方法

#### 界面层
- `lib/screens/create_article_screen.dart`
  - 集成交互式图片预览
  - 添加图片变换参数管理
  - 新增重置图片按钮
  - 添加使用说明和帮助

- `lib/screens/my_articles_screen.dart`
  - 应用图片变换显示

- `lib/screens/author_works_screen.dart`
  - 应用图片变换显示

- `lib/screens/home_screen.dart`
  - 应用图片变换显示

## 用户体验提升

### 📱 创建/编辑页面
1. **直观操作**：用户可以直接在图片上进行缩放和移动操作
2. **操作指导**：显示操作提示"双指缩放、单指移动"
3. **帮助文档**：点击提示可查看详细使用说明
4. **一键重置**：提供"重置图片"按钮快速恢复原状态
5. **三合一按钮布局**："调整文字" | "重置图片" | "重新上传"

### 🎨 显示页面
- **一致性显示**：所有页面（首页、我的文章、作者作品）都按照用户调整的效果显示图片
- **保持变换**：图片的缩放和位置调整会在发布后保持不变

## 技术细节

### 图片变换参数
```dart
// 新增的 Article 字段
final double? imageOffsetX;  // X 轴偏移
final double? imageOffsetY;  // Y 轴偏移  
final double? imageScale;    // 缩放比例
```

### API 参数扩展
```dart
// createArticle 方法新增参数
{
  double? imageOffsetX,
  double? imageOffsetY, 
  double? imageScale
}
```

### 组件使用示例
```dart
// 交互式预览（创建/编辑页面）
InteractiveImagePreview(
  imageUrl: imageUrl,
  width: double.infinity,
  height: 180.0,
  initialOffsetX: _imageOffsetX,
  initialOffsetY: _imageOffsetY,
  initialScale: _imageScale,
  onTransformChanged: (offsetX, offsetY, scale) {
    // 保存变换参数
  },
)

// 静态显示（其他页面）
TransformedImage(
  imageUrl: imageUrl,
  width: double.infinity,
  height: 200,
  offsetX: article.imageOffsetX ?? 0.0,
  offsetY: article.imageOffsetY ?? 0.0,
  scale: article.imageScale ?? 1.0,
)
```

## 兼容性说明

- **向后兼容**：现有文章没有图片变换参数时使用默认值（偏移0，缩放1.0）
- **渐进式增强**：用户可以选择是否调整图片，不调整时保持原有行为
- **性能优化**：仅在需要时应用变换，避免不必要的计算

## 使用说明

### 对于用户
1. 上传图片后，可以在预览区域进行调整
2. 使用双指进行缩放，单指进行移动
3. 点击"重置图片"可以恢复原始状态
4. 点击操作提示旁的帮助图标查看详细说明
5. 调整好的效果会在发布后保持

### 对于开发者
1. 确保后端 API 支持新增的图片变换参数
2. 数据库需要对应的字段来存储变换信息
3. 所有显示图片的地方都需要应用 `TransformedImage` 组件

## 未来扩展

- **预设模板**：提供常用的图片裁剪模板
- **更多手势**：支持双击重置、长按菜单等
- **动画效果**：添加变换过程的动画效果
- **批量应用**：支持将调整效果应用到多张图片