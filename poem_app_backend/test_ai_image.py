#!/usr/bin/env python3
"""
AI图片生成功能测试脚本
"""

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# 加载环境变量
from dotenv import load_dotenv
load_dotenv()

from utils.ai_image_generator import ai_generator

def test_ai_image_generation():
    """测试AI图片生成功能"""
    
    # 测试文章数据
    test_articles = [
        {
            'title': '沁园春·雪',
            'content': '北国风光，千里冰封，万里雪飘。望长城内外，惟余莽莽；大河上下，顿失滔滔。山舞银蛇，原驰蜡象，欲与天公试比高。须晴日，看红装素裹，分外妖娆。',
            'tags': ['自然', '风景', '古风']
        },
        {
            'title': '春夜喜雨',
            'content': '好雨知时节，当春乃发生。随风潜入夜，润物细无声。野径云俱黑，江船火独明。晓看红湿处，花重锦官城。',
            'tags': ['春天', '自然', '情感']
        },
        {
            'title': '静夜思',
            'content': '床前明月光，疑是地上霜。举头望明月，低头思故乡。',
            'tags': ['思乡', '月亮', '情感']
        }
    ]
    
    print("=== AI图片生成功能测试 ===\n")
    
    for i, article in enumerate(test_articles, 1):
        print(f"测试 {i}: {article['title']}")
        print(f"内容: {article['content'][:50]}...")
        print(f"标签: {article['tags']}")
        
        # 生成提示词
        prompt, negative_prompt = ai_generator.generate_prompt_from_poem(
            article['title'], 
            article['content'], 
            article['tags']
        )
        
        print(f"生成提示词: {prompt}")
        print(f"负面提示词: {negative_prompt}")
        
        # 测试图片生成（不保存，只测试API调用）
        print("测试API调用...")
        
        # 测试Stability AI
        if ai_generator.api_key:
            print("✓ Stability AI API Key已配置")
            # 这里可以添加实际的API调用测试
        else:
            print("✗ Stability AI API Key未配置")
        
        # 测试Hugging Face
        if ai_generator.hf_api_key:
            print("✓ Hugging Face API Key已配置")
            # 这里可以添加实际的API调用测试
        else:
            print("✗ Hugging Face API Key未配置")
        
        print("-" * 50)
    
    print("\n=== 配置建议 ===")
    print("1. 注册Stability AI: https://platform.stability.ai/")
    print("2. 注册Hugging Face: https://huggingface.co/")
    print("3. 在.env文件中配置API密钥:")
    print("   STABILITY_API_KEY=your_key_here")
    print("   HF_API_KEY=your_key_here")

if __name__ == "__main__":
    test_ai_image_generation() 