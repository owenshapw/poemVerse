#!/usr/bin/env python3
"""
登录流程测试脚本
验证登录API的完整流程
"""

import requests
import json

# API基础URL
BASE_URL = "http://localhost:5001/api"

def test_login_flow():
    """测试完整的登录流程"""
    print("=== 登录流程测试 ===\n")
    
    # 1. 测试登录
    login_data = {
        "email": "owensha@gmail.com",
        "password": "D1ffs2P3"
    }
    
    headers = {
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "*/*",
        "Accept-Encoding": "gzip, deflate, br, zstd",
        "Accept-Language": "zh-CN,zh;q=0.9",
        "Connection": "keep-alive",
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/138.0.0.0 Safari/537.36"
    }
    
    print("1. 发送登录请求...")
    response = requests.post(f"{BASE_URL}/login", json=login_data, headers=headers)
    print(f"   状态码: {response.status_code}")
    print(f"   响应头: {dict(response.headers)}")
    
    if response.status_code == 200:
        data = response.json()
        print("   ✅ 登录成功!")
        print(f"   返回数据: {json.dumps(data, indent=2, ensure_ascii=False)}")
        
        # 检查返回的数据结构
        if 'token' in data:
            print("   ✅ Token字段存在")
        else:
            print("   ❌ Token字段缺失")
            
        if 'user' in data:
            print("   ✅ User字段存在")
            user = data['user']
            if 'id' in user and 'email' in user:
                print("   ✅ User数据完整")
            else:
                print("   ❌ User数据不完整")
        else:
            print("   ❌ User字段缺失")
            
        if 'message' in data:
            print("   ✅ Message字段存在")
        else:
            print("   ❌ Message字段缺失")
            
        return data.get('token')
    else:
        print(f"   ❌ 登录失败: {response.text}")
        return None

def test_health_check():
    """测试健康检查"""
    print("\n2. 测试健康检查...")
    response = requests.get(f"{BASE_URL.replace('/api', '')}/health")
    print(f"   状态码: {response.status_code}")
    if response.status_code == 200:
        print("   ✅ 后端服务正常")
    else:
        print("   ❌ 后端服务异常")

def test_api_base():
    """测试API基础路径"""
    print("\n3. 测试API基础路径...")
    response = requests.get(f"{BASE_URL.replace('/api', '')}/")
    print(f"   状态码: {response.status_code}")
    if response.status_code == 200:
        print("   ✅ API基础路径正常")
    else:
        print("   ❌ API基础路径异常")

def main():
    """主测试函数"""
    # 测试健康检查
    test_health_check()
    
    # 测试API基础路径
    test_api_base()
    
    # 测试登录流程
    token = test_login_flow()
    
    if token:
        print(f"\n✅ 登录流程测试完成，Token: {token[:20]}...")
        print("\n如果Flutter前端仍然无法跳转，请检查：")
        print("1. Flutter应用是否正确重新编译")
        print("2. AuthProvider中的isAuthenticated逻辑")
        print("3. AuthWrapper是否正确监听状态变化")
        print("4. 网络连接和CORS设置")
    else:
        print("\n❌ 登录流程测试失败")

if __name__ == "__main__":
    main() 