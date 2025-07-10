#!/usr/bin/env python3
"""
诗篇发布和查看功能测试脚本
"""

import requests
import json

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

def test_create_article(token):
    """测试发布诗篇"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    article_data = {
        "title": "春日游园",
        "content": "春色满园关不住，一枝红杏出墙来。\n\n小园香径独徘徊，\n满目春光入眼来。\n\n花影重重蝶影飞，\n莺声阵阵柳丝垂。\n\n最是一年春好处，\n绝胜烟柳满皇都。",
        "tags": ["春天", "游园", "诗词"]
    }
    
    response = requests.post(f"{BASE_URL}/articles", json=article_data, headers=headers)
    print(f"\n发布诗篇状态码: {response.status_code}")
    
    if response.status_code == 201:
        data = response.json()
        print("诗篇发布成功!")
        print(f"文章ID: {data['article']['id']}")
        return data['article']['id']
    else:
        print(f"发布失败: {response.text}")
        return None

def test_get_articles():
    """测试获取所有诗篇"""
    response = requests.get(f"{BASE_URL}/articles")
    print(f"\n获取诗篇列表状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"获取到 {data['total']} 篇诗篇:")
        for article in data['articles']:
            print(f"- {article['title']} (作者: {article['author']})")
        return data['articles']
    else:
        print(f"获取失败: {response.text}")
        return []

def test_get_article_detail(article_id):
    """测试获取单篇诗篇详情"""
    response = requests.get(f"{BASE_URL}/articles/{article_id}")
    print(f"\n获取诗篇详情状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        article = data['article']
        print(f"诗篇详情:")
        print(f"标题: {article['title']}")
        print(f"作者: {article['author']}")
        print(f"内容: {article['content']}")
        print(f"标签: {article['tags']}")
        print(f"创建时间: {article['created_at']}")
        return article
    else:
        print(f"获取详情失败: {response.text}")
        return None

def test_get_my_articles(token):
    """测试获取我的诗篇"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    response = requests.get(f"{BASE_URL}/my-articles", headers=headers)
    print(f"\n获取我的诗篇状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"我的诗篇 ({data['total']} 篇):")
        for article in data['articles']:
            print(f"- {article['title']} (创建时间: {article['created_at']})")
        return data['articles']
    else:
        print(f"获取失败: {response.text}")
        return []

def test_search_articles():
    """测试搜索诗篇"""
    # 按标签搜索
    response = requests.get(f"{BASE_URL}/articles/search?tag=春天")
    print(f"\n按标签搜索状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"搜索到 {data['total']} 篇包含'春天'标签的诗篇:")
        for article in data['articles']:
            print(f"- {article['title']} (作者: {article['author']})")
    
    # 按作者搜索
    response = requests.get(f"{BASE_URL}/articles/search?author=owensha")
    print(f"\n按作者搜索状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print(f"搜索到 {data['total']} 篇作者为'owensha'的诗篇:")
        for article in data['articles']:
            print(f"- {article['title']}")

def main():
    """主测试函数"""
    print("=== 诗篇发布和查看功能测试 ===\n")
    
    # 1. 登录获取token
    token = test_login()
    if not token:
        print("登录失败，无法继续测试")
        return
    
    # 2. 发布诗篇
    article_id = test_create_article(token)
    if not article_id:
        print("发布失败，无法继续测试")
        return
    
    # 3. 获取所有诗篇
    test_get_articles()
    
    # 4. 获取诗篇详情
    test_get_article_detail(article_id)
    
    # 5. 获取我的诗篇
    test_get_my_articles(token)
    
    # 6. 搜索诗篇
    test_search_articles()
    
    print("\n=== 测试完成 ===")

if __name__ == "__main__":
    main() 