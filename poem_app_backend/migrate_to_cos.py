#!/usr/bin/env python3
"""
从 Supabase 迁移图片到腾讯云 COS 的脚本
"""

import os
import requests
from models.supabase_client import supabase_client
from utils.cos_client import cos_client
from config import Config
from flask import Flask

def migrate_images():
    """迁移所有图片从 Supabase 到腾讯云 COS"""
    
    # 初始化 Flask 应用
    app = Flask(__name__)
    app.config.from_object(Config())
    
    with app.app_context():
        # 初始化 Supabase 客户端
        supabase_client.init_app(app)
        
        if not supabase_client.supabase:
            print("❌ Supabase 客户端初始化失败")
            return
        
        if not cos_client.is_available():
            print("❌ 腾讯云 COS 客户端初始化失败")
            return
        
        print("✅ 开始迁移图片...")
        
        # 获取所有文章
        try:
            articles = supabase_client.supabase.table('articles').select('*').execute().data
            print(f"📄 找到 {len(articles)} 篇文章")
        except Exception as e:
            print(f"❌ 获取文章失败: {e}")
            return
        
        migrated_count = 0
        failed_count = 0
        
        for article in articles:
            try:
                image_url = article.get('image_url')
                if not image_url:
                    print(f"⏭️  文章《{article['title']}》没有图片，跳过")
                    continue
                
                print(f"🔄 迁移文章《{article['title']}》的图片: {image_url}")
                
                # 下载图片
                response = requests.get(image_url, timeout=30)
                if response.status_code != 200:
                    print(f"❌ 下载图片失败: {response.status_code}")
                    failed_count += 1
                    continue
                
                # 生成新文件名
                filename = f"migrated_{article['id']}.png"
                
                # 上传到腾讯云 COS
                new_url = cos_client.upload_file(
                    response.content,
                    filename,
                    'image/png'
                )
                
                if new_url:
                    # 更新数据库中的图片 URL
                    supabase_client.supabase.table('articles').update({
                        'image_url': new_url
                    }).eq('id', article['id']).execute()
                    
                    print(f"✅ 迁移成功: {new_url}")
                    migrated_count += 1
                else:
                    print(f"❌ 上传到 COS 失败")
                    failed_count += 1
                    
            except Exception as e:
                print(f"❌ 迁移文章《{article['title']}》失败: {e}")
                failed_count += 1
        
        print(f"\n📊 迁移完成:")
        print(f"✅ 成功: {migrated_count}")
        print(f"❌ 失败: {failed_count}")
        print(f"📄 总计: {len(articles)}")

if __name__ == '__main__':
    migrate_images() 