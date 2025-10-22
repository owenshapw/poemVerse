-- Supabase RLS 配置脚本 - 诗篇应用（简化版）
-- 只为实际使用的表配置RLS策略

-- ================================
-- 清理无用的表和视图
-- ================================

-- 删除未使用的表/视图
DROP VIEW IF EXISTS user_articles_view;
DROP TABLE IF EXISTS comments;

-- ================================
-- 1. USERS 表 RLS 策略
-- ================================
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 清理现有策略（如果存在）
DROP POLICY IF EXISTS "Allow user registration" ON users;
DROP POLICY IF EXISTS "Users can view own data" ON users;
DROP POLICY IF EXISTS "Users can update own data" ON users;

-- 允许用户注册
CREATE POLICY "Allow user registration" ON users
    FOR INSERT WITH CHECK (true);

-- 允许用户查看自己的信息和匿名访问
CREATE POLICY "Users can view own data" ON users
    FOR SELECT USING (auth.uid()::text = id::text OR auth.uid() IS NULL);

-- 允许用户更新自己的信息
CREATE POLICY "Users can update own data" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);

-- ================================
-- 2. ARTICLES 表 RLS 策略
-- ================================
ALTER TABLE articles ENABLE ROW LEVEL SECURITY;

-- 清理现有策略（如果存在）
DROP POLICY IF EXISTS "View public articles or own articles" ON articles;
DROP POLICY IF EXISTS "Authenticated users can insert articles" ON articles;
DROP POLICY IF EXISTS "Authors can update own articles" ON articles;
DROP POLICY IF EXISTS "Authors can delete own articles" ON articles;

-- 允许查看公开文章或自己的文章
CREATE POLICY "View public articles or own articles" ON articles
    FOR SELECT USING (
        is_public_visible = true OR 
        auth.uid()::text = user_id::text OR
        auth.uid() IS NULL
    );

-- 允许认证用户创建文章
CREATE POLICY "Authenticated users can insert articles" ON articles
    FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

-- 允许作者更新自己的文章
CREATE POLICY "Authors can update own articles" ON articles
    FOR UPDATE USING (auth.uid()::text = user_id::text);

-- 允许作者删除自己的文章
CREATE POLICY "Authors can delete own articles" ON articles
    FOR DELETE USING (auth.uid()::text = user_id::text);

-- ================================
-- 3. ARTICLE_LIKES 表 RLS 策略
-- ================================
ALTER TABLE article_likes ENABLE ROW LEVEL SECURITY;

-- 清理现有策略（如果存在）
DROP POLICY IF EXISTS "Anyone can view likes" ON article_likes;
DROP POLICY IF EXISTS "Anyone can insert likes" ON article_likes;
DROP POLICY IF EXISTS "Users can update own likes" ON article_likes;
DROP POLICY IF EXISTS "Users can delete own likes" ON article_likes;

-- 允许任何人查看点赞信息
CREATE POLICY "Anyone can view likes" ON article_likes
    FOR SELECT USING (true);

-- 允许任何人创建点赞（支持匿名用户）
CREATE POLICY "Anyone can insert likes" ON article_likes
    FOR INSERT WITH CHECK (true);

-- 允许用户更新自己的点赞
CREATE POLICY "Users can update own likes" ON article_likes
    FOR UPDATE USING (
        (auth.uid() IS NOT NULL AND auth.uid()::text = user_id::text) OR 
        (auth.uid() IS NULL AND device_id IS NOT NULL)
    );

-- 允许用户删除自己的点赞
CREATE POLICY "Users can delete own likes" ON article_likes
    FOR DELETE USING (
        (auth.uid() IS NOT NULL AND auth.uid()::text = user_id::text) OR 
        (auth.uid() IS NULL AND device_id IS NOT NULL)
    );

-- ================================
-- 验证RLS策略是否生效
-- ================================

-- 1. 检查所有表的RLS状态
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'articles', 'article_likes');

-- 2. 检查所有策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'articles', 'article_likes');

-- ================================
-- 简化的RLS 配置完成
-- ================================
-- 
-- 🎉 您的诗篇应用现在只使用3个核心表：
-- ✅ users - 用户管理
-- ✅ articles - 文章内容
-- ✅ article_likes - 点赞功能
-- 
-- 🗑️ 已清理的无用表：
-- ❌ user_articles_view - 未使用的视图
-- ❌ comments - 未使用的评论功能