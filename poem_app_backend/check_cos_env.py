#!/usr/bin/env python3
"""
检查腾讯云 COS 环境变量配置
"""

import os
from dotenv import load_dotenv

# 加载 .env 文件（如果存在）
load_dotenv()

print("=== 腾讯云 COS 环境变量检查 ===")
print()

# 检查必需的环境变量
required_vars = [
    'COS_SECRET_ID',
    'COS_SECRET_KEY', 
    'COS_REGION',
    'COS_BUCKET'
]

for var in required_vars:
    value = os.getenv(var)
    if value:
        # 对于敏感信息，只显示前几个字符
        if 'SECRET' in var:
            display_value = value[:8] + '***' if len(value) > 8 else '***'
        else:
            display_value = value
        print(f"✅ {var}: {display_value}")
    else:
        print(f"❌ {var}: 未设置")

print()

# 检查可选的环境变量
optional_vars = ['COS_DOMAIN']
for var in optional_vars:
    value = os.getenv(var)
    if value:
        print(f"✅ {var}: {value}")
    else:
        print(f"⚠️  {var}: 未设置（可选）")

print()

# 显示完整的配置信息
print("=== 当前 COS 配置 ===")
print(f"地域: {os.getenv('COS_REGION', '未设置')}")
print(f"存储桶: {os.getenv('COS_BUCKET', '未设置')}")
print(f"Secret ID: {os.getenv('COS_SECRET_ID', '未设置')[:8] + '***' if os.getenv('COS_SECRET_ID') else '未设置'}")
print(f"Secret Key: {'已设置' if os.getenv('COS_SECRET_KEY') else '未设置'}")
print(f"自定义域名: {os.getenv('COS_DOMAIN', '未设置')}")

print()

# 测试 COS 客户端初始化
try:
    from utils.cos_client import cos_client
    print("=== COS 客户端测试 ===")
    if cos_client.is_available():
        print("✅ COS 客户端初始化成功")
        print(f"   地域: {cos_client.region}")
        print(f"   存储桶: {cos_client.bucket}")
    else:
        print("❌ COS 客户端初始化失败")
except Exception as e:
    print(f"❌ COS 客户端测试失败: {e}") 