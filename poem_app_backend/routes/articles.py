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

@articles_bp.route('/articles', methods=['GET'])
def get_articles():
    """获取文章列表"""
    try:
        articles = supabase_client.get_all_articles()
        return jsonify({'articles': articles}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles', methods=['POST'])
@token_required
def create_article(current_user_id):
    """上传文章"""
    try:
        data = request.get_json()
        title = data.get('title')
        content = data.get('content')
        tags = data.get('tags', [])
        author = data.get('author', '')
        preview_image_url = data.get('preview_image_url')  # 新增：预览图片URL
        
        if not title or not content:
            return jsonify({'error': '标题和内容不能为空'}), 400
        
        # 创建文章
        article = supabase_client.create_article(current_user_id, title, content, tags, author)
        if not article:
            return jsonify({'error': '文章创建失败'}), 500
        
        # 处理图片
        try:
            image_url = None
            
            # 如果提供了预览图片URL，直接使用
            if preview_image_url:
                print(f"使用预览图片: {preview_image_url}")
                image_url = preview_image_url
            else:
                # 否则生成新图片
                print("未提供预览图片，生成新图片")
                # 使用AI图片生成
                image_url = ai_generator.generate_poem_image(article)
            
            if image_url:
                # 更新文章的图片URL
                updated_article = supabase_client.update_article_image(article['id'], image_url)
                if updated_article:
                    article = updated_article
        except Exception as e:
            print(f"图片处理失败: {str(e)}")
            # 图片处理失败不影响文章发布
        
        return jsonify({
            'message': '文章发布成功',
            'article': {
                'id': article['id'],
                'title': article['title'],
                'content': article['content'],
                'tags': article.get('tags', []),
                'author': article.get('author', ''),
                'image_url': article.get('image_url', ''),
                'created_at': article['created_at']
            }
        }), 201
        
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
def update_article(current_user_id, article_id):
    """更新文章"""
    try:
        data = request.get_json()
        title = data.get('title')
        content = data.get('content')
        tags = data.get('tags', [])
        author = data.get('author', '')
        preview_image_url = data.get('preview_image_url')  # 新增：预览图片URL
        
        if not title or not content:
            return jsonify({'error': '标题和内容不能为空'}), 400
        
        # 检查是否为文章作者
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        if article['user_id'] != current_user_id:
            return jsonify({'error': '无权限修改此文章'}), 403
        
        # 更新文章基本信息
        update_data = {
            'title': title,
            'content': content,
            'tags': tags,
            'author': author
        }
        updated_article = supabase_client.update_article_fields(article_id, update_data)
        if not updated_article:
            return jsonify({'error': '文章更新失败'}), 500
        
        # 处理图片更新
        try:
            if preview_image_url:
                print(f"更新文章图片: {preview_image_url}")
                # 更新文章的图片URL
                updated_article = supabase_client.update_article_image(article_id, preview_image_url)
                if not updated_article:
                    print("图片URL更新失败")
        except Exception as e:
            print(f"图片处理失败: {str(e)}")
            # 图片处理失败不影响文章更新
        
        return jsonify({
            'message': '文章更新成功',
            'article': updated_article
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/<article_id>', methods=['DELETE'])
@token_required
def delete_article(current_user_id, article_id):
    """删除文章"""
    try:
        # 检查是否为文章作者
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        if article['user_id'] != current_user_id:
            return jsonify({'error': '无权限删除此文章'}), 403
        
        # 删除文章
        if supabase_client.delete_article(article_id, current_user_id):
            return jsonify({'message': '文章删除成功'}), 200
        else:
            return jsonify({'error': '文章删除失败'}), 500
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/user/<user_id>', methods=['GET'])
def get_user_articles(user_id):
    """获取指定用户的文章"""
    try:
        articles = supabase_client.get_articles_by_user(user_id)
        return jsonify({'articles': articles}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/home', methods=['GET'])
def get_home_articles():
    """获取首页文章数据"""
    try:
        # 获取本月最热门的文章
        top_month = supabase_client.get_top_month_article()
        
        # 获取本周热门文章列表
        top_week_list = supabase_client.get_top_week_articles()
        
        return jsonify({
            'top_month': top_month,
            'top_week_list': top_week_list
        }), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500 