from flask import Blueprint, request, jsonify, current_app
from models.supabase_client import supabase_client
from utils.image_generator import generate_article_image
from utils.ai_image_generator import ai_generator
import jwt
from functools import wraps

generate_bp = Blueprint('generate', __name__)

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

@generate_bp.route('/generate', methods=['POST'])
@token_required
def generate_image(current_user_id):
    """根据文章生成图文排版图像"""
    try:
        data = request.get_json()
        article_id = data.get('article_id')
        
        if not article_id:
            return jsonify({'error': '文章ID不能为空'}), 400
        
        # 获取文章信息
        article = supabase_client.get_article_by_id(article_id)
        if not article:
            return jsonify({'error': '文章不存在'}), 404
        
        # 检查是否为文章作者
        if article['user_id'] != current_user_id:
            return jsonify({'error': '无权限生成此文章的图片'}), 403
        
        # 提取token
        token = request.headers['Authorization'].split(" ")[1]
        
        # 生成图片
        # 优先使用AI图片生成
        image_url = ai_generator.generate_poem_image(article)
        
        # 如果AI生成失败，回退到文字排版
        if not image_url:
            print("AI图片生成失败，使用文字排版")
            # 注意：同样需要为备用方案传递token
            image_url = generate_article_image(article, user_token=token)
            
        if not image_url:
            return jsonify({'error': '图片生成失败'}), 500
        
        # 更新文章的图片URL
        updated_article = supabase_client.update_article_image(article_id, image_url)
        if not updated_article:
            return jsonify({'error': '更新文章图片失败'}), 500
        
        return jsonify({
            'message': '图片生成成功',
            'image_url': image_url,
            'article': {
                'id': updated_article['id'],
                'title': updated_article['title'],
                'image_url': updated_article['image_url']
            }
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@generate_bp.route('/generate/batch', methods=['POST'])
@token_required
def generate_batch_images(current_user_id):
    """批量生成用户所有文章的图片"""
    try:
        # 获取用户的所有文章
        articles = supabase_client.get_articles_by_user(current_user_id)
        
        if not articles:
            return jsonify({'message': '没有找到需要生成图片的文章'}), 200
        
        generated_count = 0
        failed_count = 0
        
        for article in articles:
            try:
                # 如果文章已有图片，跳过
                if article['image_url']:
                    continue
                
                # 生成图片
                image_url = generate_article_image(article)
                if image_url:
                    # 更新文章的图片URL
                    supabase_client.update_article_image(article['id'], image_url)
                    generated_count += 1
                else:
                    failed_count += 1
                    
            except Exception as e:
                print(f"生成文章 {article['id']} 图片失败: {str(e)}")
                failed_count += 1
        
        return jsonify({
            'message': '批量生成完成',
            'generated_count': generated_count,
            'failed_count': failed_count,
            'total_articles': len(articles)
        }), 200
        
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@generate_bp.route('/generate/preview', methods=['POST'])
@token_required
def generate_preview(current_user_id):
    """生成预览图片（不保存到数据库）"""
    try:
        data = request.get_json()
        title = data.get('title')
        content = data.get('content')
        author = data.get('author', '')
        tags = data.get('tags', [])
        
        if not title or not content:
            return jsonify({'error': '标题和内容不能为空'}), 400
        
        # 创建临时文章对象
        temp_article = {
            'title': title,
            'content': content,
            'author': author,
            'tags': tags
        }
        
        # 提取token
        token = request.headers['Authorization'].split(" ")[1]
        
        # 优先使用AI图片生成
        print("🎨 尝试AI图片生成预览...")
        image_url = ai_generator.generate_poem_image(temp_article)
        
        # 如果AI生成失败，回退到文字排版
        if not image_url:
            print("AI预览图片生成失败，使用文字排版")
            image_url = generate_article_image(temp_article, is_preview=True, user_token=token)
            
        if not image_url:
            return jsonify({'error': '预览图片生成失败'}), 500
        
        print(f"✅ 预览图片生成成功: {image_url}")
        return jsonify({
            'message': '预览图片生成成功',
            'preview_url': image_url
        }), 200
        
    except Exception as e:
        print(f"❌ 预览图片生成异常: {str(e)}")
        import traceback
        traceback.print_exc()
        return jsonify({'error': str(e)}), 500 