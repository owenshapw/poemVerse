#!/usr/bin/env python3
"""
图片生成功能测试脚本
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

def test_create_article_with_image(token):
    """测试发布诗篇并自动生成图片"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "*/*"
    }
    
    article_data = {
        "title": "夜雨寄北",
        "content": "君问归期未有期，巴山夜雨涨秋池。\n\n何当共剪西窗烛，却话巴山夜雨时。",
        "tags": ["夜雨", "思乡", "诗词"]
    }
    
    response = requests.post(f"{BASE_URL}/articles", json=article_data, headers=headers)
    print(f"\n发布诗篇状态码: {response.status_code}")
    
    if response.status_code == 201:
        data = response.json()
        print("诗篇发布成功!")
        print(f"文章ID: {data['article']['id']}")
        print(f"图片URL: {data['article']['image_url']}")
        return data['article']['id']
    else:
        print(f"发布失败: {response.text}")
        return None

def test_generate_image_for_existing_article(token, article_id):
    """测试为现有文章生成图片"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "*/*"
    }
    
    data = {"article_id": article_id}
    response = requests.post(f"{BASE_URL}/generate", json=data, headers=headers)
    print(f"\n生成图片状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print("图片生成成功!")
        print(f"图片URL: {data['image_url']}")
        return data['image_url']
    else:
        print(f"生成失败: {response.text}")
        return None

def test_generate_preview(token):
    """测试生成预览图片"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "*/*"
    }
    
    preview_data = {
        "title": "春晓",
        "content": "春眠不觉晓，处处闻啼鸟。\n\n夜来风雨声，花落知多少。",
        "author": "孟浩然",
        "tags": ["春天", "自然", "诗词"]
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

def test_batch_generate(token):
    """测试批量生成图片"""
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "*/*"
    }
    
    response = requests.post(f"{BASE_URL}/generate/batch", headers=headers)
    print(f"\n批量生成图片状态码: {response.status_code}")
    
    if response.status_code == 200:
        data = response.json()
        print("批量生成完成!")
        print(f"成功生成: {data['generated_count']} 张")
        print(f"失败: {data['failed_count']} 张")
        print(f"总文章数: {data['total_articles']} 篇")
        return data
    else:
        print(f"批量生成失败: {response.text}")
        return None

def main():
    """主测试函数"""
    print("=== 图片生成功能测试 ===\n")
    
    # 1. 登录获取token
    token = test_login()
    if not token:
        print("登录失败，无法继续测试")
        return
    
    # 2. 发布诗篇并自动生成图片
    article_id = test_create_article_with_image(token)
    if not article_id:
        print("发布失败，无法继续测试")
        return
    
    # 等待一下，确保图片生成完成
    time.sleep(2)
    
    # 3. 为现有文章生成图片
    test_generate_image_for_existing_article(token, article_id)
    
    # 4. 生成预览图片
    test_generate_preview(token)
    
    # 5. 批量生成图片
    test_batch_generate(token)
    
    print("\n=== 测试完成 ===")
    print("请检查 uploads 目录中是否生成了图片文件")

if __name__ == "__main__":
    main() 