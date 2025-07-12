#!/usr/bin/env python3
"""
验证腾讯云COS存储桶配置
"""

import os
from dotenv import load_dotenv
from qcloud_cos import CosConfig, CosS3Client

# 加载环境变量
load_dotenv()

def verify_cos_config():
    """验证COS配置"""
    print("🔍 验证腾讯云COS配置...")
    
    # 获取配置
    secret_id = os.getenv('COS_SECRET_ID')
    secret_key = os.getenv('COS_SECRET_KEY')
    region = os.getenv('COS_REGION', 'ap-beijing')
    bucket = os.getenv('COS_BUCKET')
    
    print(f"配置信息:")
    print(f"  - Secret ID: {'已配置' if secret_id else '未配置'}")
    print(f"  - Secret Key: {'已配置' if secret_key else '未配置'}")
    print(f"  - Region: {region}")
    print(f"  - Bucket: {bucket}")
    
    if not all([secret_id, secret_key, bucket]):
        print("❌ 配置不完整")
        return False
    
    try:
        # 初始化客户端
        config = CosConfig(
            Region=region,
            SecretId=secret_id,
            SecretKey=secret_key,
            Timeout=30
        )
        client = CosS3Client(config)
        print("✅ COS客户端初始化成功")
        
        # 测试存储桶是否存在
        print(f"\n🔍 验证存储桶: {bucket}")
        try:
            response = client.head_bucket(Bucket=bucket)
            print("✅ 存储桶存在且可访问")
            return True
        except Exception as e:
            print(f"❌ 存储桶验证失败: {e}")
            
            # 尝试列出所有存储桶
            print("\n📋 尝试列出所有存储桶...")
            try:
                response = client.list_buckets()
                if 'Buckets' in response:
                    buckets = response['Buckets']['Bucket']
                    print(f"找到 {len(buckets)} 个存储桶:")
                    for b in buckets:
                        print(f"  - {b['Name']} (地域: {b['Location']})")
                        
                        # 检查是否匹配当前配置
                        if b['Name'] == bucket:
                            print(f"    ✅ 匹配当前配置")
                        elif b['Location'] == region:
                            print(f"    💡 同地域存储桶，可考虑使用")
                else:
                    print("未找到任何存储桶")
            except Exception as e2:
                print(f"❌ 列出存储桶失败: {e2}")
            
            return False
            
    except Exception as e:
        print(f"❌ COS客户端初始化失败: {e}")
        return False

def test_upload_to_bucket(bucket_name):
    """测试上传到指定存储桶"""
    print(f"\n📤 测试上传到存储桶: {bucket_name}")
    
    secret_id = os.getenv('COS_SECRET_ID')
    secret_key = os.getenv('COS_SECRET_KEY')
    region = os.getenv('COS_REGION', 'ap-beijing')
    
    try:
        config = CosConfig(
            Region=region,
            SecretId=secret_id,
            SecretKey=secret_key,
            Timeout=30
        )
        client = CosS3Client(config)
        
        # 测试上传小文件
        test_content = "这是一个测试文件"
        test_key = "test/verify_bucket.txt"
        
        response = client.put_object(
            Bucket=bucket_name,
            Body=test_content.encode('utf-8'),
            Key=test_key,
            ContentType='text/plain'
        )
        
        print("✅ 测试上传成功")
        
        # 清理测试文件
        try:
            client.delete_object(Bucket=bucket_name, Key=test_key)
            print("✅ 测试文件已清理")
        except:
            print("⚠️ 测试文件清理失败")
        
        return True
        
    except Exception as e:
        print(f"❌ 测试上传失败: {e}")
        return False

def main():
    """主函数"""
    print("🚀 腾讯云COS存储桶配置验证")
    print("=" * 50)
    
    # 验证配置
    if verify_cos_config():
        bucket = os.getenv('COS_BUCKET')
        if bucket:
            # 测试上传
            test_upload_to_bucket(bucket)
    
    print("\n" + "=" * 50)
    print("💡 建议:")
    print("1. 检查存储桶名称是否正确（区分大小写）")
    print("2. 确认存储桶所在地域是否为 ap-beijing")
    print("3. 检查API密钥是否有存储桶访问权限")
    print("4. 如果存储桶名称不同，请更新 .env 文件中的 COS_BUCKET")

if __name__ == "__main__":
    main() 