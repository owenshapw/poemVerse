#!/usr/bin/env python3
"""
测试更多Hugging Face模型
"""

import os
import requests
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def test_models():
    """测试多个模型"""
    print("=== 测试Hugging Face模型可用性 ===")
    
    hf_api_key = os.getenv('HF_API_KEY', '')
    if not hf_api_key:
        print("✗ HF_API_KEY未配置")
        return
    
    print(f"✓ HF_API_KEY已配置: {hf_api_key[:10]}...")
    
    # 测试更多模型
    models = [
        "stabilityai/stable-diffusion-2-1",
        "runwayml/stable-diffusion-v1-5",
        "CompVis/stable-diffusion-v1-4",
        "stabilityai/stable-diffusion-2-base",
        "stabilityai/stable-diffusion-xl-base-1.0",
        "stabilityai/stable-diffusion-xl-base-0.9",
        "prompthero/openjourney",
        "dreamlike-art/dreamlike-photoreal-2.0",
        "nitrosocke/Ghibli-Diffusion",
        "hakurei/waifu-diffusion",
        "cjwbw/anything-v3.0",
        "gsdf/Counterfeit-V2.5"
    ]
    
    headers = {
        "Authorization": f"Bearer {hf_api_key}",
        "Content-Type": "application/json"
    }
    
    working_models = []
    
    for model in models:
        print(f"\n测试模型: {model}")
        api_url = f"https://api-inference.huggingface.co/models/{model}"
        
        try:
            # 简单的测试请求
            test_data = {
                "inputs": "a beautiful landscape",
                "parameters": {
                    "num_inference_steps": 5,
                    "guidance_scale": 7.5,
                    "width": 128,
                    "height": 128
                }
            }
            
            response = requests.post(api_url, headers=headers, json=test_data, timeout=30)
            print(f"响应状态: {response.status_code}")
            
            if response.status_code == 200:
                print("✓ 模型可用！")
                working_models.append(model)
            elif response.status_code == 401:
                print("✗ API密钥无效")
                break
            elif response.status_code == 503:
                print("✗ 模型正在加载")
            elif response.status_code == 404:
                print("✗ 模型不存在或未启用推理API")
            else:
                print(f"✗ 错误: {response.status_code}")
                
        except Exception as e:
            print(f"✗ 请求失败: {e}")
    
    print(f"\n=== 测试结果 ===")
    if working_models:
        print("✓ 可用的模型:")
        for model in working_models:
            print(f"  - {model}")
        return working_models[0]  # 返回第一个可用的模型
    else:
        print("❌ 没有找到可用的模型")
        return None

def test_specific_model(model_name):
    """测试特定模型"""
    print(f"\n=== 测试模型: {model_name} ===")
    
    hf_api_key = os.getenv('HF_API_KEY', '')
    if not hf_api_key:
        print("✗ HF_API_KEY未配置")
        return
    
    headers = {
        "Authorization": f"Bearer {hf_api_key}",
        "Content-Type": "application/json"
    }
    
    api_url = f"https://api-inference.huggingface.co/models/{model_name}"
    
    # 生成中文诗词相关的图片
    prompt = "Beautiful Chinese traditional painting style, moonlight, night sky, stars, nostalgic mood, dreamy atmosphere, high quality, detailed, artistic"
    
    data = {
        "inputs": prompt,
        "parameters": {
            "num_inference_steps": 15,
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
            filename = f"test_generated_{model_name.replace('/', '_')}.png"
            with open(filename, 'wb') as f:
                f.write(response.content)
            
            print(f"✅ 图片生成成功: {filename}")
            print(f"文件大小: {len(response.content)} 字节")
            return True
        else:
            print(f"❌ 生成失败: {response.status_code}")
            print(f"错误: {response.text[:200]}")
            return False
            
    except Exception as e:
        print(f"❌ 生成异常: {e}")
        return False

if __name__ == "__main__":
    print("=== Hugging Face 模型测试 ===\n")
    
    # 测试模型可用性
    working_model = test_models()
    
    if working_model:
        # 测试实际生成
        test_specific_model(working_model)
    else:
        print("\n建议:")
        print("1. 检查你的Hugging Face token权限")
        print("2. 访问 https://huggingface.co/models?pipeline_tag=text-to-image&sort=downloads")
        print("3. 找到启用了推理API的模型")
        print("4. 更新代码中的模型URL")
    
    print("\n=== 测试完成 ===") 