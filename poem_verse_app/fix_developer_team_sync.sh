#!/bin/bash

echo "🔧 修复Apple Developer付费团队同步问题"
echo "========================================"
echo "团队ID: 7ZZD98JY62 (付费账号)"
echo ""

echo "1. 清理Xcode开发者数据..."
# 清理Xcode相关缓存
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

echo "2. 清理项目构建缓存..."
flutter clean
rm -rf ios/Pods ios/Podfile.lock ios/build ios/.symlinks

echo "3. 重新获取依赖..."
flutter pub get
cd ios && pod install && cd ..

echo "4. 准备打开Xcode..."
echo ""
echo "🚨 重要步骤 - 请严格按顺序执行："
echo ""
echo "📍 第一步：重新配置Apple ID"
echo "   1. 打开 Xcode → Settings → Accounts"
echo "   2. 选择你的Apple ID，点击减号删除"
echo "   3. 点击加号重新添加Apple ID"
echo "   4. 登录后，点击 'Download Manual Profiles'"
echo "   5. 等待同步完成（可能需要1-2分钟）"
echo ""
echo "📍 第二步：验证团队信息"
echo "   - 应该看到你的付费团队：Owen Sha (7ZZD98JY62)"
echo "   - 如果还是只显示个人团队，请重启Xcode后重试"
echo ""
echo "📍 第三步：配置项目签名"
echo "   1. 选择Runner target"
echo "   2. Signing & Capabilities"
echo "   3. Team选择：Owen Sha (7ZZD98JY62)"
echo "   4. Bundle ID保持：com.owensha.poemverse"
echo ""
echo "📍 第四步：如果团队仍然不出现"
echo "   - 访问 https://developer.apple.com"
echo "   - 确认账号状态正常"
echo "   - 检查App ID是否已创建"
echo ""

echo "正在打开Xcode..."
open ios/Runner.xcworkspace

echo ""
echo "⚠️  如果问题持续存在，可能需要："
echo "   1. 在Apple Developer网站手动创建App ID"
echo "   2. 创建Development配置文件"
echo "   3. 重新下载到Xcode"