import os
import requests
import json
from PIL import Image
from io import BytesIO
import uuid
from flask import current_app

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
            return None
            
        headers = {
            "Authorization": f"Bearer {self.hf_api_key}",
            "Content-Type": "application/json"
        }
        
        data = {
            "inputs": prompt,
            "parameters": {
                "negative_prompt": negative_prompt,
                "num_inference_steps": 30,
                "guidance_scale": 7.5,
                "width": 512,
                "height": 512
            }
        }
        
        try:
            response = requests.post(self.hf_api_url, headers=headers, json=data)
            if response.status_code == 200:
                return BytesIO(response.content)
        except Exception as e:
            print(f"Hugging Face生成失败: {e}")
        
        return None
    
    def generate_poem_image(self, article):
        """为诗词生成AI图片"""
        try:
            # 生成提示词
            prompt, negative_prompt = self.generate_prompt_from_poem(
                article['title'], 
                article['content'], 
                article.get('tags', [])
            )
            
            print(f"生成提示词: {prompt}")
            
            # 尝试使用Stability AI
            image_data = self.generate_with_stability_ai(prompt, negative_prompt)
            
            # 如果失败，尝试Hugging Face
            if not image_data:
                image_data = self.generate_with_huggingface(prompt, negative_prompt)
            
            if image_data:
                # 保存图片
                filename = f"ai_generated_{uuid.uuid4().hex}.png"
                upload_folder = current_app.config.get('UPLOAD_FOLDER', 'uploads')
                filepath = os.path.join(upload_folder, filename)
                
                # 确保目录存在
                os.makedirs(upload_folder, exist_ok=True)
                
                # 保存图片
                with open(filepath, 'wb') as f:
                    f.write(image_data.getvalue())
                
                return f"/uploads/{filename}"
            
            return None
            
        except Exception as e:
            print(f"AI图片生成失败: {e}")
            return None

# 创建全局实例
ai_generator = AIImageGenerator() 