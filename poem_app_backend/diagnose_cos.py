#!/usr/bin/env python3
"""
详细诊断腾讯云COS配置
"""

import os
from dotenv import load_dotenv
from qcloud_cos import CosConfig, CosS3Client
import json

# 加载环境变量
load_dotenv()

def diagnose_cos():
    """详细诊断COS配置"""
    print("🔍 详细诊断腾讯云COS配置")
    print("=" * 60)
    
    # 获取配置
    secret_id = os.getenv('COS_SECRET_ID')
    secret_key = os.getenv('COS_SECRET_KEY')
    region = os.getenv('COS_REGION', 'ap-beijing')
    bucket = os.getenv('COS_BUCKET')
    
    print("📋 当前配置:")
    print(f"  - Secret ID: {'已配置' if secret_id else '未配置'}")
    print(f"  - Secret Key: {'已配置' if secret_key else '未配置'}")
    print(f"  - Region: {region}")
    print(f"  - Bucket: {bucket}")
    
    if not all([secret_id, secret_key]):
        print("❌ 密钥配置不完整")
        return
    
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
        
        # 列出所有存储桶
        print(f"\n📋 列出所有存储桶...")
        try:
            response = client.list_buckets()
            if 'Buckets' in response and 'Bucket' in response['Buckets']:
                buckets = response['Buckets']['Bucket']
                print(f"找到 {len(buckets)} 个存储桶:")
                
                for i, b in enumerate(buckets, 1):
                    bucket_name = b['Name']
                    bucket_location = b['Location']
                    bucket_region = b.get('Region', '未知')
                    
                    print(f"  {i}. {bucket_name}")
                    print(f"      - 地域: {bucket_location}")
                    print(f"      - 区域: {bucket_region}")
                    
                    # 检查是否匹配当前配置
                    if bucket_name == bucket:
                        print(f"      ✅ 匹配当前配置")
                    elif bucket_location == region:
                        print(f"      💡 同地域存储桶")
                    
                    # 测试访问权限
                    try:
                        test_response = client.head_bucket(Bucket=bucket_name)
                        print(f"      ✅ 可访问")
                    except Exception as e:
                        print(f"      ❌ 无法访问: {str(e)[:50]}...")
                    
                    print()
            else:
                print("❌ 未找到任何存储桶")
                print(f"响应内容: {json.dumps(response, indent=2, ensure_ascii=False)}")
                
        except Exception as e:
            print(f"❌ 列出存储桶失败: {e}")
            import traceback
            traceback.print_exc()
        
        # 测试当前配置的存储桶
        if bucket:
            print(f"\n🔍 测试当前配置的存储桶: {bucket}")
            try:
                response = client.head_bucket(Bucket=bucket)
                print("✅ 存储桶存在且可访问")
                
                # 尝试列出文件
                try:
                    list_response = client.list_objects(
                        Bucket=bucket,
                        MaxKeys=5
                    )
                    if 'Contents' in list_response:
                        print(f"✅ 存储桶中有 {len(list_response['Contents'])} 个文件")
                    else:
                        print("✅ 存储桶为空")
                except Exception as e:
                    print(f"⚠️ 列出文件失败: {e}")
                
            except Exception as e:
                print(f"❌ 存储桶验证失败: {e}")
                
                # 尝试不同的存储桶名称
                print(f"\n🔍 尝试常见的存储桶名称变体...")
                possible_names = [
                    bucket,
                    bucket.replace('-', ''),
                    bucket.replace('-', '_'),
                    f"{bucket}-{region}",
                    f"poemverse-{bucket.split('-')[-1] if '-' in bucket else bucket}",
                    "poemverse",
                    "poem-verse"
                ]
                
                for name in possible_names:
                    if name != bucket:  # 跳过已测试的名称
                        try:
                            test_response = client.head_bucket(Bucket=name)
                            print(f"✅ 找到可用存储桶: {name}")
                            break
                        except:
                            continue
                else:
                    print("❌ 未找到可用的存储桶名称变体")
        
    except Exception as e:
        print(f"❌ COS客户端初始化失败: {e}")
        import traceback
        traceback.print_exc()

def test_upload_with_bucket(bucket_name):
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
        test_key = "test/diagnose_test.txt"
        
        response = client.put_object(
            Bucket=bucket_name,
            Body=test_content.encode('utf-8'),
            Key=test_key,
            ContentType='text/plain'
        )
        
        print("✅ 测试上传成功")
        
        # 获取文件URL
        file_url = f"https://{bucket_name}.cos.{region}.myqcloud.com/{test_key}"
        print(f"📎 文件URL: {file_url}")
        
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
    diagnose_cos()
    
    print("\n" + "=" * 60)
    print("💡 建议:")
    print("1. 检查存储桶名称是否正确（区分大小写）")
    print("2. 确认存储桶所在地域是否为 ap-beijing")
    print("3. 检查API密钥是否有存储桶访问权限")
    print("4. 如果找到正确的存储桶名称，请更新 .env 文件")
    print("5. 确保存储桶已创建且状态正常")

if __name__ == "__main__":
    main() 