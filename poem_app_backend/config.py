import os
from dotenv import load_dotenv

# 加载环境变量
load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    
    # Supabase配置
    SUPABASE_URL = os.environ.get('SUPABASE_URL')
    SUPABASE_KEY = os.environ.get('SUPABASE_KEY')  # anon key
    SUPABASE_SERVICE_KEY = os.environ.get('SUPABASE_SERVICE_KEY')  # service role key（用于绕过RLS）
    
    # 邮件配置
    EMAIL_USERNAME = os.environ.get('EMAIL_USERNAME')
    EMAIL_PASSWORD = os.environ.get('EMAIL_PASSWORD')
    EMAIL_SERVER = 'smtp.gmail.com'
    EMAIL_PORT = 587
    
    # 文件上传配置
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
    UPLOAD_FOLDER = 'uploads'
    
    # 图片生成配置
    IMAGE_WIDTH = 800
    IMAGE_HEIGHT = 1200 
    
    # Universal Links 配置
    BASE_URL = os.environ.get('BASE_URL')  # 例如: https://your-domain.com 
