-- 创建点赞记录表
CREATE TABLE IF NOT EXISTS article_likes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    article_id UUID NOT NULL,
    user_id UUID DEFAULT NULL,           -- 登录用户ID（可选）
    device_id VARCHAR(100) DEFAULT NULL, -- 设备唯一标识（匿名用户）
    ip_address INET DEFAULT NULL,        -- IP地址
    is_liked BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- 外键约束
    CONSTRAINT fk_article_likes_article FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
    CONSTRAINT fk_article_likes_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL,
    
    -- 唯一约束：防止重复点赞（用户登录时按user_id，匿名时按device_id）
    CONSTRAINT unique_user_like UNIQUE (article_id, user_id),
    CONSTRAINT unique_device_like UNIQUE (article_id, device_id)
);

-- 创建索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_article_likes_article_id ON article_likes(article_id);
CREATE INDEX IF NOT EXISTS idx_article_likes_user_id ON article_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_article_likes_device_id ON article_likes(device_id);
CREATE INDEX IF NOT EXISTS idx_article_likes_created_at ON article_likes(created_at);

-- 为 articles 表添加 like_count 字段（如果还没有的话）
ALTER TABLE articles ADD COLUMN IF NOT EXISTS like_count INTEGER DEFAULT 0;

-- 创建触发器函数：自动更新文章的点赞计数
CREATE OR REPLACE FUNCTION update_article_like_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- 新增点赞
        UPDATE articles 
        SET like_count = like_count + 1 
        WHERE id = NEW.article_id;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        -- 删除点赞
        UPDATE articles 
        SET like_count = GREATEST(0, like_count - 1) 
        WHERE id = OLD.article_id;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- 更新点赞状态
        IF OLD.is_liked != NEW.is_liked THEN
            IF NEW.is_liked THEN
                -- 从取消点赞变为点赞
                UPDATE articles 
                SET like_count = like_count + 1 
                WHERE id = NEW.article_id;
            ELSE
                -- 从点赞变为取消点赞
                UPDATE articles 
                SET like_count = GREATEST(0, like_count - 1) 
                WHERE id = NEW.article_id;
            END IF;
        END IF;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 创建触发器
DROP TRIGGER IF EXISTS trigger_update_article_like_count ON article_likes;
CREATE TRIGGER trigger_update_article_like_count
    AFTER INSERT OR UPDATE OR DELETE ON article_likes
    FOR EACH ROW EXECUTE FUNCTION update_article_like_count();

-- 初始化现有文章的点赞计数（可选，用于数据迁移）
UPDATE articles 
SET like_count = (
    SELECT COUNT(*) 
    FROM article_likes 
    WHERE article_likes.article_id = articles.id 
    AND article_likes.is_liked = true
)
WHERE like_count = 0 OR like_count IS NULL;