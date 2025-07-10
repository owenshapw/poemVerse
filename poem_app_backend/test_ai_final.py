#!/usr/bin/env python3
"""
最终的AI图片生成测试
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# 加载环境变量
from dotenv import load_dotenv
load_dotenv()

from app import create_app
from utils.ai_image_generator import ai_generator

def test_ai_generation():
    """测试AI图片生成功能"""
    print("=== AI图片生成功能测试 ===\n")
    
    # 创建Flask应用上下文
    app = create_app()
    
    with app.app_context():
        # 测试文章
        test_articles = [
            {
                'title': '静夜思',
                'content': '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
                'tags': ['思乡', '月亮', '情感']
            },
            {
                'title': '春晓',
                'content': '春眠不觉晓，处处闻啼鸟。夜来风雨声，花落知多少。',
                'tags': ['春天', '自然', '风景']
            },
            {
                'title': '登鹳雀楼',
                'content': '白日依山尽，黄河入海流。欲穷千里目，更上一层楼。',
                'tags': ['登高', '风景', '壮志']
            }
        ]
        
        success_count = 0
        total_count = len(test_articles)
        
        for i, article in enumerate(test_articles, 1):
            print(f"测试 {i}/{total_count}: {article['title']}")
            print(f"内容: {article['content']}")
            print(f"标签: {article['tags']}")
            
            try:
                # 生成图片
                image_url = ai_generator.generate_poem_image(article)
                
                if image_url:
                    print(f"✅ 图片生成成功: {image_url}")
                    
                    # 检查文件
                    filepath = os.path.join('uploads', os.path.basename(image_url))
                    if os.path.exists(filepath):
                        file_size = os.path.getsize(filepath)
                        print(f"   文件大小: {file_size} 字节")
                        
                        if file_size > 1000:
                            print("   文件有效")
                            success_count += 1
                        else:
                            print("   警告: 文件太小")
                    else:
                        print(f"   警告: 文件不存在 {filepath}")
                else:
                    print("❌ 图片生成失败")
                    
            except Exception as e:
                print(f"❌ 生成异常: {e}")
            
            print("-" * 50)
        
        print(f"\n=== 测试结果 ===")
        print(f"成功: {success_count}/{total_count}")
        print(f"成功率: {success_count/total_count*100:.1f}%")
        
        if success_count > 0:
            print("✅ AI图片生成功能正常工作！")
        else:
            print("❌ AI图片生成功能需要修复")

def test_prompt_generation():
    """测试提示词生成"""
    print("\n=== 测试提示词生成 ===")
    
    test_article = {
        'title': '静夜思',
        'content': '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
        'tags': ['思乡', '月亮', '情感']
    }
    
    prompt, negative_prompt = ai_generator.generate_prompt_from_poem(
        test_article['title'], 
        test_article['content'], 
        test_article['tags']
    )
    
    print(f"标题: {test_article['title']}")
    print(f"内容: {test_article['content']}")
    print(f"标签: {test_article['tags']}")
    print(f"生成提示词: {prompt}")
    print(f"负面提示词: {negative_prompt}")

if __name__ == "__main__":
    print("=== AI图片生成功能完整测试 ===\n")
    
    # 测试提示词生成
    test_prompt_generation()
    
    # 测试实际生成
    test_ai_generation()
    
    print("\n=== 测试完成 ===") 