import os
from dotenv import load_dotenv

# 自动检测 .env 文件，不存在则从 env_example.txt 复制
if not os.path.exists('.env') and os.path.exists('env_example.txt'):
    import shutil
    shutil.copy('env_example.txt', '.env')

load_dotenv()

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'dev-secret-key-change-in-production'
    
    # Supabase配置
    SUPABASE_URL = os.environ.get('SUPABASE_URL')
    SUPABASE_KEY = os.environ.get('SUPABASE_KEY')
    
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