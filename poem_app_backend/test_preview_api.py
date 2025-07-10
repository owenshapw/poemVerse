#!/usr/bin/env python3
"""
测试预览API的脚本
"""

import requests
import json
import time

def test_preview_api():
    """测试预览API"""
    
    # 等待后端启动
    print("等待后端启动...")
    time.sleep(3)
    
    # 测试健康检查
    try:
        response = requests.get('http://192.168.2.105:5001/health', timeout=5)
        if response.status_code == 200:
            print("✓ 后端健康检查通过")
        else:
            print(f"✗ 后端健康检查失败: {response.status_code}")
            return
    except Exception as e:
        print(f"✗ 无法连接到后端: {e}")
        return
    
    # 测试预览API
    preview_data = {
        'title': '静夜思',
        'content': '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
        'author': '李白',
        'tags': ['思乡', '月亮', '情感']
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer your_test_token_here'  # 这里需要有效的token
    }
    
    try:
        print("\n测试预览API...")
        response = requests.post(
            'http://192.168.2.105:5001/api/generate/preview',
            json=preview_data,
            headers=headers,
            timeout=30
        )
        
        print(f"状态码: {response.status_code}")
        print(f"响应: {response.text}")
        
        if response.status_code == 200:
            result = response.json()
            preview_url = result.get('preview_url')
            if preview_url:
                print(f"✓ 预览图片生成成功: {preview_url}")
                
                # 测试图片访问
                full_url = f"http://192.168.2.105:5001{preview_url}"
                print(f"测试图片访问: {full_url}")
                
                img_response = requests.get(full_url, timeout=10)
                if img_response.status_code == 200:
                    print("✓ 图片访问成功")
                else:
                    print(f"✗ 图片访问失败: {img_response.status_code}")
            else:
                print("✗ 预览图片URL为空")
        else:
            print(f"✗ 预览API调用失败: {response.status_code}")
            
    except Exception as e:
        print(f"✗ 预览API测试失败: {e}")

if __name__ == "__main__":
    test_preview_api() 