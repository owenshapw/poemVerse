from supabase.client import create_client, Client
import os
import uuid
from datetime import datetime, timedelta
import bcrypt
from typing import Optional, Union
import re

class SupabaseClient:
    def __init__(self):
        self.supabase: Optional[Client] = None

    def init_app(self, app):
        self.supabase = create_client(
            app.config['SUPABASE_URL'],
            app.config['SUPABASE_KEY']
        )

    def get_user_by_email(self, email: str):
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        result = self.supabase.table('users').select('*').eq('email', email).execute()
        return result.data[0] if result.data else None

    def get_user_by_id(self, user_id: str):
        """根据ID获取用户"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        result = self.supabase.table('users').select('*').eq('id', user_id).execute()
        return result.data[0] if result.data else None

    def _format_image_url(self, url: Optional[str]) -> str:
        """将Cloudflare图片URL统一为自定义域名格式，并确保返回非None值"""
        if not url:
            return ""
        m = re.search(r'imagedelivery.net/([^/]+)/([^/]+)/public', url)
        if m:
            account_hash = m.group(1)
            image_id = m.group(2)
            return f"https://imagedelivery.net/{account_hash}/{image_id}/headphoto"
        return url

    def create_article(self, user_id: str, title: str, content: str, tags: list, author: Optional[str] = None, text_position_x: Optional[float] = None, text_position_y: Optional[float] = None, preview_image_url: Optional[str] = None, image_offset_x: Optional[float] = None, image_offset_y: Optional[float] = None, image_scale: Optional[float] = None, is_public_visible: bool = True):
        """创建文章"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        user_info = self.get_user_by_id(user_id)
        if user_info:
            author_name = author or user_info.get('username', user_info.get('email', '匿名'))
        else:
            author_name = author or '匿名'
        article_data = {
            'id': str(uuid.uuid4()),
            'user_id': user_id,
            'title': title,
            'content': content,
            'tags': tags,
            'image_url': self._format_image_url(preview_image_url),
            'created_at': datetime.utcnow().isoformat(),
            'updated_at': datetime.utcnow().isoformat(),
            'like_count': 0,
            'text_position_x': text_position_x,
            'text_position_y': text_position_y,
            # 新增：保存图片偏移与缩放
            'image_offset_x': image_offset_x,
            'image_offset_y': image_offset_y,
            'image_scale': image_scale,
            # 可见性控制
            'is_public_visible': is_public_visible
        }
        try:
            article_data['author'] = author_name
        except:
            pass
        result = self.supabase.table('articles').insert(article_data).execute()
        return result.data[0] if result.data else None

    def get_all_articles(self, page: int = 1, per_page: int = 10, current_user_id=None):
        """
        获取所有文章（支持分页）
        实现可见性过滤逻辑：
        - 匿名用户：只能看到公开文章
        - 登录用户：能看到所有公开文章 + 自己的所有文章
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        if current_user_id is None:
            # 匿名用户：只返回公开文章
            start_index = (page - 1) * per_page
            end_index = start_index + per_page - 1
            result = self.supabase.table('articles').select('*').eq('is_public_visible', True).order('created_at', desc=True).range(start_index, end_index).execute()
            return result.data
        else:
            # 登录用户：需要复杂查询，先获取所有文章再过滤
            result = self.supabase.table('articles').select('*').order('created_at', desc=True).execute()
            all_articles = result.data
            
            # 过滤文章
            filtered_articles = []
            for article in all_articles:
                # 公开文章或自己的文章
                if article.get('is_public_visible', True) or article.get('user_id') == current_user_id:
                    filtered_articles.append(article)
            
            # 手动分页
            start_index = (page - 1) * per_page
            end_index = start_index + per_page
            return filtered_articles[start_index:end_index]

    def get_article_by_id(self, article_id: str):
        """根据ID获取文章"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        result = self.supabase.table('articles').select('*').eq('id', article_id).execute()
        return result.data[0] if result.data else None

    def get_articles_by_user(self, user_id: str):
        """获取用户的所有文章"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        result = self.supabase.table('articles').select('*').eq('user_id', user_id).order('updated_at', desc=True).execute()
        return result.data

    def delete_article(self, article_id: str, user_id: str):
        """删除文章（仅作者可删除）"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        result = self.supabase.table('articles').delete().eq('id', article_id).eq('user_id', user_id).execute()
        return len(result.data) > 0

    def update_article_image(self, article_id: str, image_url: Optional[str]):
        """更新文章图片URL，写入前统一格式"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        formatted_url = self._format_image_url(image_url)
        # 执行 update，然后兼容不同版本返回值格式；如 update 不返回行则 fallback 再查询一次
        resp = self.supabase.table('articles').update({'image_url': formatted_url}).eq('id', article_id).execute()
        data = None
        if resp is None:
            data = None
        elif hasattr(resp, 'data'):
            data = resp.data
        elif isinstance(resp, dict) and 'data' in resp:
            data = resp.get('data')
        if data:
            return data[0] if isinstance(data, list) else data
        return self.get_article_by_id(article_id)

    def update_article_fields(self, article_id: str, user_id: str, update_data: dict):
        """
        Update article fields and return the updated row (or None on failure).
        Compatible with different supabase-py versions by:
         - calling .table(...).update(...).eq(...).execute()
         - parsing resp.data / resp.get('data') fallback
         - if update response doesn't contain row, fetch by id as fallback
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        try:
            # 使用 table(...).update(...).eq(...).execute() 是较新/通用的方式
            # 注意：使用 self.supabase（不是 self.client），并避免在 eq() 后再调用 select()
            resp = self.supabase.table('articles').update(update_data).eq('id', article_id).execute()

            # 多种返回结构兼容处理
            data = None
            if resp is None:
                data = None
            elif hasattr(resp, 'data'):              # e.g. SyncResponse object
                data = resp.data
            elif isinstance(resp, dict) and 'data' in resp:
                data = resp.get('data')

            # 有数据且为列表时返回第一项
            if data:
                return data[0] if isinstance(data, list) else data

            # 兼容性保底：update 可能不返回行，主动再查询一次并返回
            return self.get_article_by_id(article_id)

        except Exception as e:
            # 记录错误以便在 render/日志中定位（保留原始异常信息）
            try:
                import logging
                logging.exception("update_article_fields error")
            except Exception:
                pass
            return None

    def create_comment(self, article_id: str, user_id: str, content: str):
        """创建评论"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        comment_data = {
            'id': str(uuid.uuid4()),
            'article_id': article_id,
            'user_id': user_id,
            'content': content,
            'created_at': datetime.utcnow().isoformat()
        }
        result = self.supabase.table('comments').insert(comment_data).execute()
        return result.data[0] if result.data else None

    def get_comments_by_article(self, article_id: str):
        """获取文章的所有评论"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        result = self.supabase.table('comments').select('*').eq('article_id', article_id).order('created_at', desc=True).execute()
        return result.data

    def get_recent_articles(self, limit=10, current_user_id=None):
        """
        获取最新的文章列表
        实现可见性过滤逻辑：
        - 匿名用户：只能看到公开文章
        - 登录用户：能看到所有公开文章 + 自己的所有文章
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        if current_user_id is None:
            # 匿名用户：只返回公开文章
            query = self.supabase.table('articles').select('*').eq('is_public_visible', True)
            result = query.order('created_at', desc=True).limit(limit).execute()
            return result.data
        else:
            # 登录用户：需要复杂查询（公开文章 + 自己的私密文章）
            # 获取所有文章，然后在应用层过滤
            result = self.supabase.table('articles').select('*').order('created_at', desc=True).execute()
            all_articles = result.data
            
            # 过滤文章
            filtered_articles = []
            for article in all_articles:
                # 公开文章或自己的文章
                if article.get('is_public_visible', True) or article.get('user_id') == current_user_id:
                    filtered_articles.append(article)
            
            # 返回限制数量的结果
            return filtered_articles[:limit]

    def get_articles_by_author_count(self, limit=10, current_user_id=None):
        """
        获取按作者文章数量排序的文章列表，每个作者返回最新的一篇文章
        
        Args:
            limit: 返回文章数量限制
            current_user_id: 当前用户ID（如果为None则为匿名用户）
        
        Returns:
            list: 文章列表
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        return self._get_articles_by_author_count_fallback(limit, current_user_id)

    def _get_articles_by_author_count_fallback(self, limit=10, current_user_id=None):
        """
        备用方法：获取所有文章后按作者分组
        实现可见性过滤逻辑：
        - 匿名用户：只能看到公开文章
        - 登录用户：能看到所有公开文章 + 自己的所有文章
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        # 获取所有文章
        result = self.supabase.table('articles').select('*').order('created_at', desc=True).execute()
        all_articles = result.data
        
        if not all_articles:
            return []
        
        # 根据用户身份过滤文章
        filtered_articles = []
        for article in all_articles:
            # 公开文章：所有人都能看到
            if article.get('is_public_visible', True):
                filtered_articles.append(article)
            # 私密文章：只有作者本人能看到
            elif current_user_id and article.get('user_id') == current_user_id:
                filtered_articles.append(article)
        
        # 按作者分组并统计
        author_groups = {}
        for article in filtered_articles:
            author = article.get('author', '匿名')
            if author not in author_groups:
                author_groups[author] = []
            author_groups[author].append(article)
        
        # 按文章数量排序作者
        sorted_authors = sorted(author_groups.keys(), 
                              key=lambda x: len(author_groups[x]), 
                              reverse=True)
        
        # 获取每个作者的最新文章
        articles = []
        for author in sorted_authors[:limit]:
            author_articles = author_groups[author]
            if author_articles:
                # 按创建时间排序，取最新的
                latest_article = max(author_articles, key=lambda x: x.get('created_at', ''))
                articles.append(latest_article)
        
        return articles

    def get_articles_by_author(self, author: str, current_user_id=None):
        """
        获取指定作者的所有文章
        实现可见性过滤逻辑：
        - 匿名用户：只能看到该作者的公开文章
        - 登录用户：
          - 如果查看自己的作品：能看到所有文章（包括私密的）
          - 如果查看其他人的作品：只能看到公开文章
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        # 获取该作者的所有文章
        result = self.supabase.table('articles').select('*').eq('author', author).order('created_at', desc=True).execute()
        all_articles = result.data
        
        if not all_articles:
            return []
        
        # 检查当前用户是否为该作者本人
        is_author_self = False
        if current_user_id:
            # 通过用户ID校验（更准确）
            for article in all_articles:
                if article.get('user_id') == current_user_id:
                    is_author_self = True
                    break
        
        # 根据用户身份过滤文章
        if is_author_self:
            # 作者本人：返回所有文章
            return all_articles
        else:
            # 其他用户或匿名用户：只返回公开文章
            return [article for article in all_articles if article.get('is_public_visible', True)]

    def delete_comment(self, comment_id):
        if self.supabase is None:
            from flask import current_app
            self.init_app(current_app)
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized")
        return self.supabase.table('comments').delete().eq('id', comment_id).execute()

    def get_comment_by_id(self, comment_id):
        if self.supabase is None:
            from flask import current_app
            self.init_app(current_app)
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized")
        result = self.supabase.table('comments').select('*').eq('id', comment_id).execute()
        if result.data:
            return result.data[0]
        return None

    def register_with_supabase_auth(self, email: str, password: str, username: Union[str, None] = None):
        """
        1. 通过Supabase Auth注册（auth.users）
        2. 在users表和public.users表各插入一份用户信息
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        # 1. Supabase Auth注册
        auth_result = self.supabase.auth.sign_up({"email": email, "password": password})
        if not auth_result or not getattr(auth_result, 'user', None):
            raise Exception("Supabase Auth注册失败")
        user_id = auth_result.user.id  # 用auth返回的id
        user_email = auth_result.user.email
        # 2. 插入users表，id用auth返回的id
        user_data = {
            'id': user_id,
            'email': user_email,
            'created_at': datetime.utcnow().isoformat()
        }
        if username:
            user_data['username'] = username
        self.supabase.table('users').insert(user_data).execute()
        return user_data

    # ==================== 点赞功能相关方法 ====================
    
    def toggle_article_like(self, article_id: str, user_id: Optional[str] = None, device_id: Optional[str] = None, ip_address: Optional[str] = None):
        """
        切换文章点赞状态
        
        Args:
            article_id: 文章ID
            user_id: 用户ID（登录用户）
            device_id: 设备ID（匿名用户）
            ip_address: IP地址
            
        Returns:
            dict: 包含点赞状态和总计数的字典
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        # 检查文章是否存在
        article = self.get_article_by_id(article_id)
        if not article:
            raise ValueError("文章不存在")
        
        try:
            # 查找现有的点赞记录
            query = self.supabase.table('article_likes').select('*').eq('article_id', article_id)
            
            if user_id:
                # 登录用户：按user_id查找
                query = query.eq('user_id', user_id)
            else:
                # 匿名用户：按device_id查找
                if not device_id:
                    raise ValueError("匿名用户必须提供device_id")
                query = query.eq('device_id', device_id)
            
            existing_like = query.execute()
            
            if existing_like.data:
                # 已存在点赞记录，切换状态或删除
                like_record = existing_like.data[0]
                if like_record['is_liked']:
                    # 当前已点赞，删除记录（取消点赞）
                    self.supabase.table('article_likes').delete().eq('id', like_record['id']).execute()
                    is_liked = False
                else:
                    # 当前未点赞，更新为点赞
                    self.supabase.table('article_likes').update({
                        'is_liked': True,
                        'updated_at': datetime.utcnow().isoformat()
                    }).eq('id', like_record['id']).execute()
                    is_liked = True
            else:
                # 不存在点赞记录，创建新的点赞
                like_data = {
                    'id': str(uuid.uuid4()),
                    'article_id': article_id,
                    'is_liked': True,
                    'created_at': datetime.utcnow().isoformat(),
                    'updated_at': datetime.utcnow().isoformat()
                }
                
                if user_id:
                    like_data['user_id'] = user_id
                if device_id:
                    like_data['device_id'] = device_id
                if ip_address:
                    like_data['ip_address'] = ip_address
                
                self.supabase.table('article_likes').insert(like_data).execute()
                is_liked = True
            
            # 获取更新后的文章信息（包含最新的like_count）
            updated_article = self.get_article_by_id(article_id)
            like_count = updated_article.get('like_count', 0)
            
            return {
                'success': True,
                'is_liked': is_liked,
                'like_count': like_count,
                'article_id': article_id
            }
            
        except Exception as e:
            raise Exception(f"点赞操作失败: {str(e)}")
    
    def get_article_like_info(self, article_id: str, user_id: Optional[str] = None, device_id: Optional[str] = None):
        """
        获取文章的点赞信息
        
        Args:
            article_id: 文章ID
            user_id: 用户ID（可选）
            device_id: 设备ID（可选）
            
        Returns:
            dict: 包含点赞状态和总计数的字典
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        # 获取文章信息（包含总点赞数）
        article = self.get_article_by_id(article_id)
        if not article:
            raise ValueError("文章不存在")
        
        like_count = article.get('like_count', 0)
        is_liked_by_user = False
        
        # 检查当前用户是否已点赞
        if user_id or device_id:
            query = self.supabase.table('article_likes').select('*').eq('article_id', article_id).eq('is_liked', True)
            
            if user_id:
                query = query.eq('user_id', user_id)
            else:
                query = query.eq('device_id', device_id)
            
            like_record = query.execute()
            is_liked_by_user = len(like_record.data) > 0
        
        return {
            'article_id': article_id,
            'like_count': like_count,
            'is_liked_by_user': is_liked_by_user
        }
    
    def get_batch_article_likes(self, article_ids: list, user_id: Optional[str] = None, device_id: Optional[str] = None):
        """
        批量获取多篇文章的点赞信息
        
        Args:
            article_ids: 文章ID列表
            user_id: 用户ID（可选）
            device_id: 设备ID（可选）
            
        Returns:
            dict: 以article_id为key的点赞信息字典
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        if not article_ids:
            return {}
        
        # 获取所有文章的基本信息
        articles_result = self.supabase.table('articles').select('id, like_count').in_('id', article_ids).execute()
        articles_data = {article['id']: article for article in articles_result.data}
        
        # 获取用户的点赞记录
        user_likes = {}
        if user_id or device_id:
            query = self.supabase.table('article_likes').select('article_id').in_('article_id', article_ids).eq('is_liked', True)
            
            if user_id:
                query = query.eq('user_id', user_id)
            else:
                query = query.eq('device_id', device_id)
            
            likes_result = query.execute()
            user_likes = {like['article_id']: True for like in likes_result.data}
        
        # 组装返回数据
        result = {}
        for article_id in article_ids:
            article_data = articles_data.get(article_id, {})
            result[article_id] = {
                'article_id': article_id,
                'like_count': article_data.get('like_count', 0),
                'is_liked_by_user': user_likes.get(article_id, False)
            }
        
        return result
    
    def update_article_visibility(self, article_id: str, user_id: str, is_public_visible: bool):
        """
        更新文章的首页可见性
        
        Args:
            article_id: 文章ID
            user_id: 用户ID（验证权限）
            is_public_visible: 是否公开可见
            
        Returns:
            dict: 更新后的文章数据
        """
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        
        try:
            # 更新数据
            update_data = {
                'is_public_visible': is_public_visible,
                'updated_at': datetime.utcnow().isoformat()
            }
            
            # 执行更新（只有文章作者可以更新）
            resp = self.supabase.table('articles').update(update_data).eq('id', article_id).eq('user_id', user_id).execute()
            
            # 处理返回结果
            data = None
            if resp is None:
                data = None
            elif hasattr(resp, 'data'):
                data = resp.data
            elif isinstance(resp, dict) and 'data' in resp:
                data = resp.get('data')
            
            if data:
                return data[0] if isinstance(data, list) else data
            
            # 如果更新没有返回数据，则再查询一次
            return self.get_article_by_id(article_id)
            
        except Exception as e:
            raise Exception(f"更新文章可见性失败: {str(e)}")

supabase_client = SupabaseClient()