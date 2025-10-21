# "诗"字 Logo 设计说明

## 🎨 设计理念

为 PoemVerse 诗歌APP设计的简洁优雅的"诗"字Logo，适用于启动屏幕。

### 设计特点

1. **色彩方案**
   - 背景：与主页相同的渐变色（`#667eea` → `#764ba2`）
   - Logo：纯白色描边，带有半透明填充
   - 装饰：淡白色圆形背景

2. **视觉效果**
   - 笔画粗细：3.5px，圆角笔触
   - 阴影：柔和的黑色阴影，增加立体感
   - 动画：淡入 + 缩放效果（1.5秒）

3. **字体风格**
   - 采用简化的艺术字体风格
   - 左边"讠"旁：简洁的点横竖结构
   - 右边"寺"字：艺术化处理，保持识别度

## 📱 使用方法

### 当前实现

启动APP时会自动显示Logo启动屏幕2.5秒，然后平滑过渡到主页。

### 文件结构

```
lib/
├── screens/
│   └── splash_screen.dart    # 启动屏幕
└── main.dart                  # 已配置为启动时显示
```

## 🎯 自定义选项

### 1. 调整显示时长

在 `splash_screen.dart` 中修改：

```dart
Timer(const Duration(milliseconds: 2500), () {  // 改这里的数值
  // ...
});
```

### 2. 调整Logo颜色

在 `ShiLogoPainter` 中修改：

```dart
final paint = Paint()
  ..color = Colors.white  // 改成你想要的颜色
  ..strokeWidth = 3.5;
```

### 3. 调整Logo大小

在 `splash_screen.dart` 中修改：

```dart
Container(
  width: 200,   // Logo宽度
  height: 200,  // Logo高度
  // ...
)
```

### 4. 调整动画效果

修改动画控制器：

```dart
_controller = AnimationController(
  duration: const Duration(milliseconds: 1500),  // 动画时长
  vsync: this,
);

// 淡入时间区间
curve: const Interval(0.0, 0.5, curve: Curves.easeIn),

// 缩放时间区间  
curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
```

### 5. 修改APP名称显示

```dart
Text(
  'PoemVerse',  // 改成你的APP名称
  style: TextStyle(
    fontSize: 28,      // 字体大小
    letterSpacing: 4,  // 字母间距
  ),
)
```

## 🎨 Logo变体建议

### 选项A：纯色背景

将渐变背景改为纯色：

```dart
Container(
  color: const Color(0xFF667eea),  // 单一颜色
)
```

### 选项B：添加光晕效果

给Logo添加发光效果：

```dart
Container(
  decoration: BoxDecoration(
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.white.withOpacity(0.5),
        blurRadius: 50,
        spreadRadius: 10,
      ),
    ],
  ),
)
```

### 选项C：使用图片Logo

如果您有设计好的Logo图片：

```dart
Image.asset(
  'assets/images/logo.png',
  width: 200,
  height: 200,
)
```

## 🌟 进阶定制

### 使用SVG Logo

1. 安装依赖：
```yaml
dependencies:
  flutter_svg: ^2.0.9
```

2. 替换CustomPaint为SVG：
```dart
SvgPicture.asset(
  'assets/logo/shi_logo.svg',
  width: 200,
  height: 200,
  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
)
```

### 添加加载进度

在Logo下方添加进度条：

```dart
Column(
  children: [
    // ... Logo代码 ...
    const SizedBox(height: 40),
    SizedBox(
      width: 150,
      child: LinearProgressIndicator(
        backgroundColor: Colors.white.withOpacity(0.2),
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    ),
  ],
)
```

## 📐 Logo笔画坐标说明

当前"诗"字的绘制坐标（基于200x200画布，中心为原点）：

### 左边"讠"旁
- 点：(-60, -50) → (-55, -40)
- 横1：(-60, -20) → (-40, -20)
- 横2：(-60, 0) → (-40, 0)
- 横3：(-60, 20) → (-40, 20)
- 竖：(-50, -30) → (-50, 40)

### 右边"寺"字
- 上横：(-20, -45) → (60, -45)
- 上竖：(20, -55) → (20, -25)
- 中横：(-10, -25) → (50, -25)
- 主竖钩：(20, -25) → (20, 55) → 钩(15, 60)
- 左点：(-5, 10) → (0, 18)
- 右点：(40, 10) → (45, 18)

修改这些坐标可以调整字形。

## 🚀 性能优化

1. **使用shouldRepaint = false**：避免不必要的重绘
2. **预加载资源**：如使用图片，建议预加载
3. **简化动画**：复杂动画可能影响低端设备

## 💡 设计建议

- Logo应保持足够的识别度
- 在不同屏幕尺寸上测试效果
- 考虑深色/浅色模式适配
- 保持与APP整体风格一致

---

设计时间：2024
适用版本：Flutter 3.x+
