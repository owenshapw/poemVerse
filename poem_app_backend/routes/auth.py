from flask import Blueprint, request, jsonify, current_app, render_template
from models.supabase_client import supabase_client
import bcrypt
import jwt
from datetime import datetime, timedelta
from utils.mail import send_email
from builtins import str, getattr, Exception

auth_bp = Blueprint('auth', __name__)


def generate_token(user_id: str):
    """生成JWT token"""
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(days=7)
    }
    return jwt.encode(
        payload,
        current_app.config['SECRET_KEY'],
        algorithm='HS256')


@auth_bp.route('/register', methods=['POST'])
def register():
    """用户注册（Supabase Auth + users表 + public.users表）"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')
        username = data.get('username', email.split('@')[0])  # 如果没有username，使用邮箱前缀

        if not email or not password:
            return jsonify({'error': '邮箱和密码不能为空'}), 400
        # 检查邮箱是否已存在
        existing_user = supabase_client.get_user_by_email(email)
        if existing_user:
            return jsonify({'error': '该邮箱已被注册'}), 400
        # 只允许新注册流程
        user = supabase_client.register_with_supabase_auth(email, password, username)
        if not user:
            return jsonify({'error': '用户创建失败'}), 500
        # 生成token
        token = generate_token(user['id'])
        return jsonify({
            'message': '注册成功',
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'username': user.get('username', '')
            }
        }), 201
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    """用户登录（Supabase Auth）"""
    try:
        data = request.get_json()
        email = data.get('email')
        password = data.get('password')

        if not email or not password:
            return jsonify({'error': '邮箱和密码不能为空'}), 400

        # 用Supabase Auth校验邮箱和密码
        auth_result = supabase_client.supabase.auth.sign_in_with_password({
            "email": email,
            "password": password
        })
        if not auth_result or not getattr(auth_result, 'user', None):
            return jsonify({'error': '邮箱或密码错误'}), 401
        user_id = auth_result.user.id
        user_email = auth_result.user.email
        # 从自建users表查更多信息
        user_info = supabase_client.get_user_by_id(user_id)
        # 生成token
        token = generate_token(user_id)
        return jsonify({
            'message': '登录成功',
            'token': token,
            'user': {
                'id': user_id,
                'email': user_email,
                'username': user_info.get('username', '') if user_info else ''
            }
        }), 200
    except Exception as e:
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/forgot-password', methods=['POST'])
def forgot_password():
    """忘记密码"""
    try:
        data = request.get_json()
        email = data.get('email')

        if not email:
            return jsonify({'error': '邮箱不能为空'}), 400

        # 检查用户是否存在
        user = supabase_client.get_user_by_email(email)
        if not user:
            return jsonify({'error': '用户不存在'}), 404

        # 生成重置token
        reset_token = jwt.encode(
            {
                'user_id': user['id'],
                'exp': datetime.utcnow() + timedelta(hours=1)
            },
            current_app.config['SECRET_KEY'],
            algorithm='HS256'
        )

        # 获取当前域名（用于生成重置链接）
        # 优先使用环境变量，否则使用request的host
        base_url = current_app.config.get('BASE_URL')
        if not base_url:
            base_url = request.host_url.rstrip('/')
        
        # 发送重置邮件 - 使用Universal Links格式
        reset_url = f"{base_url}/reset-password?token={reset_token}"
        subject = "诗篇 - 密码重置"
        
        # HTML邮件模板
        html_body = f"""
        <!DOCTYPE html>
        <html>
        <body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 40px; text-align: center; color: white; border-radius: 10px 10px 0 0;">
                <h1 style="margin: 0; font-size: 28px;">📝 诗篇</h1>
                <h2 style="margin: 10px 0 0; font-weight: normal;">重置密码</h2>
            </div>
            
            <div style="padding: 40px 20px; border: 1px solid #e1e5e9; border-top: none; border-radius: 0 0 10px 10px;">
                <p>您好，</p>
                <p>我们收到了您的密码重置请求。点击下面的按钮重置您的密码：</p>
                
                <div style="text-align: center; margin: 30px 0;">
                    <a href="{reset_url}" 
                       style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); 
                              color: white; 
                              padding: 15px 30px; 
                              text-decoration: none; 
                              border-radius: 25px; 
                              font-weight: bold; 
                              font-size: 16px;
                              display: inline-block;">
                        🔑 重置密码
                    </a>
                </div>
                
                <p style="font-size: 14px; color: #666;">如果按钮无法点击，请复制以下链接到浏览器：<br>
                <code style="background: #f8f9fa; padding: 5px; border-radius: 3px; font-size: 12px; word-break: break-all;">{reset_url}</code></p>
                
                <p style="font-size: 12px; color: #999; margin-top: 20px;">此链接将在1小时后失效。如果您没有申请密码重置，请忽略此邮件。</p>
                
                <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
                
                <div style="text-align: center;">
                    <p style="font-size: 12px; color: #666;">下载诗篇应用获得更好体验：</p>
                    <a href="https://apps.apple.com/app/poemverse" style="margin: 0 10px; color: #667eea; font-size: 12px;">App Store</a>
                    <a href="https://play.google.com/store/apps/details?id=com.owensha.poemverse" style="margin: 0 10px; color: #667eea; font-size: 12px;">Google Play</a>
                </div>
            </div>
            
            <div style="text-align: center; padding: 20px; font-size: 11px; color: #999;">
                © 2024 诗篇 PoemVerse. All rights reserved.
            </div>
        </body>
        </html>
        """
        
        # 纯文本备用版本
        text_body = f"""
        您好，

        您请求重置密码。请访问以下链接重置密码：

        {reset_url}

        此链接将在1小时后失效。

        如果这不是您的操作，请忽略此邮件。

        诗篇团队
        """

        # 发送HTML邮件
        send_email(email, subject, text_body, html_body)

        return jsonify({'message': '重置密码邮件已发送'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    """重置密码"""
    try:
        data = request.get_json()
        token = data.get('token')
        new_password = data.get('new_password')

        if not token or not new_password:
            return jsonify({'error': 'token和新密码不能为空'}), 400

        # 验证token
        try:
            payload = jwt.decode(
                token,
                current_app.config['SECRET_KEY'],
                algorithms=['HS256'])
            user_id = payload['user_id']
        except jwt.ExpiredSignatureError:
            return jsonify({'error': '重置链接已过期'}), 400
        except jwt.InvalidTokenError:
            return jsonify({'error': '无效的重置链接'}), 400

        # 更新密码
        password_hash = bcrypt.hashpw(
            new_password.encode('utf-8'),
            bcrypt.gensalt()).decode('utf-8')
        if not supabase_client.supabase:
            return jsonify({'error': 'Supabase client 未初始化'}), 500
        result = supabase_client.supabase.table('users').update(
            {'password_hash': password_hash}).eq('id', user_id).execute()

        if not getattr(result, 'data', None):
            return jsonify({'error': '密码更新失败'}), 500
        return jsonify({'message': '密码重置成功'}), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@auth_bp.route('/reset-password', methods=['GET'])
def reset_password_page():
    """显示重置密码页面"""
    try:
        token = request.args.get('token')
        
        if not token:
            return render_template('reset-password.html', 
                                 error='缺少重置令牌，请重新申请密码重置。'), 400
        
        # 验证token是否有效（可选，也可以在提交时验证）
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
        return render_template('reset-password.html', 
                             error=f'系统错误：{str(e)}'), 500
