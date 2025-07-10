from flask import Blueprint, request, jsonify, current_app
from models.supabase_client import supabase_client
import jwt
from functools import wraps

comments_bp = Blueprint('comments', __name__)

def token_required(f):
    """JWT token验证装饰器"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # 从请求头获取token
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            try:
                token = auth_header.split(" ")[1]
            except IndexError:
                return jsonify({'error': '无效的token格式'}), 401
        
        if not token:
            return jsonify({'error': '缺少认证token'}), 401
        
        try:
            # 验证token
            payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
            current_user_id = payload['user_id']
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'token已过期'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': '无效的token'}), 401
        
        return f(current_user_id, *args, **kwargs)
    
    return decorated

@comments_bp.route('/comments', methods=['POST'])
@token_required
def create_comment(current_user_id):
    """发表评论"""
    try:
        data = request.get_json()
        article_id = data.get('article_id')
        content = data.get('content')
        
        if not article_id or not content:
            return jsonify({'error': '文章ID和评论内容不能为空'}), 400
        
        # 检查文章是否存在
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        
        # 创建评论
        comment = supabase_client.create_comment(article_id, current_user_id, content)
        if not comment:
            return jsonify({'error': '评论创建失败'}), 500
        
        # 获取评论者信息
        comment_author = supabase_client.get_user_by_id(current_user_id)
        
        return jsonify({
            'message': '评论发表成功',
            'comment': {
                'id': comment['id'],
                'content': comment['content'],
                'author_email': comment_author['email'] if comment_author else '',
                'created_at': comment['created_at']
            }
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@comments_bp.route('/articles/<article_id>/comments', methods=['GET'])
def get_article_comments(article_id):
    """获取文章的所有评论"""
    try:
        # 检查文章是否存在
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        
        # 获取评论
        comments = supabase_client.get_comments_by_article(article_id)
        
        # 格式化评论数据
        formatted_comments = []
        for comment in comments:
            comment_author = supabase_client.get_user_by_id(comment['user_id'])
            formatted_comments.append({
                'id': comment['id'],
                'content': comment['content'],
                'author_email': comment_author['email'] if comment_author else '',
                'created_at': comment['created_at']
            })
        
        return jsonify({
            'comments': formatted_comments,
            'total': len(formatted_comments)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@comments_bp.route('/comments/<comment_id>', methods=['DELETE'])
@token_required
def delete_comment(current_user_id, comment_id):
    """删除评论（仅评论者可删除）"""
    try:
        # 获取评论信息
        result = supabase_client.supabase.table('comments').select('*').eq('id', comment_id).execute()
        if not result.data:
            return jsonify({'error': '评论不存在'}), 404
        
        comment = result.data[0]
        
        # 检查是否为评论者
        if comment['user_id'] != current_user_id:
            return jsonify({'error': '无权限删除此评论'}), 403
        
        # 删除评论
        delete_result = supabase_client.supabase.table('comments').delete().eq('id', comment_id).execute()
        
        if not delete_result.data:
            return jsonify({'error': '删除失败'}), 500
        
        return jsonify({'message': '评论删除成功'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500 