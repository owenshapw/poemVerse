from flask import Flask, send_from_directory, current_app
from flask_cors import CORS
from config import Config
from routes.auth import auth_bp
from routes.articles import articles_bp
from routes.comments import comments_bp
from routes.generate import generate_bp
from routes.likes import likes_bp
from models.supabase_client import supabase_client
from routes.upload import upload_bp
from routes.cloudflare import cloudflare_bp

from dotenv import load_dotenv
load_dotenv()

from builtins import print, Exception, RuntimeError

def create_app():
    app = Flask(__name__)
    app.config.from_object(Config)
    
    # 检查 Supabase 配置
    if not app.config.get('SUPABASE_URL') or not app.config.get('SUPABASE_KEY'):
        raise RuntimeError("Supabase 配置缺失")
    
    # 初始化Supabase客户端
    try:
        supabase_client.init_app(app)
        # 简化连接测试，减少启动时间
        if supabase_client.supabase is None:
            raise RuntimeError("Supabase 客户端初始化后仍为 None")
        
    except Exception as e:
        raise RuntimeError(f"Supabase 初始化失败: {e}")
    
    # 启用CORS - 允许Flutter前端访问
    CORS(app, resources={
        r"/api/*": {
            "origins": ["http://localhost:3000", "http://127.0.0.1:3000", "*"],
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"]
        }
    })

    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(articles_bp, url_prefix='/api')
    app.register_blueprint(comments_bp, url_prefix='/api')
    app.register_blueprint(generate_bp, url_prefix='/api')
    app.register_blueprint(likes_bp, url_prefix='/api')
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
    try:
        app = create_app()
        app.run(host='0.0.0.0', port=8080)
    except Exception as e:
        pass 
