#!/usr/bin/env python3
"""
检查环境变量配置
"""

import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def check_env_vars():
    """检查环境变量"""
    print("🔍 检查环境变量配置...")
    print("=" * 50)
    
    # 检查COS相关环境变量
    cos_vars = {
        'COS_SECRET_ID': os.getenv('COS_SECRET_ID'),
        'COS_SECRET_KEY': os.getenv('COS_SECRET_KEY'),
        'COS_REGION': os.getenv('COS_REGION'),
        'COS_BUCKET': os.getenv('COS_BUCKET'),
        'COS_DOMAIN': os.getenv('COS_DOMAIN'),
    }
    
    print("腾讯云COS配置:")
    for var, value in cos_vars.items():
        if value:
            if 'SECRET' in var:
                print(f"  ✅ {var}: {'*' * len(value)}")
            else:
                print(f"  ✅ {var}: {value}")
        else:
            print(f"  ❌ {var}: 未设置")
    
    print("\nSupabase配置:")
    supabase_vars = {
        'SUPABASE_URL': os.getenv('SUPABASE_URL'),
        'SUPABASE_KEY': os.getenv('SUPABASE_KEY'),
    }
    
    for var, value in supabase_vars.items():
        if value:
            if 'KEY' in var:
                print(f"  ✅ {var}: {'*' * len(value)}")
            else:
                print(f"  ✅ {var}: {value}")
        else:
            print(f"  ❌ {var}: 未设置")
    
    print("\n其他配置:")
    other_vars = {
        'SECRET_KEY': os.getenv('SECRET_KEY'),
        'FLASK_ENV': os.getenv('FLASK_ENV'),
        'FLASK_DEBUG': os.getenv('FLASK_DEBUG'),
    }
    
    for var, value in other_vars.items():
        if value:
            print(f"  ✅ {var}: {value}")
        else:
            print(f"  ❌ {var}: 未设置")
    
    # 检查COS配置完整性
    cos_required = ['COS_SECRET_ID', 'COS_SECRET_KEY', 'COS_BUCKET']
    cos_missing = [var for var in cos_required if not cos_vars[var]]
    
    print("\n" + "=" * 50)
    if cos_missing:
        print(f"❌ COS配置不完整，缺少: {', '.join(cos_missing)}")
        print("💡 请在Render控制台的环境变量中配置这些值")
    else:
        print("✅ COS配置完整")
    
    # 检查是否在Render环境
    if os.getenv('RENDER'):
        print("🌐 当前运行在Render环境")
    else:
        print("💻 当前运行在本地环境")

if __name__ == "__main__":
    check_env_vars() 