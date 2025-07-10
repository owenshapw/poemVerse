#!/usr/bin/env python3
"""
测试使用预览图片发布文章的功能
"""

import requests
import json

# 配置
BASE_URL = "http://127.0.0.1:5001"
EMAIL = "owensha@gmail.com"
PASSWORD = "D1ffs2P3"

def test_preview_reuse():
    """测试预览图片重用功能"""
    
    # 1. 登录获取token
    print("1. 登录获取token...")
    login_data = {
        "email": EMAIL,
        "password": PASSWORD
    }
    
    login_response = requests.post(f"{BASE_URL}/api/login", json=login_data)
    if login_response.status_code != 200:
        print(f"登录失败: {login_response.status_code}")
        return
    
    token = login_response.json()["token"]
    print(f"登录成功，获取到token")
    
    # 2. 生成预览图片
    print("\n2. 生成预览图片...")
    preview_data = {
        "title": "春日山行",
        "content": "远看山有色，近听水无声。春去花还在，人来鸟不惊。",
        "tags": ["自然", "春天", "山水"],
        "author": "王维"
    }
    
    headers = {"Authorization": f"Bearer {token}"}
    preview_response = requests.post(f"{BASE_URL}/api/generate/preview", 
                                   json=preview_data, headers=headers)
    
    if preview_response.status_code != 200:
        print(f"预览生成失败: {preview_response.status_code}")
        return
    
    preview_url = preview_response.json()["preview_url"]
    print(f"预览图片生成成功: {preview_url}")
    
    # 3. 使用预览图片发布文章
    print("\n3. 使用预览图片发布文章...")
    article_data = {
        "title": "春日山行",
        "content": "远看山有色，近听水无声。春去花还在，人来鸟不惊。",
        "tags": ["自然", "春天", "山水"],
        "author": "王维",
        "preview_image_url": preview_url  # 使用预览图片URL
    }
    
    create_response = requests.post(f"{BASE_URL}/api/articles", 
                                  json=article_data, headers=headers)
    
    if create_response.status_code != 201:
        print(f"文章发布失败: {create_response.status_code}")
        print(f"错误信息: {create_response.text}")
        return
    
    article = create_response.json()["article"]
    print(f"文章发布成功!")
    print(f"文章ID: {article['id']}")
    print(f"文章标题: {article['title']}")
    print(f"文章图片URL: {article['image_url']}")
    
    # 4. 验证图片URL是否与预览图片相同
    if article['image_url'] == preview_url:
        print("\n✅ 成功：发布的文章使用了预览图片！")
    else:
        print(f"\n❌ 失败：发布的文章图片与预览图片不同")
        print(f"预览图片: {preview_url}")
        print(f"发布图片: {article['image_url']}")
    
    # 5. 获取文章列表验证
    print("\n4. 获取文章列表验证...")
    articles_response = requests.get(f"{BASE_URL}/api/articles")
    if articles_response.status_code == 200:
        articles = articles_response.json()["articles"]
        latest_article = articles[0]  # 最新的文章
        print(f"最新文章图片URL: {latest_article['image_url']}")
        
        if latest_article['image_url'] == preview_url:
            print("✅ 验证成功：文章列表中显示的是预览图片")
        else:
            print("❌ 验证失败：文章列表中的图片与预览图片不同")

if __name__ == "__main__":
    test_preview_reuse() 