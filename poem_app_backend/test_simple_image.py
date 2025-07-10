#!/usr/bin/env python3
"""
简单的图片生成测试
确保文字能正确显示
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from flask import Flask
from utils.image_generator import generate_article_image

def test_simple_image():
    """测试简单图片生成"""
    print("=== 简单图片生成测试 ===\n")
    
    # 创建Flask应用上下文
    app = Flask(__name__)
    app.config['UPLOAD_FOLDER'] = 'uploads'
    app.config['IMAGE_WIDTH'] = 1200
    app.config['IMAGE_HEIGHT'] = 1600
    
    with app.app_context():
        # 测试简单的文章
        test_article = {
            'title': '测试标题',
            'content': '这是第一行内容\n这是第二行内容\n这是第三行内容',
            'author': '测试作者',
            'tags': ['测试', '示例']
        }
        
        print("生成测试图片...")
        print(f"标题: {test_article['title']}")
        print(f"内容: {test_article['content']}")
        print(f"作者: {test_article['author']}")
        print(f"标签: {test_article['tags']}")
        
        # 生成图片
        image_url = generate_article_image(test_article, is_preview=True)
        
        if image_url:
            print(f"\n✅ 图片生成成功: {image_url}")
            
            # 检查文件是否存在
            filename = image_url.split('/')[-1]
            filepath = os.path.join('uploads', filename)
            if os.path.exists(filepath):
                file_size = os.path.getsize(filepath)
                print(f"文件大小: {file_size} 字节")
                print(f"文件路径: {filepath}")
                
                # 检查文件是否为空
                if file_size > 1000:
                    print("✅ 文件大小正常，应该包含内容")
                else:
                    print("⚠️ 文件可能为空或太小")
            else:
                print("❌ 文件不存在")
        else:
            print("❌ 图片生成失败")
    
    print("\n=== 测试完成 ===")

if __name__ == "__main__":
    test_simple_image() 