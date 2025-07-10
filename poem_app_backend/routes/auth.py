from flask import Blueprint, request, jsonify, current_app
from models.supabase_client import supabase_client
import bcrypt
import jwt
from datetime import datetime, timedelta
from utils.mail import send_email

auth_bp = Blueprint('auth', __name__)

def generate_token(user_id: str):
    """生成JWT token"""
    payload = {
        'user_id': user_id,
        'exp': datetime.utcnow() + timedelta(days=7)
    }
    return jwt.encode(payload, current_app.config['SECRET_KEY'], algorithm='HS256')

@auth_bp.route('/register', methods=['POST'])
def register():
    """用户注册"""
    try:
        data = request.get_json()
        print(f"Received registration data: {data}")
        email = data.get('email')
        password = data.get('password')
        username = data.get('username', email.split('@')[0])  # 如果没有username，使用邮箱前缀
        
        print(f"Processing registration for email: {email}, username: {username}")
        
        if not email or not password:
            return jsonify({'error': '邮箱和密码不能为空'}), 400
        
        # 检查邮箱是否已存在
        print("Checking if user exists...")
        existing_user = supabase_client.get_user_by_email(email)
        if existing_user:
            print(f"User already exists: {existing_user['email']}")
            return jsonify({'error': '该邮箱已被注册'}), 400
        
        # 创建新用户
        print("Creating new user...")
        user = supabase_client.create_user(email, password, username)
        if not user:
            print("Failed to create user")
            return jsonify({'error': '用户创建失败'}), 500
        
        print(f"User created successfully: {user['id']}")
        
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
        print(f"Registration error: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500

@auth_bp.route('/login', methods=['POST'])
def login():
    """用户登录"""
    try:
        data = request.get_json()
        print(f"Login request data: {data}")
        email = data.get('email')
        password = data.get('password')
        
        print(f"Attempting login for email: {email}")
        
        if not email or not password:
            return jsonify({'error': '邮箱和密码不能为空'}), 400
        
        # 获取用户
        print("Looking up user...")
        user = supabase_client.get_user_by_email(email)
        if not user:
            print(f"User not found for email: {email}")
            return jsonify({'error': '用户不存在'}), 404
        
        print(f"User found: {user['id']}")
        
        # 验证密码
        print("Verifying password...")
        if not bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
            print("Password verification failed")
            return jsonify({'error': '密码错误'}), 401
        
        print("Password verified successfully")
        
        # 生成token
        token = generate_token(user['id'])
        
        return jsonify({
            'message': '登录成功',
            'token': token,
            'user': {
                'id': user['id'],
                'email': user['email'],
                'username': user.get('username', '')
            }
        }), 200
        
    except Exception as e:
        print(f"Login error: {str(e)}")
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
        
        # 发送重置邮件
        reset_url = f"https://your-frontend-domain.com/reset-password?token={reset_token}"
        subject = "诗篇 - 密码重置"
        body = f"""
        您好，
        
        您请求重置密码。请点击以下链接重置密码：
        
        {reset_url}
        
        此链接将在1小时后失效。
        
        如果这不是您的操作，请忽略此邮件。
        
        诗篇团队
        """
        
        send_email(email, subject, body)
        
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
            payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
            user_id = payload['user_id']
        except jwt.ExpiredSignatureError:
            return jsonify({'error': '重置链接已过期'}), 400
        except jwt.InvalidTokenError:
            return jsonify({'error': '无效的重置链接'}), 400
        
        # 更新密码
        password_hash = bcrypt.hashpw(new_password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')
        result = supabase_client.supabase.table('users').update({'password_hash': password_hash}).eq('id', user_id).execute()
        
        if not result.data:
            return jsonify({'error': '密码更新失败'}), 500
        
        return jsonify({'message': '密码重置成功'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500 