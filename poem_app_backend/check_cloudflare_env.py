#!/usr/bin/env python3
"""
检查 Cloudflare Images 环境变量配置
"""

import os
from dotenv import load_dotenv

def check_cloudflare_env():
    """检查 Cloudflare 环境变量配置"""
    # 加载 .env 文件（如果存在）
    load_dotenv()
    
    # 检查必需的环境变量
    required_vars = [
        'CLOUDFLARE_ACCOUNT_ID',
        'CLOUDFLARE_API_TOKEN'
    ]
    
    config_ok = True
    for var in required_vars:
        value = os.getenv(var)
        if not value:
            config_ok = False
    
    # 测试 Cloudflare 客户端初始化
    try:
        from utils.cloudflare_client import cloudflare_client
        client_ok = cloudflare_client.is_available() if hasattr(cloudflare_client, 'is_available') else False
    except Exception as e:
        client_ok = False
    
    return config_ok and client_ok

if __name__ == '__main__':
    check_cloudflare_env() 
