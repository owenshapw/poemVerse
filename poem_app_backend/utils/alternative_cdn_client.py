import os
import requests
from typing import Optional, Dict, Any
import base64
from datetime import datetime

class AlternativeCDNClient:
    """备用CDN客户端，提供多种CDN选择"""
    
    def __init__(self):
        self.cdn_providers = {
            'local': self._upload_to_local,
            'imgbb': self._upload_to_imgbb,
            'imgur': self._upload_to_imgur,
            'postimages': self._upload_to_postimages,
        }
        self.current_provider = 'local'  # 默认使用本地存储
    
    def upload_file(self, file_data: bytes, filename: str, content_type: str = 'image/png') -> Optional[str]:
        """上传文件到当前选择的CDN"""
        try:
            return self.cdn_providers[self.current_provider](file_data, filename, content_type)
        except Exception as e:
            print(f"❌ {self.current_provider} CDN上传失败: {e}")
            return self._fallback_upload(file_data, filename, content_type)
    
    def set_provider(self, provider: str):
        """设置CDN提供商"""
        if provider in self.cdn_providers:
            self.current_provider = provider
            print(f"✅ 切换到 {provider} CDN")
        else:
            print(f"❌ 不支持的CDN提供商: {provider}")
    
    def _upload_to_local(self, file_data: bytes, filename: str, content_type: str) -> Optional[str]:
        """上传到本地存储"""
        try:
            # 创建uploads目录
            upload_dir = 'uploads'
            os.makedirs(upload_dir, exist_ok=True)
            
            # 生成唯一文件名
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            unique_filename = f"{timestamp}_{filename}"
            file_path = os.path.join(upload_dir, unique_filename)
            
            # 保存文件
            with open(file_path, 'wb') as f:
                f.write(file_data)
            
            # 返回本地URL（需要配置本地服务器）
            base_url = os.getenv('LOCAL_BASE_URL', 'http://localhost:8080')
            return f"{base_url}/uploads/{unique_filename}"
            
        except Exception as e:
            print(f"❌ 本地存储失败: {e}")
            return None
    
    def _upload_to_imgbb(self, file_data: bytes, filename: str, content_type: str) -> Optional[str]:
        """上传到ImgBB（免费图片托管）"""
        try:
            api_key = os.getenv('IMGBB_API_KEY')
            if not api_key:
                print("❌ 未配置IMGBB_API_KEY")
                return None
            
            # 将图片数据编码为base64
            image_data = base64.b64encode(file_data).decode('utf-8')
            
            url = "https://api.imgbb.com/1/upload"
            data = {
                'key': api_key,
                'image': image_data,
                'name': filename
            }
            
            response = requests.post(url, data=data, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            if result.get('success'):
                return result['data']['url']
            else:
                print(f"❌ ImgBB上传失败: {result.get('error', {}).get('message', 'Unknown error')}")
                return None
                
        except Exception as e:
            print(f"❌ ImgBB上传异常: {e}")
            return None
    
    def _upload_to_imgur(self, file_data: bytes, filename: str, content_type: str) -> Optional[str]:
        """上传到Imgur（需要API密钥）"""
        try:
            client_id = os.getenv('IMGUR_CLIENT_ID')
            if not client_id:
                print("❌ 未配置IMGUR_CLIENT_ID")
                return None
            
            url = "https://api.imgur.com/3/image"
            headers = {
                'Authorization': f'Client-ID {client_id}'
            }
            
            files = {
                'image': (filename, file_data, content_type)
            }
            
            response = requests.post(url, headers=headers, files=files, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            if result.get('success'):
                return result['data']['link']
            else:
                print(f"❌ Imgur上传失败: {result.get('data', {}).get('error', 'Unknown error')}")
                return None
                
        except Exception as e:
            print(f"❌ Imgur上传异常: {e}")
            return None
    
    def _upload_to_postimages(self, file_data: bytes, filename: str, content_type: str) -> Optional[str]:
        """上传到PostImages（免费图片托管）"""
        try:
            url = "https://postimages.org/json/rr"
            
            files = {
                'file': (filename, file_data, content_type)
            }
            
            response = requests.post(url, files=files, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            if result.get('status') == 'OK':
                return result['data']['url']
            else:
                print(f"❌ PostImages上传失败: {result.get('error', 'Unknown error')}")
                return None
                
        except Exception as e:
            print(f"❌ PostImages上传异常: {e}")
            return None
    
    def _fallback_upload(self, file_data: bytes, filename: str, content_type: str) -> Optional[str]:
        """回退上传方案"""
        print("🔄 尝试回退上传方案...")
        
        # 尝试其他CDN提供商
        for provider in self.cdn_providers:
            if provider != self.current_provider:
                try:
                    print(f"🔄 尝试 {provider}...")
                    result = self.cdn_providers[provider](file_data, filename, content_type)
                    if result:
                        print(f"✅ 回退到 {provider} 成功")
                        return result
                except Exception as e:
                    print(f"❌ {provider} 回退失败: {e}")
                    continue
        
        print("❌ 所有CDN提供商都失败了")
        return None
    
    def get_available_providers(self) -> Dict[str, str]:
        """获取可用的CDN提供商"""
        return {
            'local': '本地存储',
            'imgbb': 'ImgBB (免费)',
            'imgur': 'Imgur (需要API密钥)',
            'postimages': 'PostImages (免费)',
        }
    
    def test_connection(self, provider: str = None) -> Dict[str, Any]:
        """测试CDN连接"""
        if provider is None:
            provider = self.current_provider
        
        test_data = b'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='  # 1x1透明PNG
        
        try:
            result = self.cdn_providers[provider](test_data, 'test.png', 'image/png')
            return {
                'provider': provider,
                'status': 'success' if result else 'failed',
                'url': result,
                'error': None
            }
        except Exception as e:
            return {
                'provider': provider,
                'status': 'error',
                'url': None,
                'error': str(e)
            }

# 创建全局实例
alternative_cdn_client = AlternativeCDNClient() 