import os
import requests
import json
from PIL import Image
from io import BytesIO
import uuid
from flask import current_app
from models.supabase_client import supabase_client
from supabase.client import create_client
from utils.cloudflare_client import cloudflare_client
import imghdr
import re

class AIImageGenerator:
    def __init__(self):
        self.api_url = "https://api.stability.ai/v1/generation/stable-diffusion-xl-1024-v1-0/text-to-image"
        self.api_key = None
        self.hf_api_url = "https://api-inference.huggingface.co/models/stabilityai/stable-diffusion-xl-base-1.0"
        self.hf_api_key = None
        self._initialized = False

    def _init_client(self):
        if self._initialized:
            return
        self.api_key = os.environ.get('STABILITY_API_KEY', '')
        self.hf_api_key = os.environ.get('HF_API_KEY', '')
        self._initialized = True

    def generate_prompt_from_poem(self, title, content, tags, style='abstract_ink'):
        prompt_parts = []

        imagery_map = {
            '春': ['spring landscape', 'cherry blossoms', 'green trees'],
            '秋': ['autumn landscape', 'golden leaves', 'maple trees'],
            '雪': ['winter snow', 'white landscape', 'snowflakes'],
            '月': ['moonlight', 'night sky', 'stars'],
            '山': ['mountain landscape', 'peaks', 'clouds'],
            '水': ['river', 'water', 'flowing stream'],
            '江': ['river', 'misty water'],
            '河': ['river', 'wetlands'],
            '花': ['wild mountain flowers', 'blooming petals', 'natural colors']
        }
        for key, phrases in imagery_map.items():
            if key in title:
                prompt_parts.extend(phrases)

        emotion_map = {
            ('愁', '悲', '泪', '伤'): ['melancholy mood', 'soft lighting', 'gentle colors'],
            ('喜', '乐', '欢', '笑'): ['joyful mood', 'bright colors', 'warm lighting'],
            ('思', '念', '忆', '怀'): ['nostalgic mood', 'dreamy atmosphere', 'soft focus'],
            ('孤', '旅', '远', '君'): ['romantic solitude', 'a winding path', 'distant figure']
        }
        for keys, phrases in emotion_map.items():
            if any(k in content for k in keys):
                prompt_parts.extend(phrases)

        tag_map = {
            '自然': ['natural landscape', 'scenic view'],
            '风景': ['elegant environment', 'open space'],
            '情感': ['romantic atmosphere', 'emotional scene'],
            '爱情': ['romantic scene', 'tender expression'],
            '历史': ['ancient Chinese style', 'traditional elements'],
            '古风': ['ink painting', 'ancient clothing']
        }
        for tag in tags:
            for key, phrases in tag_map.items():
                if key in tag:
                    prompt_parts.extend(phrases)

        if not prompt_parts:
            prompt_parts.append('elegant landscape, emotional abstraction')

        # 固定使用现代抽象风格
        style_phrases = [
            "sunlit abstract painting",
            "fluid brushstrokes with natural rhythm",
            "gentle white space",
            "elegant composition with breathing room",
            "poetic serenity with warm light",
            "contemporary literati expression"
        ]

        color_palette = "warm daylight tones, pale crimson, peach blush, golden ochre, jade yellow, light ivory, sun-washed paper"

        base_prompt = f"{', '.join(style_phrases)}, {', '.join(prompt_parts)}"
        if color_palette:
            base_prompt += f", color palette: {color_palette}"
        base_prompt += ", high quality, detailed, artistic"

        negative_prompt = "text, words, letters, low quality, blurry, distorted, ugly, deformed"
        return base_prompt, negative_prompt

    def generate_with_stability_ai(self, prompt, negative_prompt):
        if not self.api_key:
            return None
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }
        data = {
            "text_prompts": [
                {"text": prompt, "weight": 1},
                {"text": negative_prompt, "weight": -1}
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
                    import base64
                    return BytesIO(base64.b64decode(image_data))
        except Exception as e:
            import traceback
            traceback.print_exc()
        return None

    def generate_with_huggingface(self, prompt, negative_prompt):
        if not self.hf_api_key:
            return None
        headers = {
            "Authorization": f"Bearer {self.hf_api_key}",
            "Content-Type": "application/json"
        }
        data = {
            "inputs": f"{prompt}, high quality, detailed, artistic"
        }
        try:
            response = requests.post(self.hf_api_url, headers=headers, json=data, timeout=60)
            if response.status_code == 200:
                return BytesIO(response.content)
        except requests.exceptions.Timeout:
            pass
        except Exception as e:
            import traceback
            traceback.print_exc()
        return None

    def _ensure_supabase_initialized(self):
        try:
            if supabase_client.supabase is None:
                supabase_url = os.environ.get('SUPABASE_URL')
                supabase_key = os.environ.get('SUPABASE_KEY')
                if supabase_url and supabase_key:
                    supabase_client.supabase = create_client(supabase_url, supabase_key)
                    return True
                else:
                    return False
            return True
        except Exception as e:
            return False

    def _format_image_url(self, url: str) -> str:
        if not url:
            return url
        m = re.search(r'imagedelivery\.net/[^/]+/([\w-]+)/public', url)
        if m:
            image_id = m.group(1)
            return f"https://images.shipian.app/images/{image_id}/headphoto"
        return url

    def generate_poem_image(self, article, user_token=None):
        self._init_client()
        try:
            prompt, negative_prompt = self.generate_prompt_from_poem(
                article['title'],
                article['content'],
                article.get('tags', []),
                style='abstract_ink'
            )
            image_data = self.generate_with_huggingface(prompt, negative_prompt)
            if not image_data:
                image_data = self.generate_with_stability_ai(prompt, negative_prompt)
            if image_data:
                image_data.seek(0)
                image_bytes = image_data.read()
                filename = f"ai_generated_{uuid.uuid4().hex}.png"
                if cloudflare_client.is_available():
                    public_url = cloudflare_client.upload_file(image_bytes, filename)
                else:
                    bucket = "images"
                    if not self._ensure_supabase_initialized():
                        return None
                    if supabase_client.supabase is None:
                        return None
                    storage_client = supabase_client.supabase.storage
                    res = storage_client.from_(bucket).upload(
                        filename,
                        image_bytes,
                        {"content-type": "image/png"}
                    )
                    public_url = supabase_client.supabase.storage.from_(bucket).get_public_url(filename)
                if public_url:
                    return self._format_image_url(public_url)
                else:
                    return None
            else:
                return None
        except Exception as e:
            import traceback
            traceback.print_exc()
            return None

ai_generator = AIImageGenerator()