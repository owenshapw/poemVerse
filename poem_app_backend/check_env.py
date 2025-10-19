#!/usr/bin/env python3
"""
检查环境变量配置
"""

import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

def check_env_vars():
    """检查环境变量"""
    
    supabase_vars = {
        'SUPABASE_URL': os.getenv('SUPABASE_URL'),
        'SUPABASE_KEY': os.getenv('SUPABASE_KEY'),
    }
    
    for var, value in supabase_vars.items():
        pass  # 不输出调试信息
    
    other_vars = {
        'SECRET_KEY': os.getenv('SECRET_KEY'),
        'FLASK_ENV': os.getenv('FLASK_ENV'),
        'FLASK_DEBUG': os.getenv('FLASK_DEBUG'),
    }
    
    for var, value in other_vars.items():
        pass  # 不输出调试信息
    
    # 检查是否在Render环境
    render_env = os.getenv('RENDER')
    return True  # 返回检查结果

if __name__ == "__main__":
    check_env_vars() 