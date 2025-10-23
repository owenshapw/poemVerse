from flask import Flask, send_from_directory, current_app, render_template, request, jsonify
import jwt
from datetime import datetime
from flask_cors import CORS
from config import Config
from routes.auth import auth_bp
from routes.articles import articles_bp
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
    
    # 启用CORS - 允许前端访问
    CORS(app, resources={
        r"/api/*": {
            "origins": ["*"],
            "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
            "allow_headers": ["Content-Type", "Authorization"],
            "supports_credentials": True
        }
    })

    # 注册认证路由
    app.register_blueprint(auth_bp, url_prefix='/api/auth')
    app.register_blueprint(articles_bp, url_prefix='/api')
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
    
    @app.route('/.well-known/apple-app-site-association')
    def apple_app_site_association():
        """提供iOS Universal Links验证文件"""
        return send_from_directory('static', 'apple-app-site-association', mimetype='application/json')
    
    @app.route('/.well-known/assetlinks.json')
    def assetlinks():
        """提供Android App Links验证文件"""
        return send_from_directory('static', 'assetlinks.json', mimetype='application/json')
    
    @app.route('/reset-password', methods=['GET'])
    def reset_password_page():
        """显示重置密码页面（Universal Links入口）"""
        try:
            token = request.args.get('token')
            
            # 调试信息
            print(f"Reset password page accessed")
            print(f"Full URL: {request.url}")
            print(f"Query args: {request.args}")
            print(f"Token received: {'Yes' if token else 'No'}")
            if token:
                print(f"Token length: {len(token)}")
                print(f"Token preview: {token[:20]}...")
            
            if not token:
                return render_template('reset-password.html', 
                                     error=f'缺少重置令牌。请求URL: {request.url}'), 400
            
            # 验证token是否有效
            try:
                jwt.decode(
                    token,
                    current_app.config['SECRET_KEY'],
                    algorithms=['HS256']
                )
                # Token有效，显示重置页面
                return render_template('reset-password.html', token=token)
            except jwt.ExpiredSignatureError:
                return render_template('reset-password.html', 
                                     error='重置链接已过期，请重新申请密码重置。'), 400
            except jwt.InvalidTokenError:
                return render_template('reset-password.html', 
                                     error='无效的重置链接，请重新申请密码重置。'), 400
                
        except Exception as e:
            print(f"Error in reset password page: {str(e)}")
            return render_template('reset-password.html', 
                                 error=f'系统错误：{str(e)}'), 500
    
    @app.route('/test-reset', methods=['GET'])
    def test_reset_page():
        """测试重置页面显示（用于调试）"""
        test_token = "test-token-12345"
        return render_template('reset-password.html', token=test_token)
    
    @app.route('/debug/routes', methods=['GET'])
    def list_routes():
        """显示所有可用路由（调试用）"""
        routes = []
        for rule in app.url_map.iter_rules():
            methods = ','.join(rule.methods - {'HEAD', 'OPTIONS'})
            routes.append(f"{methods} {rule.rule}")
        return '<br>'.join(sorted(routes))
    
    @app.errorhandler(405)
    def method_not_allowed(error):
        """处理405错误"""
        print(f"405 Error: {request.method} {request.path}")
        print(f"Available methods for this endpoint: {error.description}")
        return jsonify({
            'error': 'Method Not Allowed',
            'method': request.method,
            'path': request.path,
            'message': '请求的HTTP方法不被允许'
        }), 405
    
    return app

if __name__ == '__main__':
    try:
        app = create_app()
        app.run(host='0.0.0.0', port=8080)
    except Exception as e:
        pass 
