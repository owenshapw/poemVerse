#!/usr/bin/env python3
"""
图片URL测试脚本
验证不同平台的图片URL构建
"""

import requests
import json

# 测试不同的URL构建方式
def test_image_urls():
    """测试不同的图片URL构建方式"""
    print("=== 图片URL测试 ===\n")
    
    # 测试图片路径
    image_path = "/uploads/article_a2277770-7031-448d-81b7-bfbf9a2c0e13.png"
    
    # 不同的基础URL
    urls_to_test = [
        "http://localhost:5001",
        "http://127.0.0.1:5001", 
        "http://10.0.2.2:5001",  # Android模拟器
        "http://192.168.1.100:5001",  # 可能的局域网IP
    ]
    
    for base_url in urls_to_test:
        full_url = f"{base_url}{image_path}"
        print(f"测试URL: {full_url}")
        
        try:
            response = requests.head(full_url, timeout=5)
            if response.status_code == 200:
                print(f"  ✅ 成功 - 状态码: {response.status_code}")
                print(f"  Content-Type: {response.headers.get('Content-Type')}")
                print(f"  Content-Length: {response.headers.get('Content-Length')}")
            else:
                print(f"  ❌ 失败 - 状态码: {response.status_code}")
        except requests.exceptions.RequestException as e:
            print(f"  ❌ 连接失败: {e}")
        
        print()

def test_backend_image_endpoint():
    """测试后端图片端点"""
    print("=== 后端图片端点测试 ===\n")
    
    # 测试健康检查
    try:
        response = requests.get("http://localhost:5001/health")
        print(f"健康检查: {response.status_code}")
        if response.status_code == 200:
            print("✅ 后端服务正常")
        else:
            print("❌ 后端服务异常")
    except Exception as e:
        print(f"❌ 健康检查失败: {e}")
    
    print()
    
    # 测试图片端点
    try:
        response = requests.get("http://localhost:5001/uploads/")
        print(f"图片目录访问: {response.status_code}")
        if response.status_code == 200:
            print("✅ 图片目录可访问")
        else:
            print("❌ 图片目录不可访问")
    except Exception as e:
        print(f"❌ 图片目录访问失败: {e}")

def test_specific_image():
    """测试特定图片"""
    print("\n=== 特定图片测试 ===\n")
    
    image_path = "/uploads/article_a2277770-7031-448d-81b7-bfbf9a2c0e13.png"
    url = f"http://localhost:5001{image_path}"
    
    print(f"测试图片: {url}")
    
    try:
        response = requests.get(url, timeout=10)
        if response.status_code == 200:
            print("✅ 图片访问成功")
            print(f"文件大小: {len(response.content)} 字节")
            print(f"Content-Type: {response.headers.get('Content-Type')}")
            
            # 检查是否为有效的PNG文件
            if response.content.startswith(b'\x89PNG'):
                print("✅ 有效的PNG文件")
            else:
                print("❌ 不是有效的PNG文件")
        else:
            print(f"❌ 图片访问失败: {response.status_code}")
    except Exception as e:
        print(f"❌ 图片访问异常: {e}")

def main():
    """主测试函数"""
    print("开始图片URL测试...\n")
    
    # 测试后端图片端点
    test_backend_image_endpoint()
    
    # 测试不同的URL构建方式
    test_image_urls()
    
    # 测试特定图片
    test_specific_image()
    
    print("\n=== 测试完成 ===")
    print("\nFlutter应用中的图片URL构建建议:")
    print("1. iOS模拟器: http://localhost:5001")
    print("2. Android模拟器: http://10.0.2.2:5001")
    print("3. 真机: 使用实际的IP地址")
    print("4. 确保后端CORS设置允许跨域访问")

if __name__ == "__main__":
    main() 