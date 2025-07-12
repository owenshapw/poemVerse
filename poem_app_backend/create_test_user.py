#!/usr/bin/env python3
"""
创建测试用户
"""

import bcrypt
import os
from models.supabase_client import supabase_client
from config import Config
from flask import Flask

app = Flask(__name__)
app.config.from_object(Config())
supabase_client.init_app(app)

def create_test_user():
    """创建测试用户"""
    with app.app_context():
        if not supabase_client.supabase:
            print("❌ Supabase 客户端未初始化")
            return False
        
        email = "test@example.com"
        password = "test123456"
        username = "testuser"
        
        # 检查用户是否已存在
        existing_user = supabase_client.get_user_by_email(email)
        if existing_user:
            print(f"✅ 用户 {email} 已存在")
            return True
        
        # 创建新用户
        print(f"🔄 创建测试用户: {email}")
        user = supabase_client.create_user(email, password, username)
        
        if user:
            print(f"✅ 测试用户创建成功: {user['id']}")
            return True
        else:
            print("❌ 测试用户创建失败")
            return False

if __name__ == "__main__":
    create_test_user() 