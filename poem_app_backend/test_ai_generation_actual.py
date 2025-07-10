#!/usr/bin/env python3
"""
实际测试AI图片生成功能
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# 加载环境变量
from dotenv import load_dotenv
load_dotenv()

from utils.ai_image_generator import ai_generator
import requests

def test_api_keys():
    """测试API密钥是否有效"""
    print("=== 测试API密钥 ===")
    
    # 测试Stability AI
    if ai_generator.api_key:
        print(f"✓ Stability AI API Key已配置: {ai_generator.api_key[:10]}...")
        
        # 测试API连接
        headers = {
            "Authorization": f"Bearer {ai_generator.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        try:
            # 简单的API测试
            test_data = {
                "text_prompts": [
                    {
                        "text": "test",
                        "weight": 1
                    }
                ],
                "cfg_scale": 7,
                "height": 512,
                "width": 512,
                "samples": 1,
                "steps": 10,
            }
            
            response = requests.post(ai_generator.api_url, headers=headers, json=test_data, timeout=30)
            print(f"Stability AI API响应状态: {response.status_code}")
            
            if response.status_code == 200:
                print("✓ Stability AI API连接成功")
            elif response.status_code == 401:
                print("✗ Stability AI API密钥无效")
            elif response.status_code == 402:
                print("✗ Stability AI API配额已用完")
            else:
                print(f"✗ Stability AI API错误: {response.status_code} - {response.text[:100]}")
                
        except Exception as e:
            print(f"✗ Stability AI API连接失败: {e}")
    else:
        print("✗ Stability AI API Key未配置")
    
    # 测试Hugging Face
    if ai_generator.hf_api_key:
        print(f"✓ Hugging Face API Key已配置: {ai_generator.hf_api_key[:10]}...")
        
        # 测试API连接
        headers = {
            "Authorization": f"Bearer {ai_generator.hf_api_key}",
            "Content-Type": "application/json"
        }
        
        try:
            test_data = {
                "inputs": "test",
                "parameters": {
                    "num_inference_steps": 10,
                    "guidance_scale": 7.5,
                    "width": 256,
                    "height": 256
                }
            }
            
            response = requests.post(ai_generator.hf_api_url, headers=headers, json=test_data, timeout=30)
            print(f"Hugging Face API响应状态: {response.status_code}")
            
            if response.status_code == 200:
                print("✓ Hugging Face API连接成功")
            elif response.status_code == 401:
                print("✗ Hugging Face API密钥无效")
            elif response.status_code == 503:
                print("✗ Hugging Face模型正在加载")
            else:
                print(f"✗ Hugging Face API错误: {response.status_code} - {response.text[:100]}")
                
        except Exception as e:
            print(f"✗ Hugging Face API连接失败: {e}")
    else:
        print("✗ Hugging Face API Key未配置")

def test_actual_generation():
    """测试实际的图片生成"""
    print("\n=== 测试实际图片生成 ===")
    
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
            else:
                print(f"   警告: 文件不存在 {filepath}")
        else:
            print("❌ AI图片生成失败")
            
    except Exception as e:
        print(f"❌ AI图片生成异常: {e}")

def test_error_handling():
    """测试错误处理"""
    print("\n=== 测试错误处理 ===")
    
    # 测试空内容
    empty_article = {
        'title': '',
        'content': '',
        'tags': []
    }
    
    try:
        image_url = ai_generator.generate_poem_image(empty_article)
        print(f"空内容测试结果: {image_url}")
    except Exception as e:
        print(f"空内容测试异常: {e}")
    
    # 测试特殊字符
    special_article = {
        'title': '测试标题!@#$%^&*()',
        'content': '测试内容\n换行符\r回车符\t制表符',
        'tags': ['特殊', '字符', '测试']
    }
    
    try:
        image_url = ai_generator.generate_poem_image(special_article)
        print(f"特殊字符测试结果: {image_url}")
    except Exception as e:
        print(f"特殊字符测试异常: {e}")

if __name__ == "__main__":
    print("=== AI图片生成功能实际测试 ===\n")
    
    test_api_keys()
    test_actual_generation()
    test_error_handling()
    
    print("\n=== 测试完成 ===") 