#!/usr/bin/env python3
"""
测试登录功能
"""

import requests
import json

def test_login():
    """测试登录功能"""
    url = "http://127.0.0.1:5001/api/login"
    
    # 测试数据
    test_data = {
        "email": "owensha@gmail.com",
        "password": "D1ffs2P3"
    }
    
    print(f"Testing login with: {test_data}")
    
    try:
        response = requests.post(url, json=test_data, headers={
            'Content-Type': 'application/json'
        })
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        
        if response.status_code == 200:
            data = response.json()
            print("✅ Login successful!")
            print(f"Token: {data.get('token', 'N/A')}")
            print(f"User: {data.get('user', 'N/A')}")
        else:
            print("❌ Login failed")
            
    except Exception as e:
        print(f"❌ Request failed: {e}")

if __name__ == '__main__':
    test_login() 