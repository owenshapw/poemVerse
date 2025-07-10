#!/usr/bin/env python3
"""
测试新的IP地址
"""

import requests

def test_new_ip():
    """测试新的IP地址"""
    print("=== 测试新的IP地址 ===")
    
    # 测试新的IP地址
    new_ip = "192.168.14.18"
    image_path = "/uploads/ai_generated_0075528896df49e6afc6352a5a13da3d.png"
    
    flutter_image_url = f"http://{new_ip}:5001{image_path}"
    print(f"新的Flutter图片URL: {flutter_image_url}")
    
    try:
        response = requests.get(flutter_image_url, timeout=10)
        if response.status_code == 200:
            print(f"✅ 新IP地址访问成功，大小: {len(response.content)} 字节")
            return True
        else:
            print(f"❌ 新IP地址访问失败: {response.status_code}")
            return False
    except Exception as e:
        print(f"❌ 新IP地址访问异常: {e}")
        return False

def test_backend_health():
    """测试后端健康状态"""
    print("\n=== 测试后端健康状态 ===")
    
    urls = [
        "http://127.0.0.1:5001/health",
        "http://192.168.14.18:5001/health",
        "http://0.0.0.0:5001/health"
    ]
    
    for url in urls:
        try:
            response = requests.get(url, timeout=5)
            print(f"{url}: {response.status_code}")
        except Exception as e:
            print(f"{url}: 连接失败 - {e}")

if __name__ == "__main__":
    print("=== IP地址测试 ===\n")
    
    test_backend_health()
    test_new_ip()
    
    print("\n=== 测试完成 ===") 