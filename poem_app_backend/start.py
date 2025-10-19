#!/usr/bin/env python3
"""
诗篇后端快速启动脚本
"""

import os
import sys

def check_python_version():
    """检查Python版本"""
    if sys.version_info < (3, 8):
        return False
    return True

def check_dependencies():
    """检查依赖是否安装"""
    try:
        import flask
        import flask_cors
        import dotenv
        import supabase
        import bcrypt
        import jwt
        from PIL import Image
        return True
    except ImportError as e:
        return False

def check_env_file():
    """检查环境变量文件"""
    if not os.path.exists('.env'):
        return False
    return True

def check_supabase_config():
    """检查Supabase配置"""
    try:
        from config import Config
        config = Config()
        
        if not config.SUPABASE_URL or config.SUPABASE_URL == 'https://xxxx.supabase.co':
            return False
        if not config.SUPABASE_KEY or config.SUPABASE_KEY == 'your_supabase_key':
            return False
            
        return True
    except Exception as e:
        return False

def start_app():
    """启动应用"""
    try:
        # 设置环境变量
        os.environ['FLASK_ENV'] = 'development'
        os.environ['FLASK_DEBUG'] = 'True'
        
        # 启动Flask应用
        from app import create_app
        app = create_app()
        app.run(debug=True, host='0.0.0.0', port=5001)
        
    except Exception as e:
        return False

def main():
    """主函数"""
    checks = [
        check_python_version,
        check_dependencies,
        check_env_file,
        check_supabase_config
    ]
    
    all_passed = True
    for check in checks:
        if not check():
            all_passed = False
    
    if not all_passed:
        return 1
    
    # 询问是否启动
    try:
        response = input("是否现在启动服务? (y/n): ").lower().strip()
        if response in ['y', 'yes', '是']:
            start_app()
    except KeyboardInterrupt:
        pass
    
    return 0

if __name__ == '__main__':
    sys.exit(main()) 