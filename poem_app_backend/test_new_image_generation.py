#!/usr/bin/env python3
"""
测试新的图片生成功能
展示改进后的排版效果
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from flask import Flask
from utils.image_generator import generate_article_image

def test_new_image_generation():
    """测试新的图片生成功能"""
    print("=== 测试新的图片生成功能 ===\n")
    
    # 创建Flask应用上下文
    app = Flask(__name__)
    app.config['UPLOAD_FOLDER'] = 'uploads'
    app.config['IMAGE_WIDTH'] = 1200
    app.config['IMAGE_HEIGHT'] = 1600
    
    with app.app_context():
        # 测试不同的诗词内容
        test_articles = [
            {
                'title': '静夜思',
                'content': '床前明月光，\n疑是地上霜。\n举头望明月，\n低头思故乡。',
                'author': '李白',
                'tags': ['思乡', '月亮', '唐诗']
            },
            {
                'title': '春晓',
                'content': '春眠不觉晓，\n处处闻啼鸟。\n夜来风雨声，\n花落知多少。',
                'author': '孟浩然',
                'tags': ['春天', '自然', '唐诗']
            },
            {
                'title': '登鹳雀楼',
                'content': '白日依山尽，\n黄河入海流。\n欲穷千里目，\n更上一层楼。',
                'author': '王之涣',
                'tags': ['登高', '壮美', '唐诗']
            }
        ]
        
        for i, article in enumerate(test_articles, 1):
            print(f"生成第{i}首诗的图片: {article['title']}")
            
            # 生成图片
            image_url = generate_article_image(article, is_preview=True)
            
            if image_url:
                print(f"✅ 图片生成成功: {image_url}")
                
                # 检查文件是否存在
                filename = image_url.split('/')[-1]
                filepath = os.path.join('uploads', filename)
                if os.path.exists(filepath):
                    file_size = os.path.getsize(filepath)
                    print(f"   文件大小: {file_size} 字节")
                else:
                    print("   ❌ 文件不存在")
            else:
                print("   ❌ 图片生成失败")
            
            print()
    
    print("=== 测试完成 ===")
    print("\n改进内容:")
    print("1. 图片尺寸: 1200x1600 (更大更清晰)")
    print("2. 字体大小: 标题72px, 内容48px, 作者36px")
    print("3. 中文文本处理: 按字符分割，每行最多15个字符")
    print("4. 优雅排版: 双边框、背景色、装饰元素")
    print("5. 行高增加: 80px，更易阅读")
    print("6. 古典风格: 米色背景、优雅配色")

if __name__ == "__main__":
    test_new_image_generation() 