# poem_app_backend/batch_regenerate_images.py
from models.supabase_client import supabase_client
from config import Config
from utils.image_generator import generate_article_image
from utils.ai_image_generator import ai_generator
from flask import Flask

app = Flask(__name__)
app.config.from_object(Config())
supabase_client.init_app(app)

with app.app_context():
    if supabase_client.supabase is None:
        print("❌ Supabase 客户端初始化失败")
    else:
        articles = supabase_client.supabase.table('articles').select('*').execute().data
        print(f"共 {len(articles)} 篇文章，开始批量重生成图片...")
        for article in articles:
            try:
                # 先用AI生成，失败则用传统排版
                image_url = ai_generator.generate_poem_image(article)
                if not image_url:
                    image_url = generate_article_image(article)
                if image_url:
                    supabase_client.update_article_image(article['id'], image_url)
                    print(f"✅ 文章《{article['title']}》图片已重生成: {image_url}")
                else:
                    print(f"❌ 文章《{article['title']}》图片生成失败")
            except Exception as e:
                print(f"❌ 文章《{article['title']}》处理异常: {e}") 