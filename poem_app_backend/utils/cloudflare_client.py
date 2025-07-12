import os
import requests
import uuid
from flask import current_app
import json
import imghdr
from PIL import Image
from io import BytesIO

class CloudflareClient:
    """Cloudflare Images 客户端"""
    
    def __init__(self):
        self.account_id = None
        self.api_token = None
        self._initialized = False
        self._available = None  # 缓存可用性状态
    
    def _init_client(self):
        """初始化 Cloudflare 客户端"""
        if self._initialized:
            return
            
        try:
            # 确保从环境变量加载
            self.account_id = os.environ.get('CLOUDFLARE_ACCOUNT_ID')
            self.api_token = os.environ.get('CLOUDFLARE_API_TOKEN')
            
            if not self.account_id or not self.api_token:
                self._available = False
                self._initialized = True
                return
            
            self._available = True
            self._initialized = True
                
        except Exception as e:
            self.account_id = None
            self.api_token = None
            self._available = False
            self._initialized = True
    
    def _process_image_data(self, file_data, filename):
        """处理图片数据，自动检测格式并转换为PNG"""
        try:
            # 检测原始图片格式
            image_buffer = BytesIO(file_data)
            original_format = imghdr.what(image_buffer)
            
            # 使用 PIL 打开图片并统一转换为 PNG
            image_buffer.seek(0)
            pil_image = Image.open(image_buffer)
            
            # 转换为 RGB 模式（确保兼容性）
            if pil_image.mode != 'RGB':
                pil_image = pil_image.convert('RGB')
            
            # 保存为 PNG 格式到 BytesIO
            png_buffer = BytesIO()
            pil_image.save(png_buffer, format='PNG', optimize=True)
            png_buffer.seek(0)
            
            # 获取 PNG 数据
            image_bytes = png_buffer.getvalue()
            
            # 验证 PNG 文件头
            if len(image_bytes) >= 8:
                png_header = image_bytes[:8]
                if png_header != b'\x89PNG\r\n\x1a\n':
                    return None, 'image/png'
            
            return image_bytes, 'image/png'
            
        except Exception as e:
            print(f"❌ 图片格式转换失败: {e}")
            return None, 'image/png'
    
    def upload_file(self, file_data, filename, content_type=None):
        """上传文件到 Cloudflare Images，自动检测和转换图片格式"""
        # 延迟初始化
        self._init_client()
        
        if not self.is_available():
            print("❌ Cloudflare 不可用")
            return None
        
        try:
            print(f"🔄 上传文件到 Cloudflare Images: {filename}")
            
            # 自动检测和转换图片格式
            processed_data, final_content_type = self._process_image_data(file_data, filename)
            
            if processed_data is None:
                print("❌ 图片处理失败，无法上传")
                return None
            
            # 生成唯一的文件名（统一使用 PNG 扩展名）
            unique_filename = f"poemverse_{uuid.uuid4().hex}.png"
            
            headers = {
                'Authorization': f'Bearer {self.api_token}'
            }
            
            # 准备上传数据 - metadata和requireSignedURLs都作为multipart字段传递
            files = {
                'file': (unique_filename, processed_data, final_content_type),
                'metadata': (None, f'{{"filename":"{filename}","original_name":"{filename}"}}', 'application/json'),
                'requireSignedURLs': (None, 'false', 'text/plain')
            }
            
            # 上传到 Cloudflare Images - metadata作为multipart字段
            response = requests.post(
                f'https://api.cloudflare.com/client/v4/accounts/{self.account_id}/images/v1',
                headers=headers,
                files=files,
                timeout=60
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success'):
                    image_info = result['result']
                    # 使用 .get() 避免 dict key 不存在报错
                    variants = image_info.get('variants', [])
                    if variants:
                        # 上传到public变体，但返回headphoto变体URL给APP端
                        public_url = variants[1] if len(variants) > 1 else variants[0]  # headphoto 变体
                        print(f"✅ 文件上传成功: {public_url}")
                        return public_url
                    else:
                        print("❌ 未找到可用的变体URL")
                        return None
                else:
                    print(f"❌ Cloudflare 上传失败: {result.get('errors', [])}")
                    return None
            else:
                print(f"❌ Cloudflare 上传失败: {response.status_code}")
                return None
                
        except Exception as e:
            print(f"❌ 文件上传失败: {e}")
            return None
    
    def delete_file(self, image_id):
        """删除文件"""
        # 延迟初始化
        self._init_client()
        
        if not self.is_available():
            return False
            
        try:
            headers = {
                'Authorization': f'Bearer {self.api_token}'
            }
            
            response = requests.delete(
                f'https://api.cloudflare.com/client/v4/accounts/{self.account_id}/images/v1/{image_id}',
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200:
                print(f"✅ 文件删除成功: {image_id}")
                return True
            else:
                print(f"❌ 文件删除失败: {response.status_code}")
                return False
                
        except Exception as e:
            print(f"❌ 文件删除失败: {e}")
            return False
    
    def is_available(self):
        """检查 Cloudflare 是否可用 - 使用缓存结果"""
        if self._available is not None:
            return self._available
        
        # 延迟初始化
        self._init_client()
        return self._available
    
    def list_files(self, max_files=10):
        """列出文件"""
        # 延迟初始化
        self._init_client()
        
        if not self.is_available():
            return []
        
        try:
            headers = {
                'Authorization': f'Bearer {self.api_token}',
                'Content-Type': 'application/json'
            }
            
            response = requests.get(
                f'https://api.cloudflare.com/client/v4/accounts/{self.account_id}/images/v1',
                headers=headers,
                params={'per_page': max_files},
                timeout=30
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success'):
                    images = result['result']['images']
                    return [img['id'] for img in images]
            return []
            
        except Exception as e:
            print(f"获取文件列表失败: {e}")
            return []
    
    def get_public_url(self, image_id, variant='public'):
        """获取文件的公开访问URL"""
        # 延迟初始化
        self._init_client()
        
        if not self.is_available():
            return None
            
        # Cloudflare Images 的 URL 格式
        return f"https://imagedelivery.net/{self.account_id}/{image_id}/{variant}"

# 创建全局实例
cloudflare_client = CloudflareClient() 