import os
import time
from qcloud_cos import CosConfig, CosS3Client
from flask import current_app

class COSClient:
    """腾讯云 COS 客户端"""
    
    def __init__(self):
        self.client = None
        self.bucket = None
        self.region = None
        self._init_client()
    
    def _init_client(self):
        """初始化COS客户端"""
        try:
            secret_id = os.getenv('COS_SECRET_ID')
            secret_key = os.getenv('COS_SECRET_KEY')
            bucket = os.getenv('COS_BUCKET')
            region = os.getenv('COS_REGION', 'ap-guangzhou')
            
            if not all([secret_id, secret_key, bucket]):
                print("❌ COS 配置不完整，跳过初始化")
                return
            
            config = CosConfig(
                Region=region,
                SecretId=secret_id,
                SecretKey=secret_key,
                Timeout=120,  # 增加超时时间到120秒
            )
            
            self.client = CosS3Client(config)
            self.bucket = bucket
            self.region = region
            
            # 测试连接
            try:
                self.client.head_bucket(Bucket=bucket)
                print(f"✅ 腾讯云 COS 客户端初始化成功，Bucket: {bucket}")
            except Exception as e:
                print(f"❌ COS 连接测试失败: {e}")
                self.client = None
                
        except Exception as e:
            print(f"❌ COS 客户端初始化失败: {e}")
            self.client = None
    
    def upload_file(self, file_data, filename, content_type='application/octet-stream'):
        """上传文件到COS"""
        if not self.is_available() or self.client is None:
            print("❌ COS 不可用")
            return None
        
        try:
            print(f"🔄 上传文件到COS: {filename}")
            
            # 构建对象键
            object_key = f"poemverse/{filename}"
            
            # 上传文件
            response = self.client.put_object(
                Bucket=self.bucket,
                Body=file_data,
                Key=object_key,
                ContentType=content_type
            )
            
            # 构建腾讯云COS默认公网URL
            public_url = f"https://{self.bucket}.cos.{self.region}.myqcloud.com/{object_key}"
            print(f"✅ 文件上传成功: {public_url}")
            return public_url
            
        except Exception as e:
            print(f"❌ 文件上传失败: {e}")
            return None
    
    def delete_file(self, file_url):
        """删除文件"""
        if not self.is_available() or self.client is None:
            return False
            
        try:
            # 从腾讯云默认域名中提取文件路径
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
        """检查COS是否可用"""
        return self.client is not None and self.bucket is not None
    
    def list_files(self, prefix='', max_keys=10):
        """列出文件"""
        if not self.is_available() or self.client is None:
            return []
        
        try:
            response = self.client.list_objects(
                Bucket=self.bucket,
                Prefix=prefix,
                MaxKeys=max_keys
            )
            
            if 'Contents' in response:
                return [obj['Key'] for obj in response['Contents']]
            return []
            
        except Exception as e:
            print(f"获取文件列表失败: {e}")
            return []
    
    def get_public_url(self, file_key):
        """获取文件的公开访问URL（腾讯云COS默认URL）"""
        return f"https://{self.bucket}.cos.{self.region}.myqcloud.com/{file_key}"

# 创建全局实例
cos_client = COSClient() 