import os
import requests
import uuid
from flask import current_app

class CloudflareClient:
    """Cloudflare Images 客户端"""
    
    def __init__(self):
        self.account_id = None
        self.api_token = None
        self._init_client()
    
    def _init_client(self):
        """初始化 Cloudflare 客户端"""
        try:
            self.account_id = os.getenv('CLOUDFLARE_ACCOUNT_ID')
            self.api_token = os.getenv('CLOUDFLARE_API_TOKEN')
            
            if not all([self.account_id, self.api_token]):
                print("❌ Cloudflare 配置不完整，跳过初始化")
                print(f"  - Account ID: {'已配置' if self.account_id else '未配置'}")
                print(f"  - API Token: {'已配置' if self.api_token else '未配置'}")
                return
            
            print(f"✅ Cloudflare Images 客户端初始化成功，Account ID: {self.account_id}")
                
        except Exception as e:
            print(f"❌ Cloudflare 客户端初始化失败: {e}")
            self.account_id = None
            self.api_token = None
    
    def upload_file(self, file_data, filename, content_type='image/png'):
        """上传文件到 Cloudflare Images"""
        if not self.is_available():
            print("❌ Cloudflare 不可用")
            return None
        
        try:
            print(f"🔄 上传文件到 Cloudflare Images: {filename}")
            
            # 生成唯一的文件名
            file_extension = filename.split('.')[-1] if '.' in filename else 'png'
            unique_filename = f"poemverse_{uuid.uuid4().hex}.{file_extension}"
            
            headers = {
                'Authorization': f'Bearer {self.api_token}'
            }
            
            # 准备上传数据
            files = {
                'file': (unique_filename, file_data, content_type)
            }
            
            # 可选：添加元数据
            data = {
                'metadata': f'filename={filename}',
                'requireSignedURLs': 'false'  # 允许公开访问
            }
            
            # 上传到 Cloudflare Images
            response = requests.post(
                f'https://api.cloudflare.com/client/v4/accounts/{self.account_id}/images/v1',
                headers=headers,
                files=files,
                data=data,
                timeout=60
            )
            
            if response.status_code == 200:
                result = response.json()
                if result.get('success'):
                    image_info = result['result']
                    # Cloudflare Images 返回的 URL 格式
                    public_url = image_info['variants'][0]  # 使用第一个变体（通常是原始尺寸）
                    print(f"✅ 文件上传成功: {public_url}")
                    return public_url
                else:
                    print(f"❌ Cloudflare 上传失败: {result.get('errors', [])}")
                    return None
            else:
                print(f"❌ Cloudflare 上传失败: {response.status_code} - {response.text}")
                return None
                
        except Exception as e:
            print(f"❌ 文件上传失败: {e}")
            return None
    
    def delete_file(self, image_id):
        """删除文件"""
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
        """检查 Cloudflare 是否可用"""
        return self.account_id is not None and self.api_token is not None
    
    def list_files(self, max_files=10):
        """列出文件"""
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
        # Cloudflare Images 的 URL 格式
        return f"https://imagedelivery.net/{self.account_id}/{image_id}/{variant}"

# 创建全局实例
cloudflare_client = CloudflareClient() 