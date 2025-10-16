from flask import Blueprint, request, jsonify, current_app
from models.supabase_client import supabase_client
import jwt
from functools import wraps

likes_bp = Blueprint('likes', __name__)

def get_user_from_token():
    """从token中获取用户ID（可选）"""
    token = None
    if 'Authorization' in request.headers:
        auth_header = request.headers.get('Authorization')
        if auth_header and isinstance(auth_header, str) and " " in auth_header:
            try:
                token = auth_header.split(" ")[1]
            except IndexError:
                return None
        else:
            return None

    if not token:
        return None

    try:
        payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
        return payload['user_id']
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        return None

def get_client_info():
    """获取客户端信息（设备ID和IP地址）"""
    data = request.get_json() or {}
    device_id = data.get('device_id') or request.headers.get('X-Device-ID')
    ip_address = request.environ.get('HTTP_X_FORWARDED_FOR', request.environ.get('REMOTE_ADDR'))
    
    return device_id, ip_address

@likes_bp.route('/articles/<article_id>/like', methods=['POST'])
def toggle_article_like(article_id):
    """
    切换文章点赞状态
    
    Request Body:
    {
        "action": "like" | "unlike",  # 可选，如果不提供则自动切换
        "device_id": "device_123"     # 匿名用户必须提供
    }
    """
    try:
        # 获取用户信息
        user_id = get_user_from_token()
        device_id, ip_address = get_client_info()
        
        # 验证参数
        if not user_id and not device_id:
            return jsonify({
                'error': '需要提供用户身份信息（登录或设备ID）'
            }), 400
        
        # 执行点赞切换
        result = supabase_client.toggle_article_like(
            article_id=article_id,
            user_id=user_id,
            device_id=device_id,
            ip_address=ip_address
        )
        
        return jsonify(result), 200
        
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': f'点赞操作失败: {str(e)}'}), 500

@likes_bp.route('/articles/<article_id>/likes', methods=['GET'])
def get_article_likes(article_id):
    """
    获取文章点赞信息
    
    Query Parameters:
    - device_id: 设备ID（匿名用户）
    """
    try:
        # 获取用户信息
        user_id = get_user_from_token()
        device_id = request.args.get('device_id')
        
        # 获取点赞信息
        result = supabase_client.get_article_like_info(
            article_id=article_id,
            user_id=user_id,
            device_id=device_id
        )
        
        return jsonify(result), 200
        
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': f'获取点赞信息失败: {str(e)}'}), 500

@likes_bp.route('/articles/likes/batch', methods=['POST'])
def get_batch_article_likes():
    """
    批量获取多篇文章的点赞信息
    
    Request Body:
    {
        "article_ids": ["id1", "id2", "id3"],
        "device_id": "device_123"  # 匿名用户可选提供
    }
    """
    try:
        data = request.get_json()
        if not data or 'article_ids' not in data:
            return jsonify({'error': '缺少article_ids参数'}), 400
        
        article_ids = data['article_ids']
        if not isinstance(article_ids, list) or not article_ids:
            return jsonify({'error': 'article_ids必须是非空列表'}), 400
        
        # 获取用户信息
        user_id = get_user_from_token()
        device_id = data.get('device_id')
        
        # 批量获取点赞信息
        result = supabase_client.get_batch_article_likes(
            article_ids=article_ids,
            user_id=user_id,
            device_id=device_id
        )
        
        return jsonify(result), 200
        
    except Exception as e:
        return jsonify({'error': f'批量获取点赞信息失败: {str(e)}'}), 500

# 统计相关接口（可选）
@likes_bp.route('/articles/<article_id>/likes/stats', methods=['GET'])
def get_article_like_stats(article_id):
    """获取文章点赞统计详情"""
    try:
        # 基本点赞信息
        user_id = get_user_from_token()
        device_id = request.args.get('device_id')
        
        like_info = supabase_client.get_article_like_info(
            article_id=article_id,
            user_id=user_id,
            device_id=device_id
        )
        
        # 可以扩展更多统计信息
        # 比如：最近点赞的用户、点赞趋势等
        
        return jsonify({
            **like_info,
            'stats': {
                'total_likes': like_info['like_count'],
                # 'recent_likes': recent_likes,  # 可选扩展
                # 'like_trend': like_trend      # 可选扩展
            }
        }), 200
        
    except ValueError as e:
        return jsonify({'error': str(e)}), 400
    except Exception as e:
        return jsonify({'error': f'获取点赞统计失败: {str(e)}'}), 500