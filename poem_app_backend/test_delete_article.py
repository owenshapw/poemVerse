#!/usr/bin/env python3
"""
测试文章删除功能
"""

import requests
import json

# 配置
BASE_URL = "http://127.0.0.1:5001"
EMAIL = "owensha@gmail.com"
PASSWORD = "D1ffs2P3"

def test_delete_article():
    """测试文章删除功能"""
    
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
    
    # 2. 获取文章列表
    print("\n2. 获取文章列表...")
    headers = {"Authorization": f"Bearer {token}"}
    articles_response = requests.get(f"{BASE_URL}/api/articles", headers=headers)
    
    if articles_response.status_code != 200:
        print(f"获取文章列表失败: {articles_response.status_code}")
        return
    
    articles = articles_response.json()["articles"]
    if not articles:
        print("没有找到文章，无法测试删除功能")
        return
    
    # 找到用户自己的文章
    user_articles = [article for article in articles if article.get('user_id')]
    if not user_articles:
        print("没有找到用户自己的文章，无法测试删除功能")
        return
    
    test_article = user_articles[0]
    article_id = test_article['id']
    article_title = test_article['title']
    
    print(f"找到测试文章: {article_title} (ID: {article_id})")
    
    # 3. 删除文章
    print(f"\n3. 删除文章: {article_title}")
    delete_response = requests.delete(f"{BASE_URL}/api/articles/{article_id}", headers=headers)
    
    if delete_response.status_code == 200:
        print("✅ 文章删除成功!")
        
        # 4. 验证文章已被删除
        print("\n4. 验证文章已被删除...")
        verify_response = requests.get(f"{BASE_URL}/api/articles", headers=headers)
        
        if verify_response.status_code == 200:
            updated_articles = verify_response.json()["articles"]
            article_exists = any(article['id'] == article_id for article in updated_articles)
            
            if not article_exists:
                print("✅ 验证成功：文章已从列表中删除")
            else:
                print("❌ 验证失败：文章仍在列表中")
        else:
            print(f"❌ 验证失败：无法获取更新后的文章列表")
            
    elif delete_response.status_code == 403:
        print("❌ 删除失败：无权限删除此文章")
    elif delete_response.status_code == 404:
        print("❌ 删除失败：文章不存在")
    else:
        print(f"❌ 删除失败: {delete_response.status_code}")
        print(f"错误信息: {delete_response.text}")

if __name__ == "__main__":
    test_delete_article() 