#!/usr/bin/env python3
"""
带Flask上下文的AI图片生成测试
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# 加载环境变量
from dotenv import load_dotenv
load_dotenv()

from app import create_app
from utils.ai_image_generator import ai_generator
import requests

def test_huggingface_api():
    """测试Hugging Face API连接"""
    print("=== 测试Hugging Face API ===")
    
    if not ai_generator.hf_api_key:
        print("✗ Hugging Face API Key未配置")
        return False
    
    print(f"✓ Hugging Face API Key已配置: {ai_generator.hf_api_key[:10]}...")
    
    # 测试API连接
    headers = {
        "Authorization": f"Bearer {ai_generator.hf_api_key}",
        "Content-Type": "application/json"
    }
    
    # 使用更稳定的模型
    test_url = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0"
    
    try:
        test_data = {
            "inputs": "a beautiful landscape",
            "parameters": {
                "num_inference_steps": 10,
                "guidance_scale": 7.5,
                "width": 256,
                "height": 256
            }
        }
        
        print("正在测试Hugging Face API连接...")
        response = requests.post(test_url, headers=headers, json=test_data, timeout=60)
        print(f"Hugging Face API响应状态: {response.status_code}")
        
        if response.status_code == 200:
            print("✓ Hugging Face API连接成功")
            return True
        elif response.status_code == 401:
            print("✗ Hugging Face API密钥无效")
            return False
        elif response.status_code == 503:
            print("✗ Hugging Face模型正在加载，请稍后再试")
            return False
        else:
            print(f"✗ Hugging Face API错误: {response.status_code}")
            print(f"错误详情: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"✗ Hugging Face API连接失败: {e}")
        return False

def test_ai_generation_with_context():
    """在Flask上下文中测试AI图片生成"""
    print("\n=== 在Flask上下文中测试AI图片生成 ===")
    
    app = create_app()
    with app.app_context():
        test_article = {
            'title': '静夜思',
            'content': '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
            'tags': ['思乡', '月亮', '情感']
        }
        
        print(f"测试文章: {test_article['title']}")
        print(f"内容: {test_article['content']}")
        print(f"标签: {test_article['tags']}")
        
        # 生成提示词
        prompt, negative_prompt = ai_generator.generate_prompt_from_poem(
            test_article['title'], 
            test_article['content'], 
            test_article['tags']
        )
        
        print(f"\n生成提示词: {prompt}")
        print(f"负面提示词: {negative_prompt}")
        
        # 尝试生成图片
        print("\n开始生成图片...")
        try:
            image_url = ai_generator.generate_poem_image(test_article)
            
            if image_url:
                print(f"✅ AI图片生成成功: {image_url}")
                
                # 检查文件是否存在
                filepath = os.path.join('uploads', os.path.basename(image_url))
                if os.path.exists(filepath):
                    file_size = os.path.getsize(filepath)
                    print(f"   文件大小: {file_size} 字节")
                    print(f"   文件路径: {filepath}")
                    
                    # 检查文件是否为有效图片
                    if file_size > 1000:  # 至少1KB
                        print("   文件大小正常，应该是有效图片")
                    else:
                        print("   警告: 文件太小，可能不是有效图片")
                else:
                    print(f"   警告: 文件不存在 {filepath}")
            else:
                print("❌ AI图片生成失败")
                
        except Exception as e:
            print(f"❌ AI图片生成异常: {e}")

def test_stability_api():
    """测试Stability AI API"""
    print("\n=== 测试Stability AI API ===")
    
    if not ai_generator.api_key:
        print("✗ Stability AI API Key未配置")
        return False
    
    print(f"✓ Stability AI API Key已配置: {ai_generator.api_key[:10]}...")
    
    # 使用更兼容的模型
    test_url = "https://api.stability.ai/v1/generation/stable-diffusion-v1-5/text-to-image"
    
    headers = {
        "Authorization": f"Bearer {ai_generator.api_key}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    data = {
        "text_prompts": [
            {
                "text": "a beautiful landscape",
                "weight": 1
            }
        ],
        "cfg_scale": 7,
        "height": 512,
        "width": 512,
        "samples": 1,
        "steps": 10,
    }
    
    try:
        print("正在测试Stability AI API连接...")
        response = requests.post(test_url, headers=headers, json=data, timeout=60)
        print(f"Stability AI API响应状态: {response.status_code}")
        
        if response.status_code == 200:
            print("✓ Stability AI API连接成功")
            return True
        elif response.status_code == 401:
            print("✗ Stability AI API密钥无效")
            return False
        elif response.status_code == 402:
            print("✗ Stability AI API配额已用完")
            return False
        else:
            print(f"✗ Stability AI API错误: {response.status_code}")
            print(f"错误详情: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"✗ Stability AI API连接失败: {e}")
        return False

if __name__ == "__main__":
    print("=== AI图片生成功能完整测试 ===\n")
    
    # 测试API连接
    hf_ok = test_huggingface_api()
    stability_ok = test_stability_api()
    
    if not hf_ok and not stability_ok:
        print("\n❌ 所有API都连接失败，请检查API密钥和网络连接")
        sys.exit(1)
    
    # 测试实际生成
    test_ai_generation_with_context()
    
    print("\n=== 测试完成 ===")
    print("\n建议:")
    if hf_ok:
        print("✓ Hugging Face API可用，建议优先使用")
    if stability_ok:
        print("✓ Stability AI API可用，可作为备选") 