#!/usr/bin/env python3
"""
测试脚本：验证诗篇后端项目设置
"""

import os
import sys

def test_imports():
    """测试所有必要的导入"""
    print("🔍 测试导入...")
    
    try:
        import flask
        print("✅ Flask 导入成功")
    except ImportError as e:
        print(f"❌ Flask 导入失败: {e}")
        return False
    
    try:
        import flask_cors
        print("✅ Flask-CORS 导入成功")
    except ImportError as e:
        print(f"❌ Flask-CORS 导入失败: {e}")
        return False
    
    try:
        import dotenv
        print("✅ python-dotenv 导入成功")
    except ImportError as e:
        print(f"❌ python-dotenv 导入失败: {e}")
        return False
    
    try:
        import supabase
        print("✅ Supabase 导入成功")
    except ImportError as e:
        print(f"❌ Supabase 导入失败: {e}")
        return False
    
    try:
        import bcrypt
        print("✅ bcrypt 导入成功")
    except ImportError as e:
        print(f"❌ bcrypt 导入失败: {e}")
        return False
    
    try:
        import jwt
        print("✅ PyJWT 导入成功")
    except ImportError as e:
        print(f"❌ PyJWT 导入失败: {e}")
        return False
    
    try:
        from PIL import Image
        print("✅ Pillow 导入成功")
    except ImportError as e:
        print(f"❌ Pillow 导入失败: {e}")
        return False
    
    return True

def test_project_structure():
    """测试项目结构"""
    print("\n📁 测试项目结构...")
    
    required_files = [
        'app.py',
        'config.py',
        'requirements.txt',
        'Procfile',
        'README.md',
        'routes/auth.py',
        'routes/articles.py',
        'routes/comments.py',
        'routes/generate.py',
        'models/supabase_client.py',
        'utils/mail.py',
        'utils/image_generator.py',
        'templates/article_template.html'
    ]
    
    missing_files = []
    for file_path in required_files:
        if os.path.exists(file_path):
            print(f"✅ {file_path}")
        else:
            print(f"❌ {file_path} - 文件不存在")
            missing_files.append(file_path)
    
    if missing_files:
        print(f"\n⚠️  缺少 {len(missing_files)} 个文件")
        return False
    else:
        print("\n✅ 所有必需文件都存在")
        return True

def test_config():
    """测试配置"""
    print("\n⚙️  测试配置...")
    
    try:
        from config import Config
        print("✅ 配置类导入成功")
        
        # 检查必要的配置项
        config = Config()
        required_configs = [
            'SECRET_KEY',
            'SUPABASE_URL',
            'SUPABASE_KEY',
            'EMAIL_USERNAME',
            'EMAIL_PASSWORD'
        ]
        
        for config_name in required_configs:
            value = getattr(config, config_name, None)
            if value is None:
                print(f"⚠️  {config_name} 未设置（使用环境变量）")
            else:
                print(f"✅ {config_name} 已设置")
        
        return True
        
    except Exception as e:
        print(f"❌ 配置测试失败: {e}")
        return False

def test_app_creation():
    """测试应用创建"""
    print("\n🚀 测试应用创建...")
    
    try:
        from app import create_app
        app = create_app()
        print("✅ Flask应用创建成功")
        
        # 测试路由注册
        routes = []
        for rule in app.url_map.iter_rules():
            routes.append(rule.rule)
        
        expected_routes = [
            '/',
            '/health',
            '/api/register',
            '/api/login',
            '/api/forgot-password',
            '/api/reset-password',
            '/api/articles',
            '/api/my-articles',
            '/api/articles/search',
            '/api/comments',
            '/api/generate',
            '/api/generate/batch',
            '/api/generate/preview'
        ]
        
        print(f"📋 注册的路由数量: {len(routes)}")
        for route in routes:
            print(f"  - {route}")
        
        return True
        
    except Exception as e:
        print(f"❌ 应用创建失败: {e}")
        return False

def main():
    """主测试函数"""
    print("🎯 诗篇后端项目测试开始\n")
    
    tests = [
        test_imports,
        test_project_structure,
        test_config,
        test_app_creation
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
        except Exception as e:
            print(f"❌ 测试异常: {e}")
    
    print(f"\n📊 测试结果: {passed}/{total} 通过")
    
    if passed == total:
        print("🎉 所有测试通过！项目设置正确。")
        print("\n📝 下一步:")
        print("1. 配置 .env 文件")
        print("2. 设置 Supabase 数据库")
        print("3. 运行: python app.py")
        return 0
    else:
        print("⚠️  部分测试失败，请检查项目设置。")
        return 1

if __name__ == '__main__':
    sys.exit(main()) 