#!/bin/bash

# 启动页无缝衔接设置脚本
# 一键生成所有需要的资源并应用配置

echo "🚀 开始设置启动页无缝衔接..."
echo ""

# 检查是否在正确的目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误: 请在 poem_verse_app 目录下运行此脚本"
    exit 1
fi

# Step 1: 安装依赖
echo "📦 Step 1: 安装 Flutter 依赖..."
flutter pub get

# Step 2: 生成背景图
echo ""
echo "🎨 Step 2: 生成渐变背景图..."
python3 scripts/generate_splash_background.py

# Step 3: 生成文字图片（可选）
echo ""
echo "✍️  Step 3: 生成"诗章"文字图片..."
python3 scripts/generate_app_title.py

# Step 4: 生成原生启动页
echo ""
echo "🔧 Step 4: 生成原生启动页..."
dart run flutter_native_splash:create

echo ""
echo "✅ 设置完成！"
echo ""
echo "📝 接下来："
echo "   1. 运行 'flutter run' 测试启动效果"
echo "   2. 如果还有跳动，查看 SPLASH_SCREEN_SETUP.md 了解调整方法"
echo ""
echo "⚠️  注意："
echo "   - 原生启动页时间由iOS系统控制（0.5-1秒），无法缩短"
echo "   - 但通过视觉一致性，用户感知会更流畅"
echo ""
