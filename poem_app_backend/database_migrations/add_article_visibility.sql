-- 为articles表添加可见性控制字段
-- 运行时间: 2024-12-19

-- 添加 is_public_visible 字段，默认为 true（公开可见）
ALTER TABLE articles ADD COLUMN IF NOT EXISTS is_public_visible BOOLEAN DEFAULT true;

-- 添加索引以提高查询性能
CREATE INDEX IF NOT EXISTS idx_articles_public_visible ON articles(is_public_visible);

-- 创建组合索引，用于首页查询优化
CREATE INDEX IF NOT EXISTS idx_articles_public_created ON articles(is_public_visible, created_at DESC);

-- 更新现有文章为公开可见（如果字段为null）
UPDATE articles SET is_public_visible = true WHERE is_public_visible IS NULL;