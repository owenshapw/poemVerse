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

    def create_article(self, user_id: str, title: str, content: str, tags: list, author: Optional[str] = None):
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
            'image_url': None,
            'created_at': datetime.utcnow().isoformat(),
            'like_count': 0
        }
        try:
            article_data['author'] = author_name
        except:
            pass
        result = self.supabase.table('articles').insert(article_data).execute()
        return result.data[0] if result.data else None

    def get_all_articles(self, page: int = 1, per_page: int = 10):
        """获取所有文章（支持分页）"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        start_index = (page - 1) * per_page
        end_index = start_index + per_page - 1
        result = self.supabase.table('articles').select('*').order('created_at', desc=True).range(start_index, end_index).execute()
        return result.data

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
        result = self.supabase.table('articles').select('*').eq('user_id', user_id).order('created_at', desc=True).execute()
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
        result = self.supabase.table('articles').update({'image_url': formatted_url}).eq('id', article_id).execute()
        return result.data[0] if result.data else None

    def update_article_fields(self, article_id: str, update_data: dict):
        """根据ID更新文章部分字段"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        result = self.supabase.table('articles').update(update_data).eq('id', article_id).execute()
        return result.data[0] if result.data else None

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

    def get_recent_articles(self, limit=10):
        """获取最新的文章列表"""
        if self.supabase is None:
            raise RuntimeError("Supabase client not initialized. Call init_app() first.")
        result = self.supabase.table('articles').select('*').order('created_at', desc=True).limit(limit).execute()
        return result.data

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
        user_id = auth_result.user.id
        user_email = auth_result.user.email
        # 2. 插入users表
        user_data = {
            'id': user_id,
            'email': user_email,
            'created_at': datetime.utcnow().isoformat()
        }
        if username:
            user_data['username'] = username
        self.supabase.table('users').insert(user_data).execute()
        # 3. 插入public.users表
        self.supabase.table('public.users').insert(user_data).execute()
        return user_data

supabase_client = SupabaseClient()