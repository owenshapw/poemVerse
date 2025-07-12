#!/usr/bin/env python3
"""
配置COS存储桶为公开访问
"""

import os
from qcloud_cos import CosConfig, CosS3Client

def configure_cos_public():
    """配置COS存储桶为公开访问"""
    print("=== 配置COS存储桶为公开访问 ===")
    
    # 从环境变量获取配置
    secret_id = os.getenv('COS_SECRET_ID')
    secret_key = os.getenv('COS_SECRET_KEY')
    region = os.getenv('COS_REGION', 'ap-guangzhou')
    bucket = os.getenv('COS_BUCKET')
    
    if not all([secret_id, secret_key, bucket]):
        print("❌ COS配置不完整")
        return False
    
    try:
        # 初始化COS客户端
        config = CosConfig(
            Region=region,
            SecretId=secret_id,
            SecretKey=secret_key,
            Timeout=60
        )
        client = CosS3Client(config)
        
        print(f"✅ COS客户端初始化成功")
        print(f"存储桶: {bucket}")
        print(f"地域: {region}")
        
        # 设置存储桶为公开读取
        try:
            # 设置存储桶ACL为公开读取
            response = client.put_bucket_acl(
                Bucket=bucket,
                ACL='public-read'
            )
            print("✅ 存储桶ACL设置为公开读取成功")
            
        except Exception as e:
            print(f"⚠️ 设置存储桶ACL失败: {e}")
            print("这可能是权限问题，请手动在腾讯云控制台设置")
        
        # 设置存储桶策略，允许公开读取
        bucket_policy = {
            "Statement": [
                {
                    "Principal": {
                        "qcs": ["*"]
                    },
                    "Action": [
                        "name/cos:GetObject"
                    ],
                    "Effect": "Allow",
                    "Resource": [
                        f"qcs::cos:{region}:uid/*:{bucket}/*"
                    ]
                }
            ],
            "Version": "2.0"
        }
        
        try:
            response = client.put_bucket_policy(
                Bucket=bucket,
                Policy=json.dumps(bucket_policy)
            )
            print("✅ 存储桶策略设置成功")
            
        except Exception as e:
            print(f"⚠️ 设置存储桶策略失败: {e}")
            print("这可能是权限问题，请手动在腾讯云控制台设置")
        
        print("\n=== 手动配置说明 ===")
        print("如果自动配置失败，请手动在腾讯云控制台进行以下设置：")
        print("1. 登录腾讯云控制台")
        print("2. 进入对象存储COS")
        print("3. 选择存储桶: " + str(bucket))
        print("4. 点击'权限管理' -> '存储桶权限'")
        print("5. 将'公共权限'设置为'公有读私有写'")
        print("6. 保存设置")
        
        return True
        
    except Exception as e:
        print(f"❌ 配置失败: {e}")
        return False

if __name__ == "__main__":
    import json
    configure_cos_public() 