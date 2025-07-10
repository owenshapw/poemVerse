#!/usr/bin/env python3
"""
Flutter前端集成测试脚本
测试图片生成和API接口的兼容性
"""

import requests
import json
import time

# API基础URL
BASE_URL = "http://localhost:5001/api"

def test_login():
    """测试登录获取token"""
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
    
    response = requests.post(f"{BASE_URL}/login", json=login_data, headers=headers)
    print(f"登录状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print("登录成功!")
        return data['token']
    else:
        print(f"登录失败: {response.text}")
        return None

def test_create_article_for_flutter(token):
    """测试创建文章（Flutter前端格式）"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "*/*"
    }
    
    article_data = {
        "title": "静夜思",
        "content": "床前明月光，疑是地上霜。\n\n举头望明月，低头思故乡。",
        "tags": ["思乡", "月亮", "诗词"]
    }
    
    response = requests.post(f"{BASE_URL}/articles", json=article_data, headers=headers)
    print(f"\n创建文章状态码: {response.status_code}")
    
    if response.status_code == 201:
        data = response.json()
        print("文章创建成功!")
        print(f"文章ID: {data['article']['id']}")
        print(f"图片URL: {data['article']['image_url']}")
        return data['article']['id']
    else:
        print(f"创建失败: {response.text}")
        return None

def test_get_articles_for_flutter():
    """测试获取文章列表（Flutter前端格式）"""
    response = requests.get(f"{BASE_URL}/articles")
    print(f"\n获取文章列表状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"获取到 {data['total']} 篇文章:")
        for article in data['articles']:
            print(f"- {article['title']} (作者: {article['author']})")
            print(f"  图片URL: {article['image_url']}")
            print(f"  标签: {article['tags']}")
        return data['articles']
    else:
        print(f"获取失败: {response.text}")
        return []

def test_generate_preview_for_flutter(token):
    """测试生成预览图片（Flutter前端格式）"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "*/*"
    }
    
    preview_data = {
        "title": "登鹳雀楼",
        "content": "白日依山尽，黄河入海流。\n\n欲穷千里目，更上一层楼。",
        "tags": ["登高", "壮丽", "诗词"]
    }
    
    response = requests.post(f"{BASE_URL}/generate/preview", json=preview_data, headers=headers)
    print(f"\n生成预览图片状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print("预览图片生成成功!")
        print(f"预览URL: {data['preview_url']}")
        return data['preview_url']
    else:
        print(f"预览生成失败: {response.text}")
        return None

def test_image_access():
    """测试图片访问"""
    # 测试一个已知的图片URL
    test_url = "http://localhost:5001/uploads/article_a2277770-7031-448d-81b7-bfbf9a2c0e13.png"
    response = requests.head(test_url)
    print(f"\n图片访问测试状态码: {response.status_code}")
    
    if response.status_code == 200:
        print("图片访问正常!")
        print(f"Content-Type: {response.headers.get('Content-Type')}")
        print(f"Content-Length: {response.headers.get('Content-Length')}")
    else:
        print("图片访问失败!")

def main():
    """主测试函数"""
    print("=== Flutter前端集成测试 ===\n")
    
    # 1. 登录获取token
    token = test_login()
    if not token:
        print("登录失败，无法继续测试")
        return
    
    # 2. 创建文章（Flutter格式）
    article_id = test_create_article_for_flutter(token)
    if not article_id:
        print("创建文章失败，无法继续测试")
        return
    
    # 等待一下，确保图片生成完成
    time.sleep(2)
    
    # 3. 获取文章列表（Flutter格式）
    test_get_articles_for_flutter()
    
    # 4. 生成预览图片（Flutter格式）
    test_generate_preview_for_flutter(token)
    
    # 5. 测试图片访问
    test_image_access()
    
    print("\n=== 测试完成 ===")
    print("如果所有测试都通过，Flutter前端应该能正常显示图片和文章")

if __name__ == "__main__":
    main() 