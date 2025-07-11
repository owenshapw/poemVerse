from flask import Blueprint, request, jsonify, current_app
from models.supabase_client import supabase_client
from utils.image_generator import generate_article_image
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

# 工具函数：序列化文章，确保包含 user_id 字段

def serialize_article(article):
    return {
        'id': article['id'],
        'title': article['title'],
        'content': article['content'],
        'tags': article['tags'],
        'author': article['author'],
        'image_url': article['image_url'],
        'created_at': article['created_at'],
        'user_id': article['user_id'],
        'like_count': article.get('like_count', 0)
    }

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
                # 优先使用AI图片生成
                image_url = ai_generator.generate_poem_image(article)
                
                # 如果AI生成失败，回退到文字排版
                if not image_url:
                    print("AI图片生成失败，使用文字排版")
                    image_url = generate_article_image(article)
            
            if image_url:
                # 更新文章的图片URL
                updated_article = supabase_client.update_article_image(article['id'], image_url)
                if updated_article:
                    article = updated_article
        except Exception as e:
            print(f"图片处理失败: {str(e)}")
            # 图片处理失败不影响文章发布
        
        return jsonify({
            'message': '文章上传成功',
            'article': serialize_article(article)
        }), 201
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles', methods=['GET'])
def get_articles():
    """获取所有文章列表（首页流）"""
    try:
        articles = supabase_client.get_all_articles()
        
        # 格式化返回数据
        formatted_articles = []
        for article in articles:
            # 获取作者信息
            author_info = supabase_client.get_user_by_id(article['user_id'])
            
            formatted_articles.append({
                'id': article['id'],
                'title': article['title'],
                'content': article['content'],
                'tags': article['tags'],
                'author': article['author'],
                'author_email': author_info['email'] if author_info else '',
                'image_url': article['image_url'],
                'created_at': article['created_at'],
                'user_id': article['user_id']  # 添加用户ID字段
            })
        
        return jsonify({
            'articles': formatted_articles,
            'total': len(formatted_articles)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/<article_id>', methods=['GET'])
def get_article(article_id):
    """获取单篇文章详情"""
    try:
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        
        # 获取作者信息
        author_info = supabase_client.get_user_by_id(article['user_id'])
        
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
            'article': serialize_article(article),
            'comments': formatted_comments
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/<article_id>', methods=['DELETE'])
@token_required
def delete_article(current_user_id, article_id):
    """删除文章（仅作者可删除）"""
    try:
        # 检查文章是否存在
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        
        # 检查是否为作者
        if article['user_id'] != current_user_id:
            return jsonify({'error': '无权限删除此文章'}), 403
        
        # 删除文章
        success = supabase_client.delete_article(article_id, current_user_id)
        if not success:
            return jsonify({'error': '删除失败'}), 500
        
        return jsonify({'message': '文章删除成功'}), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/my-articles', methods=['GET'])
@token_required
def get_my_articles(current_user_id):
    """获取当前用户的所有文章"""
    try:
        articles = supabase_client.get_articles_by_user(current_user_id)
        
        formatted_articles = []
        for article in articles:
            formatted_articles.append({
                'id': article['id'],
                'title': article['title'],
                'content': article['content'],
                'tags': article['tags'],
                'author': article['author'],
                'image_url': article['image_url'],
                'created_at': article['created_at'],
                'user_id': article['user_id']
            })
        
        return jsonify({
            'articles': formatted_articles,
            'total': len(formatted_articles)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@articles_bp.route('/articles/search', methods=['GET'])
def search_articles():
    """搜索文章（按标签或作者）"""
    try:
        tag = request.args.get('tag')
        author = request.args.get('author')
        
        if not tag and not author:
            return jsonify({'error': '请提供搜索条件（标签或作者）'}), 400
        
        articles = supabase_client.get_all_articles()
        
        # 过滤文章
        filtered_articles = []
        for article in articles:
            if tag and tag in article['tags']:
                filtered_articles.append(article)
            elif author and author.lower() in article['author'].lower():
                filtered_articles.append(article)
        
        # 格式化返回数据
        formatted_articles = []
        for article in filtered_articles:
            author_info = supabase_client.get_user_by_id(article['user_id'])
            formatted_articles.append({
                'id': article['id'],
                'title': article['title'],
                'content': article['content'],
                'tags': article['tags'],
                'author': article['author'],
                'author_email': author_info['email'] if author_info else '',
                'image_url': article['image_url'],
                'created_at': article['created_at'],
                'user_id': article['user_id']
            })
        
        return jsonify({
            'articles': formatted_articles,
            'total': len(formatted_articles)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500 

@articles_bp.route('/articles/home', methods=['GET'])
def get_home_articles():
    """首页聚合接口：
    - top_month: 过去一个月点赞最多的诗（1条，背景大图）
    - top_week_list: 过去一周点赞最多的诗（多条，列表）
    """
    try:
        if supabase_client.supabase is None:
            print("⚠️ Supabase 客户端未初始化，尝试重新初始化...")
            try:
                from supabase.client import create_client
                import os
                supabase_url = os.getenv("SUPABASE_URL")
                supabase_key = os.getenv("SUPABASE_KEY")
                if supabase_url and supabase_key:
                    supabase_client.supabase = create_client(supabase_url, supabase_key)
                    print("✅ Supabase 客户端重新初始化成功")
                else:
                    return jsonify({'error': 'Supabase 环境变量未配置'}), 500
            except Exception as e:
                print(f"❌ Supabase 客户端重新初始化失败: {e}")
                return jsonify({'error': 'Supabase 客户端初始化失败'}), 500
        
        # 再次检查客户端是否可用
        if supabase_client.supabase is None:
            return jsonify({'error': 'Supabase 客户端仍然不可用'}), 500
        
        print("开始查询首页数据...")
        now = datetime.utcnow()
        one_month_ago = now - timedelta(days=30)
        one_week_ago = now - timedelta(days=7)

        print(f"查询时间范围: {one_month_ago} 到 {now}")

        # 过去一个月点赞最多的诗
        try:
            print("查询过去一个月热门诗篇...")
            month_result = supabase_client.supabase.table('articles') \
                .select('*') \
                .gte('created_at', one_month_ago.isoformat()) \
                .order('like_count', desc=True) \
                .limit(1) \
                .execute()
            top_month = month_result.data[0] if month_result.data else None
            print(f"一个月热门诗篇查询成功，结果: {len(month_result.data) if month_result.data else 0} 条")
        except Exception as e:
            print(f"查询一个月热门诗篇失败: {e}")
            top_month = None

        # 过去一周点赞最多的诗列表
        try:
            print("查询过去一周热门诗篇...")
            week_result = supabase_client.supabase.table('articles') \
                .select('*') \
                .gte('created_at', one_week_ago.isoformat()) \
                .order('like_count', desc=True) \
                .limit(10) \
                .execute()
            top_week_list = week_result.data if week_result.data else []
            print(f"一周热门诗篇查询成功，结果: {len(top_week_list)} 条")
        except Exception as e:
            print(f"查询一周热门诗篇失败: {e}")
            top_week_list = []

        # 如果都失败了，尝试获取所有文章
        if top_month is None and not top_week_list:
            print("尝试获取所有文章作为备选...")
            try:
                all_articles = supabase_client.get_all_articles()
                if all_articles:
                    top_month = all_articles[0]
                    top_week_list = all_articles[:10]
                    print(f"备选方案成功，获取到 {len(all_articles)} 篇文章")
            except Exception as e:
                print(f"备选方案也失败: {e}")

        return jsonify({
            'top_month': top_month,
            'top_week_list': top_week_list
        }), 200
    except Exception as e:
        print(f"首页接口异常: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500 

@articles_bp.route('/articles/<article_id>', methods=['PUT'])
@token_required
def update_article(current_user_id, article_id):
    """更新诗篇内容"""
    try:
        print(f"开始更新文章: {article_id}")
        print(f"Supabase client 状态: {supabase_client.supabase is not None}")
        
        data = request.get_json()
        title = data.get('title')
        content = data.get('content')
        tags = data.get('tags', [])
        preview_image_url = data.get('preview_image_url')

        print(f"更新数据: title={title}, content长度={len(content) if content else 0}, tags={tags}, preview_image_url={preview_image_url}")

        # 获取并校验文章
        print("获取文章信息...")
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        if article['user_id'] != current_user_id:
            return jsonify({'error': '无权限编辑此文章'}), 403

        print("文章验证通过，开始更新...")

        # 更新内容
        update_data = {
            'title': title,
            'content': content,
            'tags': tags,
        }
        if preview_image_url:
            update_data['image_url'] = preview_image_url

        print(f"更新数据: {update_data}")
        updated_article = supabase_client.update_article_fields(article_id, update_data)
        if not updated_article:
            return jsonify({'error': '更新失败'}), 500

        print("文章更新成功")
        return jsonify({'message': '更新成功', 'article': serialize_article(updated_article)}), 200
        
    except Exception as e:
        print(f"更新文章异常: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500 