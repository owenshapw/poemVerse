import os
import requests
import json
from PIL import Image
from io import BytesIO
import uuid
from flask import current_app
from models.supabase_client import supabase_client
from supabase.client import create_client  # 正确导入
from utils.cos_client import cos_client  # 导入 COS 客户端

class AIImageGenerator:
    """AI图片生成器"""
    
    def __init__(self):
        # 使用免费的Stable Diffusion API - 使用更兼容的模型
        self.api_url = "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image"
        self.api_key = os.getenv('STABILITY_API_KEY', '')  # 需要注册获取免费API key
        
        # 备用API - 使用免费的Hugging Face API
        self.hf_api_url = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0"
        self.hf_api_key = os.getenv('HF_API_KEY', '')  # 需要注册获取免费API key
        
    def generate_prompt_from_poem(self, title, content, tags):
        """根据诗词内容生成AI提示词"""
        # 分析诗词主题和情感
        prompt_parts = []
        
        # 从标题提取关键词
        if '春' in title:
            prompt_parts.append('spring landscape, cherry blossoms, green trees')
        if '秋' in title:
            prompt_parts.append('autumn landscape, golden leaves, maple trees')
        if '雪' in title:
            prompt_parts.append('winter snow, white landscape, snowflakes')
        if '月' in title:
            prompt_parts.append('moonlight, night sky, stars')
        if '山' in title:
            prompt_parts.append('mountain landscape, peaks, clouds')
        if '水' in title or '江' in title or '河' in title:
            prompt_parts.append('river, water, flowing stream')
        if '花' in title:
            prompt_parts.append('flowers, blooming, colorful petals')
        
        # 从内容提取情感和主题
        content_lower = content.lower()
        if any(word in content_lower for word in ['愁', '悲', '泪', '伤']):
            prompt_parts.append('melancholy mood, soft lighting, gentle colors')
        if any(word in content_lower for word in ['喜', '乐', '欢', '笑']):
            prompt_parts.append('joyful mood, bright colors, warm lighting')
        if any(word in content_lower for word in ['思', '念', '忆', '怀']):
            prompt_parts.append('nostalgic mood, dreamy atmosphere, soft focus')
        
        # 从标签提取主题
        for tag in tags:
            if '自然' in tag or '风景' in tag:
                prompt_parts.append('natural landscape, scenic view')
            if '情感' in tag or '爱情' in tag:
                prompt_parts.append('romantic atmosphere, emotional scene')
            if '历史' in tag or '古风' in tag:
                prompt_parts.append('ancient Chinese style, traditional architecture')
        
        # 默认风格
        if not prompt_parts:
            prompt_parts.append('Chinese traditional painting style, elegant landscape')
        
        # 组合提示词
        base_prompt = f"Beautiful Chinese traditional painting style, {', '.join(prompt_parts)}, high quality, detailed, artistic"
        
        # 负面提示词
        negative_prompt = "text, words, letters, low quality, blurry, distorted, ugly, deformed"
        
        return base_prompt, negative_prompt
    
    def generate_with_stability_ai(self, prompt, negative_prompt):
        """使用Stability AI生成图片"""
        if not self.api_key:
            return None
            
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        
        data = {
            "text_prompts": [
                {
                    "text": prompt,
                    "weight": 1
                },
                {
                    "text": negative_prompt,
                    "weight": -1
                }
            ],
            "cfg_scale": 7,
            "height": 1024,
            "width": 1024,
            "samples": 1,
            "steps": 30,
        }
        
        try:
            response = requests.post(self.api_url, headers=headers, json=data)
            if response.status_code == 200:
                result = response.json()
                if 'artifacts' in result and len(result['artifacts']) > 0:
                    image_data = result['artifacts'][0]['base64']
                    # 修复：base64解码而不是十六进制解码
                    import base64
                    return BytesIO(base64.b64decode(image_data))
            else:
                print(f"Stability AI API错误: {response.status_code} - {response.text[:200]}")
        except Exception as e:
            print(f"Stability AI生成失败: {e}")
        
        return None
    
    def generate_with_huggingface(self, prompt, negative_prompt):
        """使用Hugging Face生成图片"""
        if not self.hf_api_key:
            print("Hugging Face API key未设置，跳过生成。")
            return None
            
        print(f"使用 Hugging Face API 生成图片，API Key: {self.hf_api_key[:10]}...")
        
        headers = {
            "Authorization": f"Bearer {self.hf_api_key}",
            "Content-Type": "application/json"
        }
        
        # 简化请求格式，只使用基本的 inputs 参数
        data = {
            "inputs": f"{prompt}, high quality, detailed, artistic"
        }
        
        try:
            print(f"发送请求到: {self.hf_api_url}")
            print(f"请求数据: {data}")
            
            response = requests.post(self.hf_api_url, headers=headers, json=data, timeout=60)
            
            print(f"Hugging Face API 响应状态码: {response.status_code}")
            
            if response.status_code == 200:
                print("Hugging Face 图片生成成功")
                return BytesIO(response.content)
            else:
                print(f"Hugging Face API 错误: 状态码 {response.status_code}")
                print(f"Hugging Face API 响应: {response.text[:500]}") # 打印前500个字符的响应
                
                # 检查是否是模型加载中的错误
                if "loading" in response.text.lower():
                    print("模型正在加载中，请稍后重试")
                elif "quota" in response.text.lower():
                    print("API 配额已用完")
                elif "unauthorized" in response.text.lower():
                    print("API Key 无效或权限不足")
                elif "model" in response.text.lower() and "not found" in response.text.lower():
                    print("模型不存在或不可访问")
                
        except requests.exceptions.Timeout:
            print("Hugging Face API 请求超时")
        except requests.exceptions.RequestException as e:
            print(f"Hugging Face API 请求异常: {e}")
        except Exception as e:
            print(f"Hugging Face生成失败: {e}")
            import traceback
            traceback.print_exc()
        
        return None
    
    def generate_poem_image(self, article, user_token=None):
        """为诗词生成AI图片，并上传到腾讯云 COS"""
        try:
            # 生成提示词
            prompt, negative_prompt = self.generate_prompt_from_poem(
                article['title'], 
                article['content'], 
                article.get('tags', [])
            )
            print(f"生成提示词: {prompt}")
            
            # 优先尝试Hugging Face
            image_data = self.generate_with_huggingface(prompt, negative_prompt)
            
            # 如果失败，再尝试使用Stability AI
            if not image_data:
                print("Hugging Face 生成失败，尝试 Stability AI")
                image_data = self.generate_with_stability_ai(prompt, negative_prompt)
                
            if image_data:
                # 生成文件名
                filename = f"ai_generated_{uuid.uuid4().hex}.png"
                
                # 优先使用腾讯云 COS
                if cos_client.is_available():
                    print("使用腾讯云 COS 上传图片")
                    public_url = cos_client.upload_file(
                        image_data.getvalue(),
                        filename,
                        'image/png'
                    )
                else:
                    print("COS 不可用，回退到 Supabase")
                    # 回退到 Supabase
                    bucket = "images"
                    
                    if not supabase_client.supabase:
                        raise RuntimeError("Supabase client 未初始化")
                    
                    storage_client = supabase_client.supabase.storage
                    
                    # 上传图片内容
                    res = storage_client.from_(bucket).upload(
                        filename, 
                        image_data.getvalue(), 
                        {"content-type": "image/png"}
                    )
                    print(f"Supabase上传返回: {res}")
                    
                    # 获取公开URL
                    public_url = supabase_client.supabase.storage.from_(bucket).get_public_url(filename)
                
                if public_url:
                    print(f"AI图片生成成功: {public_url}")
                    return public_url
                else:
                    print("图片上传失败")
                    return None
            else:
                print("所有AI图片生成方法都失败了")
                return None
                
        except Exception as e:
            print(f"AI图片生成失败: {e}")
            import traceback
            traceback.print_exc()
            return None

# 创建全局实例
ai_generator = AIImageGenerator() 