#!/usr/bin/env python3
"""
模拟Flutter图片URL构建逻辑的测试脚本
"""

import requests
import json

def test_flutter_image_urls():
    """测试Flutter应用中的图片URL构建逻辑"""
    print("=== Flutter图片URL构建测试 ===\n")
    
    # 模拟Flutter的AppConfig.buildImageUrl逻辑
    def build_image_url(image_path, platform="ios"):
        if not image_path:
            return ""
        
        # 如果已经是完整URL，直接返回
        if image_path.startswith('http://') or image_path.startswith('https://'):
            return image_path
        
        # 根据平台构建基础URL
        if platform == "ios":
            base_url = "http://192.168.2.105:5001"  # iOS真机使用本机IP
        elif platform == "android":
            base_url = "http://10.0.2.2:5001"  # Android模拟器
        else:
            base_url = "http://localhost:5001"  # 其他平台
        
        return f"{base_url}{image_path}"
    
    # 测试图片路径
    image_path = "/uploads/article_a2277770-7031-448d-81b7-bfbf9a2c0e13.png"
    
    # 测试不同平台的URL构建
    platforms = [
        ("iOS真机", "ios"),
        ("Android模拟器", "android"),
        ("其他平台", "other")
    ]
    
    for platform_name, platform in platforms:
        url = build_image_url(image_path, platform)
        print(f"{platform_name}:")
        print(f"  构建的URL: {url}")
        
        # 测试URL是否可访问
        try:
            response = requests.head(url, timeout=5)
            if response.status_code == 200:
                print(f"  ✅ 可访问 - 状态码: {response.status_code}")
                print(f"  Content-Type: {response.headers.get('Content-Type')}")
            else:
                print(f"  ❌ 不可访问 - 状态码: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"  ❌ 连接失败: {e}")
        
        print()
    
    # 测试不同的图片路径
    print("=== 测试不同图片路径 ===\n")
    test_paths = [
        "/uploads/test1.png",
        "/uploads/test2.jpg",
        "http://example.com/image.png",
        "https://example.com/image.jpg",
        "",
        None
    ]
    
    for path in test_paths:
        url = build_image_url(path, "ios")
        print(f"路径: '{path}' -> URL: '{url}'")
    
    print("\n=== 测试完成 ===")
    print("\n建议:")
    print("1. iOS真机使用本机IP地址: 192.168.2.105")
    print("2. Android模拟器使用: 10.0.2.2")
    print("3. 确保后端服务在正确的IP地址上运行")
    print("4. 检查网络连接和防火墙设置")

def test_network_connectivity():
    """测试网络连接性"""
    print("\n=== 网络连接性测试 ===\n")
    
    # 测试不同的IP地址
    test_urls = [
        "http://localhost:5001/health",
        "http://127.0.0.1:5001/health",
        "http://192.168.2.105:5001/health",
        "http://10.0.2.2:5001/health",
    ]
    
    for url in test_urls:
        print(f"测试: {url}")
        try:
            response = requests.get(url, timeout=5)
            if response.status_code == 200:
                print(f"  ✅ 连接成功")
            else:
                print(f"  ❌ 连接失败 - 状态码: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"  ❌ 连接失败: {e}")
        print()

def main():
    """主测试函数"""
    print("开始Flutter图片URL测试...\n")
    
    # 测试网络连接性
    test_network_connectivity()
    
    # 测试Flutter图片URL构建
    test_flutter_image_urls()

if __name__ == "__main__":
    main() 