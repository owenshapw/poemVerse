#!/usr/bin/env python3
"""
重置测试用户密码
"""

import bcrypt
from models.supabase_client import supabase_client
from config import Config
from flask import Flask

app = Flask(__name__)
app.config.from_object(Config())
supabase_client.init_app(app)

def reset_test_user_password():
    """重置测试用户密码"""
    with app.app_context():
        if not supabase_client.supabase:
            print("❌ Supabase 客户端未初始化")
            return False
        
        email = "test@example.com"
        new_password = "test123456"
        
        # 查找用户
        user = supabase_client.get_user_by_email(email)
        if not user:
            print(f"❌ 用户 {email} 不存在")
            return False
        
        # 生成新的密码哈希
        password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        
        # 更新密码
        result = supabase_client.supabase.table('users').update({
            'password_hash': password_hash
        }).eq('email', email).execute()
        
        if result.data:
            print(f"✅ 用户 {email} 密码重置成功")
            print(f"新密码: {new_password}")
            return True
        else:
            print("❌ 密码重置失败")
            return False

if __name__ == "__main__":
    reset_test_user_password() 