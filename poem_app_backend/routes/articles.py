from flask import Blueprint, request, jsonify, current_app
from models.supabase_client import supabase_client
from utils.ai_image_generator import ai_generator
import jwt
from functools import wraps
from datetime import datetime, timedelta

articles_bp = Blueprint('articles', __name__)

def token_required(f):
    """JWT token验证装饰器"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        if 'Authorization' in request.headers:
            auth_header = request.headers.get('Authorization')
            if auth_header and isinstance(auth_header, str) and " " in auth_header:
                try:
                    token = auth_header.split(" ")[1]
                except IndexError:
                    return jsonify({'error': '无效的token格式'}), 401
            else:
                token = None

        if not token:
            return jsonify({'error': '缺少认证token'}), 401

        try:
            payload = jwt.decode(token, current_app.config['SECRET_KEY'], algorithms=['HS256'])
            kwargs['current_user_id'] = payload['user_id']
        except jwt.ExpiredSignatureError:
            return jsonify({'error': 'token已过期'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'error': '无效的token'}), 401

        return f(*args, **kwargs)
    return decorated

@articles_bp.route('/articles/home', methods=['GET'])
def get_home_articles():
    """获取首页文章数据"""
    try:
        recent_articles = supabase_client.get_recent_articles(limit=10)
        return jsonify({'recent_articles': recent_articles}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/grouped/by-author-count', methods=['GET'])
def get_articles_by_author_count():
    """获取按作者文章数量排序的文章列表"""
    try:
        limit = request.args.get('limit', 10, type=int)
        articles = supabase_client.get_articles_by_author_count(limit=limit)
        return jsonify({'articles': articles}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/grouped/by-author/<author>', methods=['GET'])
def get_articles_by_author(author):
    """获取指定作者的所有文章"""
    try:
        articles = supabase_client.get_articles_by_author(author)
        return jsonify({'articles': articles}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/user/<user_id>', methods=['GET'])
@token_required
def get_user_articles(user_id, current_user_id):
    """获取指定用户的文章列表"""
    if user_id != current_user_id:
        return jsonify({'error': '无权限访问'}), 403
    try:
        articles = supabase_client.get_articles_by_user(user_id)
        return jsonify({'articles': articles}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles', methods=['GET'])
def get_articles():
    """获取文章列表（分页）"""
    try:
        page = request.args.get('page', 1, type=int)
        per_page = request.args.get('per_page', 10, type=int)
        articles = supabase_client.get_all_articles(page=page, per_page=per_page)
        return jsonify({'articles': articles}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles', methods=['POST'])
@token_required
def create_article(current_user_id):
    """创建文章"""
    try:
        data = request.get_json()
        title = data.get('title')
        content = data.get('content')
        tags = data.get('tags', [])
        author = data.get('author', '')
        preview_image_url = data.get('preview_image_url')
        
        if not title or not content:
            return jsonify({'error': '标题和内容不能为空'}), 400
        
        article = supabase_client.create_article(current_user_id, title, content, tags, author)
        if not article:
            return jsonify({'error': '文章创建失败'}), 500
        
        try:
            image_url = None
            if preview_image_url:
                image_url = preview_image_url
            else:
                image_url = ai_generator.generate_poem_image(article)
            
            if image_url:
                updated_article = supabase_client.update_article_image(article['id'], image_url)
                if updated_article:
                    article = updated_article
        except Exception as e:
            print(f"图片处理失败: {str(e)}")
        
        return jsonify({'article': article}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/<article_id>', methods=['GET'])
def get_article(article_id):
    """获取单篇文章"""
    try:
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        return jsonify({'article': article}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/<article_id>', methods=['PUT'])
@token_required
def update_article(article_id, current_user_id):
    """更新文章"""
    try:
        article = supabase_client.get_article_by_id(article_id)
        if not article or article['user_id'] != current_user_id:
            return jsonify({'error': '无权限修改此文章'}), 403
        
        data = request.get_json()
        update_data = {
            'title': data.get('title'),
            'content': data.get('content'),
            'tags': data.get('tags'),
            'author': data.get('author')
        }
        updated_article = supabase_client.update_article_fields(article_id, update_data)
        return jsonify({'article': updated_article}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/<article_id>', methods=['DELETE'])
@token_required
def delete_article(article_id, current_user_id):
    """删除文章"""
    try:
        article = supabase_client.get_article_by_id(article_id)
        if not article or article['user_id'] != current_user_id:
            return jsonify({'error': '无权限删除此文章'}), 403
        
        supabase_client.delete_article(article_id, current_user_id)
        return jsonify({'message': '文章删除成功'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500