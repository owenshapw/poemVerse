#!/usr/bin/env python3
"""
测试Supabase连接和表结构
"""

import os
from dotenv import load_dotenv
from supabase.client import create_client

def test_supabase_connection():
    """测试Supabase连接"""
    load_dotenv()
    
    supabase_url = os.environ.get('SUPABASE_URL')
    supabase_key = os.environ.get('SUPABASE_KEY')
    
    print(f"SUPABASE_URL: {supabase_url}")
    print(f"SUPABASE_KEY: {supabase_key[:10]}..." if supabase_key else "None")
    
    if not supabase_url or not supabase_key:
        print("❌ Supabase配置缺失")
        return False
    
    try:
        # 创建客户端
        supabase = create_client(supabase_url, supabase_key)
        print("✅ Supabase客户端创建成功")
        
        # 测试连接 - 尝试查询users表
        try:
            result = supabase.table('users').select('*').limit(1).execute()
            print("✅ users表查询成功")
            print(f"表结构: {result}")
        except Exception as e:
            print(f"❌ users表查询失败: {e}")
            return False
        
        # 检查表是否存在
        try:
            # 尝试获取表信息
            result = supabase.table('users').select('count').execute()
            print("✅ users表存在且可访问")
        except Exception as e:
            print(f"❌ users表访问失败: {e}")
            return False
        
        return True
        
    except Exception as e:
        print(f"❌ Supabase连接失败: {e}")
        return False

if __name__ == '__main__':
    print("🔍 测试Supabase连接...")
    success = test_supabase_connection()
    
    if success:
        print("\n✅ Supabase连接测试通过")
    else:
        print("\n❌ Supabase连接测试失败")
        print("\n请检查:")
        print("1. .env文件中的SUPABASE_URL和SUPABASE_KEY是否正确")
        print("2. Supabase项目是否已创建users表")
        print("3. 网络连接是否正常") 