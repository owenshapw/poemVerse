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
        text_position_x = data.get('text_position_x')
        text_position_y = data.get('text_position_y')
        preview_image_url = data.get('preview_image_url')

        if not title or not content:
            return jsonify({'error': '标题和内容不能为空'}), 400

        # If no image is provided, generate one.
        if not preview_image_url:
            try:
                temp_article_for_image = {
                    'id': 'temp', 'title': title, 'content': content, 'author': author, 'tags': tags
                }
                preview_image_url = ai_generator.generate_poem_image(temp_article_for_image)
            except Exception as e:
                print(f"图片生成失败: {str(e)}")
                preview_image_url = None

        # Create the article in a single, atomic operation with all data.
        article = supabase_client.create_article(
            current_user_id, title, content, tags, author, 
            text_position_x=text_position_x, 
            text_position_y=text_position_y, 
            preview_image_url=preview_image_url
        )
        
        if not article:
            return jsonify({'error': '文章创建失败'}), 500
        
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
        # First, verify the user has permission to edit this article
        article = supabase_client.get_article_by_id(article_id)
        if not article or article['user_id'] != current_user_id:
            return jsonify({'error': '无权限修改此文章'}), 403
        
        data = request.get_json()
        
        # Build the update dictionary robustly, only including fields that are present
        update_data = {}
        for key in ['title', 'content', 'tags', 'author']:
            if key in data:
                update_data[key] = data[key]

        # Explicitly cast positions to float to prevent data type errors
        if 'text_position_x' in data and data['text_position_x'] is not None:
            update_data['text_position_x'] = float(data['text_position_x'])
        if 'text_position_y' in data and data['text_position_y'] is not None:
            update_data['text_position_y'] = float(data['text_position_y'])

        # Handle the image URL separately to ensure it's formatted correctly
        if 'preview_image_url' in data:
            update_data['image_url'] = supabase_client._format_image_url(data['preview_image_url'])

        # Perform the update only if there is data to update
        if not update_data:
            return jsonify({'message': 'No data provided to update'}), 200

        updated_article = supabase_client.update_article_fields(article_id, current_user_id, update_data)
        
        if not updated_article:
            return jsonify({'error': '文章更新失败'}), 500

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