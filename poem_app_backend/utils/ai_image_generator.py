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
import base64

class AIImageGenerator:
    """AI图片生成器"""

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

    def generate_prompt_from_poem(self, title, content, tags):
        style_phrases = [
            "lyrical abstract painting",
            "dynamic gestural lines",
            "floating speckles of color",
            "dry-brush strokes on coarse canvas",
            "light color fields with painterly texture",
            "playful composition with vibrant rhythm"
        ]

        color_palette = "sky blue, blush pink, ochre yellow, lavender grey, pale jade, ivory white"

        base_prompt = f"{', '.join(style_phrases)}, {color_palette}, high quality, sharp, balanced composition"
        negative_prompt = "text, words, letters, low quality, blurry, distorted, ugly, deformed"

        return base_prompt, negative_prompt

    def generate_with_huggingface(self, prompt, negative_prompt):
        if not self.hf_api_key:
            return None

        headers = {
            "Authorization": f"Bearer {self.hf_api_key}",
            "Content-Type": "application/json"
        }

        data = {
            "inputs": f"{prompt}"
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
            "height": 768,
            "width": 1280,
            "samples": 1,
            "steps": 30,
        }

        try:
            response = requests.post(self.api_url, headers=headers, json=data, timeout=30)
            if response.status_code == 200:
                result = response.json()
                if 'artifacts' in result and len(result['artifacts']) > 0:
                    image_data = result['artifacts'][0]['base64']
                    return BytesIO(base64.b64decode(image_data))
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
                article.get('tags', [])
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
            return None
        except Exception as e:
            import traceback
            traceback.print_exc()
            return None

ai_generator = AIImageGenerator()