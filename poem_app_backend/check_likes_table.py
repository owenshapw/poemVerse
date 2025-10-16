#!/usr/bin/env python3
"""
检查Supabase数据库中是否已经创建了点赞相关的表
"""

import os
from dotenv import load_dotenv
from models.supabase_client import supabase_client

load_dotenv()

class Config:
    SUPABASE_URL = os.environ.get('SUPABASE_URL')
    SUPABASE_KEY = os.environ.get('SUPABASE_KEY')

def check_tables():
    """检查数据库表结构"""
    
    # 模拟Flask app配置
    class MockApp:
        def __init__(self):
            self.config = {
                'SUPABASE_URL': Config.SUPABASE_URL,
                'SUPABASE_KEY': Config.SUPABASE_KEY
            }
    
    app = MockApp()
    
    try:
        # 初始化Supabase客户端
        supabase_client.init_app(app)
        
        print("🔍 检查数据库表结构...")
        
        # 1. 检查article_likes表是否存在
        print("1. 检查article_likes表...")
        try:
            result = supabase_client.supabase.table('article_likes').select('*').limit(1).execute()
            print(f"✅ article_likes表存在，当前记录数: {len(result.data)}")
        except Exception as e:
            print(f"❌ article_likes表不存在或有问题: {e}")
            return False
        
        # 2. 检查articles表是否有like_count字段
        print("2. 检查articles表的like_count字段...")
        try:
            result = supabase_client.supabase.table('articles').select('id, like_count').limit(1).execute()
            if result.data and len(result.data) > 0:
                if 'like_count' in result.data[0]:
                    print(f"✅ articles表有like_count字段")
                else:
                    print(f"❌ articles表缺少like_count字段")
                    return False
            else:
                print("ℹ️  articles表为空，无法验证字段")
        except Exception as e:
            print(f"❌ 检查articles表字段失败: {e}")
            return False
        
        # 3. 测试插入和删除一条点赞记录（验证触发器）
        print("3. 测试触发器功能...")
        try:
            # 获取第一篇文章ID用于测试
            articles_result = supabase_client.supabase.table('articles').select('id').limit(1).execute()
            if not articles_result.data:
                print("❌ 没有文章可以测试")
                return False
                
            test_article_id = articles_result.data[0]['id']
            
            # 获取当前点赞数
            before_result = supabase_client.supabase.table('articles').select('like_count').eq('id', test_article_id).execute()
            before_count = before_result.data[0]['like_count'] if before_result.data else 0
            
            # 插入测试点赞记录
            test_like_data = {
                'article_id': test_article_id,
                'device_id': 'test_check_device',
                'is_liked': True
            }
            
            like_result = supabase_client.supabase.table('article_likes').insert(test_like_data).execute()
            
            if like_result.data:
                # 检查点赞数是否增加
                after_result = supabase_client.supabase.table('articles').select('like_count').eq('id', test_article_id).execute()
                after_count = after_result.data[0]['like_count'] if after_result.data else 0
                
                if after_count == before_count + 1:
                    print("✅ 触发器工作正常")
                    
                    # 删除测试记录
                    supabase_client.supabase.table('article_likes').delete().eq('device_id', 'test_check_device').execute()
                    print("🧹 清理测试数据完成")
                    return True
                else:
                    print(f"❌ 触发器未工作 - 点赞前: {before_count}, 点赞后: {after_count}")
                    # 清理测试记录
                    supabase_client.supabase.table('article_likes').delete().eq('device_id', 'test_check_device').execute()
                    return False
            else:
                print("❌ 无法插入测试点赞记录")
                return False
                
        except Exception as e:
            print(f"❌ 测试触发器失败: {e}")
            # 尝试清理可能的测试记录
            try:
                supabase_client.supabase.table('article_likes').delete().eq('device_id', 'test_check_device').execute()
            except:
                pass
            return False
        
    except Exception as e:
        print(f"❌ 数据库连接失败: {e}")
        return False

def main():
    print("🔍 检查点赞系统数据库结构...")
    
    if not Config.SUPABASE_URL or not Config.SUPABASE_KEY:
        print("❌ 缺少Supabase配置环境变量")
        return
    
    if check_tables():
        print("\n🎉 数据库结构检查通过！点赞系统可以正常工作。")
    else:
        print("\n❌ 数据库结构有问题，请执行以下步骤：")
        print("1. 在Supabase控制台执行 database_migrations/create_likes_tables.sql")
        print("2. 确保所有表和触发器都创建成功")
        print("3. 重新运行此检查脚本")

if __name__ == '__main__':
    main()