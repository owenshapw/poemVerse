import os
import requests
import json
from PIL import Image
from io import BytesIO
import uuid
from flask import current_app
from models.supabase_client import supabase_client
from supabase.client import create_client  # 正确导入
from utils.cloudflare_client import cloudflare_client  # 导入 Cloudflare 客户端
import imghdr  # 添加图片类型检测

class AIImageGenerator:
    """AI图片生成器"""
    
    def __init__(self):
        # 使用免费的Stable Diffusion API - 使用更兼容的模型
        self.api_url = "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image"
        self.api_key = None
        
        # 备用API - 使用免费的Hugging Face API
        self.hf_api_url = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0"
        self.hf_api_key = None
        self._initialized = False
    
    def _init_client(self):
        """延迟初始化，确保环境变量已加载"""
        if self._initialized:
            return
            
        self.api_key = os.environ.get('STABILITY_API_KEY', '')
        self.hf_api_key = os.environ.get('HF_API_KEY', '')
        self._initialized = True
        
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
            response = requests.post(self.api_url, headers=headers, json=data, timeout=30)
            if response.status_code == 200:
                result = response.json()
                if 'artifacts' in result and len(result['artifacts']) > 0:
                    image_data = result['artifacts'][0]['base64']
                    # 修复：base64解码而不是十六进制解码
                    import base64
                    return BytesIO(base64.b64decode(image_data))
            else:
                print(f"Stability AI API错误: {response.status_code}")
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
        
        # 简化请求格式，只使用基本的 inputs 参数
        data = {
            "inputs": f"{prompt}, high quality, detailed, artistic"
        }
        
        try:
            response = requests.post(self.hf_api_url, headers=headers, json=data, timeout=60)
            
            if response.status_code == 200:
                return BytesIO(response.content)
            else:
                print(f"Hugging Face API 错误: 状态码 {response.status_code}")
                
        except requests.exceptions.Timeout:
            print("Hugging Face API 请求超时")
        except Exception as e:
            print(f"Hugging Face生成失败: {e}")
        
        return None
    
    def _ensure_supabase_initialized(self):
        """确保 Supabase 客户端已初始化"""
        try:
            if supabase_client.supabase is None:
                # 尝试从环境变量重新初始化
                supabase_url = os.environ.get('SUPABASE_URL')
                supabase_key = os.environ.get('SUPABASE_KEY')
                
                if supabase_url and supabase_key:
                    supabase_client.supabase = create_client(supabase_url, supabase_key)
                    return True
                else:
                    return False
            return True
        except Exception as e:
            print(f"❌ Supabase 客户端重新初始化失败: {e}")
            return False
    
    def generate_poem_image(self, article, user_token=None):
        """为诗词生成AI图片，并上传到腾讯云 COS"""
        # 延迟初始化
        self._init_client()
        
        try:
            # 生成提示词
            prompt, negative_prompt = self.generate_prompt_from_poem(
                article['title'], 
                article['content'], 
                article.get('tags', [])
            )
            
            # 优先尝试Hugging Face
            image_data = self.generate_with_huggingface(prompt, negative_prompt)
            
            # 如果失败，再尝试使用Stability AI
            if not image_data:
                image_data = self.generate_with_stability_ai(prompt, negative_prompt)
                
            if image_data:
                # 获取原始图片数据
                image_data.seek(0)
                image_bytes = image_data.read()
                
                # 生成文件名
                filename = f"ai_generated_{uuid.uuid4().hex}.png"
                
                # 优先使用 Cloudflare Images（自动处理格式转换）
                if cloudflare_client.is_available():
                    public_url = cloudflare_client.upload_file(
                        image_bytes,
                        filename
                    )
                else:
                    # 回退到 Supabase
                    bucket = "images"
                    
                    # 确保 Supabase 客户端已初始化
                    if not self._ensure_supabase_initialized():
                        return None
                    
                    # 再次检查 supabase 客户端是否可用
                    if supabase_client.supabase is None:
                        return None
                    
                    storage_client = supabase_client.supabase.storage
                    
                    # 上传图片内容 - 使用已读取的字节数据
                    res = storage_client.from_(bucket).upload(
                        filename, 
                        image_bytes, 
                        {"content-type": "image/png"}
                    )
                    
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
            return None

# 创建全局实例
ai_generator = AIImageGenerator() 