#!/bin/bash

echo "🔧 修复iOS签名问题"
echo "===================="

# 1. 清理构建缓存
echo "1. 清理Flutter和iOS缓存..."
flutter clean
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ios/build
rm -rf ios/.symlinks

# 2. 重新获取依赖
echo "2. 重新获取Flutter依赖..."
flutter pub get

# 3. 重新安装CocoaPods
echo "3. 重新安装CocoaPods..."
cd ios
pod deintegrate
pod install
cd ..

# 4. 打开Xcode以进行手动配置
echo "4. 正在打开Xcode..."
echo ""
echo "📋 请在Xcode中进行以下操作："
echo "   1. 选择Runner target"
echo "   2. 进入 Signing & Capabilities"
echo "   3. 将 Code Signing Style 改为 Automatic"
echo "   4. 选择正确的Team (7ZZD98JY62)"
echo "   5. 确认Bundle Identifier为: com.owensha.poemverse"
echo "   6. 确保设备已添加到开发者账号"
echo ""
echo "⚠️  如果使用的是免费开发者账号，需要："
echo "   - 更改Bundle ID为唯一标识符"
echo "   - 使用Automatic signing"
echo "   - 设备需要信任开发者证书"
echo ""

open ios/Runner.xcworkspace

echo "✅ 脚本执行完成！请按照上述步骤在Xcode中配置签名。"