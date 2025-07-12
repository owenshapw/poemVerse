from flask import Flask, send_from_directory, current_app
from flask_cors import CORS
from config import Config
from routes.auth import auth_bp
from routes.articles import articles_bp
from routes.comments import comments_bp
from routes.generate import generate_bp
from models.supabase_client import supabase_client
from routes.upload import upload_bp
from routes.cloudflare import cloudflare_bp
import os

from dotenv import load_dotenv
load_dotenv()

# 启动时打印环境变量，便于排查
print("SUPABASE_URL:", os.environ.get("SUPABASE_URL"))
print("SUPABASE_KEY:", os.environ.get("SUPABASE_KEY"))

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # 初始化Supabase客户端
    supabase_client.init_app(app)
    
    # 启用CORS - 允许Flutter前端访问
    CORS(app, resources={
        r"/api/*": {
            "origins": ["http://localhost:3000", "http://127.0.0.1:3000", "*"],
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })
    
    # 注册蓝图
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(articles_bp, url_prefix='/api')
    app.register_blueprint(comments_bp, url_prefix='/api')
    app.register_blueprint(generate_bp, url_prefix='/api')
    app.register_blueprint(upload_bp)
    app.register_blueprint(cloudflare_bp)
    
    @app.route('/')
    def index():
        return {'message': '诗篇 API 服务运行中', 'status': 'success'}
    
    @app.route('/health')
    def health():
        return {'status': 'healthy'}
    
    @app.route('/uploads/<filename>')
    def uploaded_file(filename):
        """提供上传文件的访问"""
        return send_from_directory(current_app.config['UPLOAD_FOLDER'], filename)
    
    return app

if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=8080) 