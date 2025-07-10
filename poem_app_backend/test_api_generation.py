#!/usr/bin/env python3
"""
测试API接口的图片生成功能
"""

import requests
import json

def test_preview_generation():
    """测试预览图片生成API"""
    print("=== 测试预览图片生成API ===")
    
    url = "http://127.0.0.1:5001/api/generate/preview"
    
    # 测试数据
    test_data = {
        "title": "静夜思",
        "content": "床前明月光，疑是地上霜。举头望明月，低头思故乡。",
        "author": "李白",
        "tags": ["思乡", "月亮", "情感"]
    }
    
    headers = {
        "Content-Type": "application/json"
    }
    
    try:
        print("发送预览生成请求...")
        response = requests.post(url, headers=headers, json=test_data, timeout=120)
        
        print(f"响应状态: {response.status_code}")
        
        if response.status_code == 200:
            result = response.json()
            print("✅ 预览生成成功！")
            print(f"预览URL: {result.get('preview_url')}")
            return True
        else:
            print(f"❌ 预览生成失败: {response.status_code}")
            print(f"错误: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ 请求异常: {e}")
        return False

def test_simple_generation():
    """测试简单图片生成（不需要认证）"""
    print("\n=== 测试简单图片生成 ===")
    
    # 直接调用AI生成器
    import os
    import sys
    sys.path.append(os.path.dirname(os.path.abspath(__file__)))
    
    from dotenv import load_dotenv
    load_dotenv()
    
    from app import create_app
    from utils.ai_image_generator import ai_generator
    
    app = create_app()
    
    with app.app_context():
        test_article = {
            'title': '测试诗词',
            'content': '这是一首测试诗词，用于验证AI图片生成功能。',
            'tags': ['测试', '验证']
        }
        
        print("正在生成测试图片...")
        image_url = ai_generator.generate_poem_image(test_article)
        
        if image_url:
            print(f"✅ 测试图片生成成功: {image_url}")
            
            # 检查文件
            filepath = os.path.join('uploads', os.path.basename(image_url))
            if os.path.exists(filepath):
                file_size = os.path.getsize(filepath)
                print(f"文件大小: {file_size} 字节")
                print(f"文件路径: {filepath}")
                return True
            else:
                print(f"❌ 文件不存在: {filepath}")
                return False
        else:
            print("❌ 测试图片生成失败")
            return False

if __name__ == "__main__":
    print("=== API图片生成功能测试 ===\n")
    
    # 测试简单生成
    simple_ok = test_simple_generation()
    
    # 测试API接口
    api_ok = test_preview_generation()
    
    print(f"\n=== 测试结果 ===")
    print(f"简单生成: {'✅ 成功' if simple_ok else '❌ 失败'}")
    print(f"API接口: {'✅ 成功' if api_ok else '❌ 失败'}")
    
    if simple_ok and api_ok:
        print("🎉 所有测试通过！AI图片生成功能完全正常！")
    elif simple_ok:
        print("⚠️  AI生成正常，但API接口需要认证")
    else:
        print("❌ 需要检查AI生成功能")
    
    print("\n=== 测试完成 ===") 