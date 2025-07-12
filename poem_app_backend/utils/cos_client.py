import os
import uuid
from qcloud_cos import CosConfig, CosS3Client
from flask import current_app
import sys
import logging

class COSClient:
    """腾讯云 COS 客户端"""
    
    def __init__(self):
        # 从环境变量获取配置
        self.secret_id = os.getenv('COS_SECRET_ID')
        self.secret_key = os.getenv('COS_SECRET_KEY')
        self.region = os.getenv('COS_REGION', 'ap-beijing')  # 默认北京
        self.bucket = os.getenv('COS_BUCKET')
        self.domain = os.getenv('COS_DOMAIN')  # 自定义域名，如 https://your-domain.com
        
        if not all([self.secret_id, self.secret_key, self.bucket]):
            print("⚠️ 腾讯云 COS 配置不完整，请检查环境变量")
            self.client = None
            return
            
        try:
            config = CosConfig(
                Region=self.region,
                SecretId=self.secret_id,
                SecretKey=self.secret_key,
                Timeout=60  # 设置超时时间为60秒
            )
            self.client = CosS3Client(config)
            print(f"✅ 腾讯云 COS 客户端初始化成功，Bucket: {self.bucket}")
        except Exception as e:
            print(f"❌ 腾讯云 COS 客户端初始化失败: {e}")
            self.client = None
    
    def upload_file(self, file_data, filename, content_type='image/png'):
        """上传文件到 COS"""
        if not self.client:
            print("❌ COS 客户端未初始化")
            return None
            
        try:
            # 生成唯一文件名
            file_key = f"poemverse/{filename}"
            
            # 上传文件（适合内存数据）
            response = self.client.put_object(
                Bucket=self.bucket,
                Body=file_data,
                Key=file_key,
                StorageClass='STANDARD',
                EnableMD5=False,
                ContentType=content_type
            )
            
            print(f"✅ 文件上传成功: {file_key}")
            
            # 返回访问 URL
            if self.domain:
                # 使用自定义域名
                return f"{self.domain}/{file_key}"
            else:
                # 使用腾讯云默认域名
                return f"https://{self.bucket}.cos.{self.region}.myqcloud.com/{file_key}"
                
        except Exception as e:
            print(f"❌ 文件上传失败: {e}")
            import traceback
            traceback.print_exc()
            return None
    
    def delete_file(self, file_url):
        """删除文件"""
        if not self.client:
            return False
            
        try:
            # 从 URL 中提取文件路径
            if self.domain and file_url.startswith(self.domain):
                file_key = file_url.replace(f"{self.domain}/", "")
            else:
                # 从腾讯云默认域名中提取
                file_key = file_url.split(f"{self.bucket}.cos.{self.region}.myqcloud.com/")[-1]
            
            response = self.client.delete_object(
                Bucket=self.bucket,
                Key=file_key
            )
            
            print(f"✅ 文件删除成功: {file_key}")
            return True
            
        except Exception as e:
            print(f"❌ 文件删除失败: {e}")
            return False
    
    def is_available(self):
        """检查 COS 是否可用"""
        return self.client is not None
    
    def list_files(self, prefix='', max_keys=100):
        """获取文件列表"""
        try:
            if not self.is_available() or not self.client:
                return []
            
            response = self.client.list_objects(
                Bucket=self.bucket,
                Prefix=prefix,
                MaxKeys=max_keys
            )
            
            files = []
            if 'Contents' in response:
                for obj in response['Contents']:
                    files.append({
                        'key': obj['Key'],
                        'size': obj['Size'],
                        'last_modified': obj['LastModified'].isoformat() if hasattr(obj['LastModified'], 'isoformat') else str(obj['LastModified']),
                        'url': self.get_public_url(obj['Key'])
                    })
            
            return files
        except Exception as e:
            print(f"获取文件列表失败: {str(e)}")
            import traceback
            traceback.print_exc()
            return []
    
    def get_public_url(self, file_key):
        """获取文件的公开访问URL"""
        if self.domain:
            return f"{self.domain}/{file_key}"
        else:
            return f"https://{self.bucket}.cos.{self.region}.myqcloud.com/{file_key}"

# 创建全局实例
cos_client = COSClient() 