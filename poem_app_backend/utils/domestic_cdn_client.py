import os
import requests
from typing import Optional, Dict, Any
import base64
from datetime import datetime

class DomesticCDNClient:
    """国内CDN客户端，使用国内可访问的CDN服务"""
    
    def __init__(self):
        self.cdn_providers = {
            'aliyun_oss': self._upload_to_aliyun_oss,
            'qiniu': self._upload_to_qiniu,
            'tencent_cos': self._upload_to_tencent_cos,
            'local': self._upload_to_local,
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
    
    def _upload_to_aliyun_oss(self, file_data: bytes, filename: str, content_type: str) -> Optional[str]:
        """上传到阿里云OSS"""
        try:
            # 需要配置阿里云OSS的访问密钥
            access_key_id = os.getenv('ALIYUN_ACCESS_KEY_ID')
            access_key_secret = os.getenv('ALIYUN_ACCESS_KEY_SECRET')
            bucket_name = os.getenv('ALIYUN_BUCKET_NAME')
            endpoint = os.getenv('ALIYUN_ENDPOINT')
            
            if not all([access_key_id, access_key_secret, bucket_name, endpoint]):
                print("❌ 未配置阿里云OSS环境变量")
                return None
            
            # 这里需要安装阿里云SDK: pip install oss2
            try:
                import oss2
            except ImportError:
                print("❌ 请安装阿里云OSS SDK: pip install oss2")
                return None
            
            # 创建OSS客户端
            auth = oss2.Auth(access_key_id, access_key_secret)
            bucket = oss2.Bucket(auth, endpoint, bucket_name)
            
            # 生成唯一文件名
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            unique_filename = f"poemverse/{timestamp}_{filename}"
            
            # 上传文件
            result = bucket.put_object(unique_filename, file_data)
            
            if result.status == 200:
                return f"https://{bucket_name}.{endpoint}/{unique_filename}"
            else:
                print(f"❌ 阿里云OSS上传失败: {result.status}")
                return None
                
        except Exception as e:
            print(f"❌ 阿里云OSS上传异常: {e}")
            return None
    
    def _upload_to_qiniu(self, file_data: bytes, filename: str, content_type: str) -> Optional[str]:
        """上传到七牛云"""
        try:
            access_key = os.getenv('QINIU_ACCESS_KEY')
            secret_key = os.getenv('QINIU_SECRET_KEY')
            bucket_name = os.getenv('QINIU_BUCKET_NAME')
            domain = os.getenv('QINIU_DOMAIN')
            
            if not all([access_key, secret_key, bucket_name, domain]):
                print("❌ 未配置七牛云环境变量")
                return None
            
            # 这里需要安装七牛云SDK: pip install qiniu
            try:
                import qiniu
            except ImportError:
                print("❌ 请安装七牛云SDK: pip install qiniu")
                return None
            
            # 创建上传凭证
            auth = qiniu.Auth(access_key, secret_key)
            token = auth.upload_token(bucket_name)
            
            # 创建上传管理器
            upload_mgr = qiniu.put_file.PutFile()
            
            # 生成唯一文件名
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            unique_filename = f"poemverse/{timestamp}_{filename}"
            
            # 上传文件
            ret, info = upload_mgr.put(token, unique_filename, file_data)
            
            if info.status_code == 200:
                return f"https://{domain}/{unique_filename}"
            else:
                print(f"❌ 七牛云上传失败: {info.status_code}")
                return None
                
        except Exception as e:
            print(f"❌ 七牛云上传异常: {e}")
            return None
    
    def _upload_to_tencent_cos(self, file_data: bytes, filename: str, content_type: str) -> Optional[str]:
        """上传到腾讯云COS"""
        try:
            secret_id = os.getenv('TENCENT_SECRET_ID')
            secret_key = os.getenv('TENCENT_SECRET_KEY')
            bucket_name = os.getenv('TENCENT_BUCKET_NAME')
            region = os.getenv('TENCENT_REGION')
            
            if not all([secret_id, secret_key, bucket_name, region]):
                print("❌ 未配置腾讯云COS环境变量")
                return None
            
            # 这里需要安装腾讯云SDK: pip install cos-python-sdk-v5
            try:
                from qcloud_cos import CosConfig, CosS3Client
            except ImportError:
                print("❌ 请安装腾讯云COS SDK: pip install cos-python-sdk-v5")
                return None
            
            # 创建COS客户端
            config = CosConfig(Region=region, SecretId=secret_id, SecretKey=secret_key)
            client = CosS3Client(config)
            
            # 生成唯一文件名
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            unique_filename = f"poemverse/{timestamp}_{filename}"
            
            # 上传文件
            response = client.put_object(
                Bucket=bucket_name,
                Body=file_data,
                Key=unique_filename,
                ContentType=content_type
            )
            
            if response['ETag']:
                return f"https://{bucket_name}.cos.{region}.myqcloud.com/{unique_filename}"
            else:
                print("❌ 腾讯云COS上传失败")
                return None
                
        except Exception as e:
            print(f"❌ 腾讯云COS上传异常: {e}")
            return None
    
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
            'aliyun_oss': '阿里云OSS',
            'qiniu': '七牛云',
            'tencent_cos': '腾讯云COS',
            'local': '本地存储',
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
domestic_cdn_client = DomesticCDNClient() 