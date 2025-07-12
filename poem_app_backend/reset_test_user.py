#!/usr/bin/env python3
"""
重置测试用户密码
"""

import os
import bcrypt
from dotenv import load_dotenv
from supabase.client import create_client

# 加载环境变量
load_dotenv()

def reset_test_user_password():
    """重置测试用户密码"""
    print("🔧 重置测试用户密码...")
    
    # 测试用户信息
    test_email = "test@example.com"
    new_password = "123456"
    
    # 获取 Supabase 配置
    supabase_url = os.environ.get("SUPABASE_URL")
    supabase_key = os.environ.get("SUPABASE_KEY")
    
    if not supabase_url or not supabase_key:
        print("❌ Supabase 环境变量未配置")
        return False
    
    try:
        # 创建 Supabase 客户端
        supabase = create_client(supabase_url, supabase_key)
        print("✅ Supabase 客户端创建成功")
        
        # 查找测试用户
        print(f"查找用户: {test_email}")
        result = supabase.table('users').select('*').eq('email', test_email).execute()
        
        if not result.data:
            print("❌ 测试用户不存在")
            return False
        
        user = result.data[0]
        print(f"✅ 找到用户: {user['id']}")
        
        # 生成新密码哈希
        password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # 更新用户密码
        update_result = supabase.table('users').update({
            'password_hash': password_hash
        }).eq('id', user['id']).execute()
        
        if update_result.data:
            print("✅ 密码重置成功")
            print(f"新密码: {new_password}")
            return True
        else:
            print("❌ 密码重置失败")
            return False
            
    except Exception as e:
        print(f"❌ 重置密码时出现错误: {e}")
        return False

if __name__ == '__main__':
    success = reset_test_user_password()
    if success:
        print("\n✅ 测试用户密码重置成功!")
        print("现在可以使用 test@example.com / 123456 登录")
    else:
        print("\n❌ 密码重置失败!") 