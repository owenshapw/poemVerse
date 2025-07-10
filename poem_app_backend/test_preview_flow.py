#!/usr/bin/env python3
"""
测试预览流程的完整脚本
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

import requests
import json
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def test_login():
    """测试登录获取token"""
    print("=== 测试登录 ===")
    
    login_data = {
        'email': 'owensha@gmail.com',
        'password': 'D1ffs2P3'
    }
    
    try:
        response = requests.post(
            'http://127.0.0.1:5001/api/login',
            headers={'Content-Type': 'application/json'},
            json=login_data
        )
        
        print(f"登录响应状态: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            token = data.get('token')
            print(f"✅ 登录成功，获取到token: {token[:20]}...")
            return token
        else:
            print(f"❌ 登录失败: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ 登录异常: {e}")
        return None

def test_preview_generation(token):
    """测试预览生成"""
    print("\n=== 测试预览生成 ===")
    
    preview_data = {
        'title': '静夜思',
        'content': '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
        'author': '李白',
        'tags': ['思乡', '月亮', '情感']
    }
    
    headers = {
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {token}'
    }
    
    try:
        print("发送预览生成请求...")
        response = requests.post(
            'http://127.0.0.1:5001/api/generate/preview',
            headers=headers,
            json=preview_data,
            timeout=120
        )
        
        print(f"预览生成响应状态: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            preview_url = data.get('preview_url')
            print(f"✅ 预览生成成功！")
            print(f"预览URL: {preview_url}")
            
            # 测试图片URL是否可访问
            if preview_url:
                image_url = f"http://127.0.0.1:5001{preview_url}"
                print(f"完整图片URL: {image_url}")
                
                # 检查文件是否存在
                filepath = os.path.join('uploads', os.path.basename(preview_url))
                if os.path.exists(filepath):
                    file_size = os.path.getsize(filepath)
                    print(f"✅ 图片文件存在: {filepath}")
                    print(f"文件大小: {file_size} 字节")
                    
                    # 测试HTTP访问
                    try:
                        img_response = requests.get(image_url, timeout=10)
                        if img_response.status_code == 200:
                            print(f"✅ 图片HTTP访问成功，大小: {len(img_response.content)} 字节")
                        else:
                            print(f"❌ 图片HTTP访问失败: {img_response.status_code}")
                    except Exception as e:
                        print(f"❌ 图片HTTP访问异常: {e}")
                else:
                    print(f"❌ 图片文件不存在: {filepath}")
            
            return preview_url
        else:
            print(f"❌ 预览生成失败: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ 预览生成异常: {e}")
        return None

def test_image_accessibility():
    """测试图片可访问性"""
    print("\n=== 测试图片可访问性 ===")
    
    # 检查uploads目录中的图片
    uploads_dir = 'uploads'
    if os.path.exists(uploads_dir):
        files = [f for f in os.listdir(uploads_dir) if f.endswith('.png')]
        print(f"uploads目录中有 {len(files)} 个PNG文件")
        
        for file in files[:3]:  # 只测试前3个文件
            filepath = os.path.join(uploads_dir, file)
            file_size = os.path.getsize(filepath)
            image_url = f"http://127.0.0.1:5001/uploads/{file}"
            
            print(f"\n测试文件: {file}")
            print(f"文件大小: {file_size} 字节")
            print(f"访问URL: {image_url}")
            
            try:
                response = requests.get(image_url, timeout=10)
                if response.status_code == 200:
                    print(f"✅ HTTP访问成功，响应大小: {len(response.content)} 字节")
                else:
                    print(f"❌ HTTP访问失败: {response.status_code}")
            except Exception as e:
                print(f"❌ HTTP访问异常: {e}")
    else:
        print("❌ uploads目录不存在")

def test_flutter_image_url():
    """测试Flutter应用会使用的图片URL格式"""
    print("\n=== 测试Flutter图片URL格式 ===")
    
    # 模拟Flutter应用的URL构建
    backend_base_url = "http://192.168.2.105:5001"  # iOS真机使用的IP
    image_path = "/uploads/ai_generated_0075528896df49e6afc6352a5a13da3d.png"
    
    flutter_image_url = f"{backend_base_url}{image_path}"
    print(f"Flutter图片URL: {flutter_image_url}")
    
    try:
        response = requests.get(flutter_image_url, timeout=10)
        if response.status_code == 200:
            print(f"✅ Flutter图片URL访问成功，大小: {len(response.content)} 字节")
        else:
            print(f"❌ Flutter图片URL访问失败: {response.status_code}")
    except Exception as e:
        print(f"❌ Flutter图片URL访问异常: {e}")

if __name__ == "__main__":
    print("=== 预览流程完整测试 ===\n")
    
    # 1. 测试登录
    token = test_login()
    
    if token:
        # 2. 测试预览生成
        preview_url = test_preview_generation(token)
        
        # 3. 测试图片可访问性
        test_image_accessibility()
        
        # 4. 测试Flutter图片URL
        test_flutter_image_url()
        
        print(f"\n=== 测试完成 ===")
        if preview_url:
            print("✅ 预览流程测试成功！")
        else:
            print("❌ 预览流程测试失败！")
    else:
        print("❌ 无法获取token，跳过后续测试") 