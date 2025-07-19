from flask import Blueprint, request, jsonify, current_app
from models.supabase_client import supabase_client
import bcrypt
import jwt
from datetime import datetime, timedelta
from utils.mail import send_email
import builtins

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

        # 发送重置邮件
        reset_url = f"poemverse://reset-password?token={reset_token}"
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
