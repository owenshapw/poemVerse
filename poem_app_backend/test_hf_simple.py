#!/usr/bin/env python3
"""
简单的Hugging Face API测试
"""

import os
import requests
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def test_huggingface_api():
    """测试Hugging Face API"""
    print("=== 测试Hugging Face API ===")
    
    # 获取API密钥
    hf_api_key = os.getenv('HF_API_KEY', '')
    if not hf_api_key:
        print("✗ HF_API_KEY未配置")
        return False
    
    print(f"✓ HF_API_KEY已配置: {hf_api_key[:10]}...")
    
    # 测试不同的模型
    models = [
        "stabilityai/stable-diffusion-2-1",
        "runwayml/stable-diffusion-v1-5", 
        "CompVis/stable-diffusion-v1-4"
    ]
    
    headers = {
        "Authorization": f"Bearer {hf_api_key}",
        "Content-Type": "application/json"
    }
    
    for model in models:
        print(f"\n测试模型: {model}")
        api_url = f"https://api-inference.huggingface.co/models/{model}"
        
        try:
            # 简单的测试请求
            test_data = {
                "inputs": "a beautiful Chinese landscape painting",
                "parameters": {
                    "num_inference_steps": 10,
                    "guidance_scale": 7.5,
                    "width": 256,
                    "height": 256
                }
            }
            
            print("发送请求...")
            response = requests.post(api_url, headers=headers, json=test_data, timeout=60)
            print(f"响应状态: {response.status_code}")
            
            if response.status_code == 200:
                print("✓ 模型可用！")
                print(f"响应大小: {len(response.content)} 字节")
                return model
            elif response.status_code == 401:
                print("✗ API密钥无效")
                return None
            elif response.status_code == 503:
                print("✗ 模型正在加载")
            elif response.status_code == 404:
                print("✗ 模型不存在或未启用推理API")
            else:
                print(f"✗ 错误: {response.status_code}")
                print(f"错误详情: {response.text[:200]}")
                
        except Exception as e:
            print(f"✗ 请求失败: {e}")
    
    return None

def test_simple_generation():
    """测试简单的图片生成"""
    print("\n=== 测试简单图片生成 ===")
    
    hf_api_key = os.getenv('HF_API_KEY', '')
    if not hf_api_key:
        print("✗ HF_API_KEY未配置")
        return
    
    # 使用确认可用的模型
    working_model = test_huggingface_api()
    if not working_model:
        print("❌ 没有可用的模型")
        return
    
    print(f"\n使用模型: {working_model}")
    
    headers = {
        "Authorization": f"Bearer {hf_api_key}",
        "Content-Type": "application/json"
    }
    
    api_url = f"https://api-inference.huggingface.co/models/{working_model}"
    
    # 生成中文诗词相关的图片
    prompt = "Beautiful Chinese traditional painting style, moonlight, night sky, stars, nostalgic mood, dreamy atmosphere, high quality, detailed, artistic"
    
    data = {
        "inputs": prompt,
        "parameters": {
            "num_inference_steps": 20,
            "guidance_scale": 7.5,
            "width": 512,
            "height": 512
        }
    }
    
    try:
        print("正在生成图片...")
        response = requests.post(api_url, headers=headers, json=data, timeout=120)
        
        if response.status_code == 200:
            # 保存图片
            filename = f"test_hf_generated_{working_model.replace('/', '_')}.png"
            with open(filename, 'wb') as f:
                f.write(response.content)
            
            print(f"✅ 图片生成成功: {filename}")
            print(f"文件大小: {len(response.content)} 字节")
        else:
            print(f"❌ 生成失败: {response.status_code}")
            print(f"错误: {response.text[:200]}")
            
    except Exception as e:
        print(f"❌ 生成异常: {e}")

if __name__ == "__main__":
    print("=== Hugging Face API 简单测试 ===\n")
    
    test_simple_generation()
    
    print("\n=== 测试完成 ===") 