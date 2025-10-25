# 实用脚本工具

这个目录包含用于生成应用资源的 Python 实用脚本。

## 📋 依赖安装

在运行脚本之前，请先安装 Python 依赖：

```bash
cd scripts
pip install -r requirements.txt
```

或者使用虚拟环境：

```bash
cd scripts
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

## 🛠️ 可用脚本

### `create_splash_image.py`

创建完整的启动屏图片，包含渐变背景、Logo 和"诗章"文字。

**用法：**
```bash
python3 create_splash_image.py
```

**输出：**
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` (1x)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` (2x)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` (3x)

### `create_launch_logo.py`

创建带圆角白色边框的启动 Logo。

**用法：**
```bash
python3 create_launch_logo.py
```

**输出：**
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` (1x)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` (2x)
- `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` (3x)

## 📝 注意事项

- 确保 `assets/images/poemlogo.png` 存在
- 脚本会自动创建输出目录
- 生成的图片会覆盖现有文件
