#!/usr/bin/env python3
"""
测试预览图片生成API
"""

import requests
import json

BASE_URL = "http://localhost:5001/api"

def test_preview_generation():
    """测试预览图片生成"""
    print("=== 预览图片生成API测试 ===\n")
    
    # 1. 登录获取token
    login_data = {
        "email": "owensha@gmail.com",
        "password": "123456"
    }
    
    print("1. 登录获取token...")
    response = requests.post(f"{BASE_URL}/login", json=login_data)
    
    if response.status_code != 200:
        print(f"❌ 登录失败: {response.status_code}")
        return None
    
    token = response.json()['token']
    print(f"✅ 登录成功，获取token")
    
    # 2. 测试预览图片生成
    preview_data = {
        "title": "测试预览标题",
        "content": "这是第一行测试内容\n这是第二行测试内容\n这是第三行测试内容",
        "tags": ["测试", "预览", "示例"],
        "author": "测试作者"
    }
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    print("\n2. 生成预览图片...")
    print(f"标题: {preview_data['title']}")
    print(f"内容: {preview_data['content']}")
    print(f"作者: {preview_data['author']}")
    print(f"标签: {preview_data['tags']}")
    
    response = requests.post(f"{BASE_URL}/generate/preview", json=preview_data, headers=headers)
    
    print(f"\n状态码: {response.status_code}")
    print(f"响应头: {dict(response.headers)}")
    
    if response.status_code == 200:
        data = response.json()
        print("✅ 预览图片生成成功!")
        print(f"预览URL: {data.get('preview_url')}")
        print(f"消息: {data.get('message')}")
        
        # 3. 测试访问生成的图片
        if data.get('preview_url'):
            image_url = f"http://localhost:5001{data['preview_url']}"
            print(f"\n3. 测试访问图片: {image_url}")
            
            img_response = requests.head(image_url)
            print(f"图片访问状态码: {img_response.status_code}")
            
            if img_response.status_code == 200:
                print("✅ 图片可以正常访问")
                print(f"Content-Type: {img_response.headers.get('Content-Type')}")
                print(f"Content-Length: {img_response.headers.get('Content-Length')}")
            else:
                print("❌ 图片访问失败")
        
        return data.get('preview_url')
    else:
        print(f"❌ 预览图片生成失败")
        print(f"错误信息: {response.text}")
        return None

if __name__ == "__main__":
    preview_url = test_preview_generation()
    
    if preview_url:
        print(f"\n=== 测试完成 ===")
        print(f"预览图片URL: {preview_url}")
        print(f"完整访问地址: http://localhost:5001{preview_url}")
    else:
        print(f"\n=== 测试失败 ===") 