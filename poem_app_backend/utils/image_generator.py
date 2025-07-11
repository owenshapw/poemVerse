import os
import uuid
from PIL import Image, ImageDraw, ImageFont
from flask import current_app
import requests
from io import BytesIO
import random
from models.supabase_client import supabase_client
import io

def generate_article_image(article, is_preview=False):
    """生成文章排版图片并上传到Supabase"""
    try:
        # ... [前面的图片生成代码保持不变] ...
        # 创建图片 - 使用更大的尺寸
        width = 1200  # 增加宽度
        height = 1600  # 增加高度

        # 创建白色背景
        image = Image.new('RGB', (width, height), color=0xFFFFFF)
        draw = ImageDraw.Draw(image)

        # 尝试加载中文字体，使用更大的字号
        try:
            # 尝试不同的中文字体路径
            font_paths = [
                '/System/Library/Fonts/PingFang.ttc',  # macOS
                '/System/Library/Fonts/STHeiti Light.ttc',  # macOS
                '/System/Library/Fonts/Hiragino Sans GB.ttc',  # macOS
                'C:/Windows/Fonts/simhei.ttf',  # Windows
                'C:/Windows/Fonts/simsun.ttc',  # Windows
                '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',  # Linux
            ]
            
            title_font = None
            content_font = None
            author_font = None
            
            for font_path in font_paths:
                if os.path.exists(font_path):
                    try:
                        title_font = ImageFont.truetype(font_path, 72)  # 标题字体增大
                        content_font = ImageFont.truetype(font_path, 48)  # 内容字体增大
                        author_font = ImageFont.truetype(font_path, 36)  # 作者字体
                        break
                    except:
                        continue
            
            if not title_font:
                title_font = ImageFont.load_default()
                content_font = ImageFont.load_default()
                author_font = ImageFont.load_default()
                
        except Exception as e:
            print(f"字体加载失败: {e}")
            title_font = ImageFont.load_default()
            content_font = ImageFont.load_default()
            author_font = ImageFont.load_default()
        
        # 绘制装饰边框 - 更优雅的边框
        border_width = 40
        draw.rectangle([border_width, border_width, width-border_width, height-border_width], 
                      outline='#8B4513', width=4)
        
        # 绘制内边框
        inner_border = 80
        draw.rectangle([inner_border, inner_border, width-inner_border, height-inner_border], 
                      outline='#D2691E', width=2)
        
        # 绘制标题
        title = str(article['title'])  # 确保是字符串
        try:
            title_bbox = draw.textbbox((0, 0), title, font=title_font)
            title_width = title_bbox[2] - title_bbox[0]
            title_height = title_bbox[3] - title_bbox[1]
            title_x = (width - title_width) // 2
            title_y = 120
            
            # 标题背景
            title_bg_padding = 20
            draw.rectangle([
                title_x - title_bg_padding, 
                title_y - title_bg_padding, 
                title_x + title_width + title_bg_padding, 
                title_y + title_height + title_bg_padding
            ], fill='#F5F5DC', outline='#8B4513', width=2)
            
            draw.text((title_x, title_y), title, fill='#2F4F4F', font=title_font)
        except Exception as e:
            print(f"绘制标题失败: {e}")
            # 使用默认位置绘制标题
            draw.text((width//2 - 100, title_y), title, fill='#2F4F4F', font=title_font)

        # 绘制装饰性分隔线
        line_y = int((title_y or 120) + (title_height or 0) + 60)
        # 上分隔线
        draw.line([(150, line_y), (width-150, line_y)], fill='#8B4513', width=3)
        # 装饰点
        for i in range(5):
            x = 200 + i * 160
            draw.ellipse([x-3, line_y-3, x+3, line_y+3], fill='#D2691E')
            x = 200 + i * 160
            draw.ellipse([x-3, line_y-3, x+3, line_y+3], fill='#D2691E')
        
        # 绘制作者信息
        author = article.get('author', '')
        if author:
            author_text = f"作者：{author}"
            author_bbox = draw.textbbox((0, 0), author_text, font=author_font)
            author_width = author_bbox[2] - author_bbox[0]
            author_x = (width - author_width) // 2
            author_y = line_y + 40
            
            draw.text((author_x, author_y), author_text, fill='#696969', font=author_font)
            content_start_y = author_y + 80
        else:
            content_start_y = line_y + 80
        
        # 绘制正文内容 - 改进中文文本处理
        content = article['content']
        max_width = width - 200  # 左右各留100px边距
        line_height = 80  # 增加行高
        
        # 中文文本换行处理 - 按字符分割，每行最多15个字符
        lines = []
        current_line = ""
        char_count = 0
        max_chars_per_line = 15
        
        for char in content:
            if char == '\n':
                if current_line:
                    lines.append(current_line)
                current_line = ""
                char_count = 0
            elif char == ' ' or char == '，' or char == '。' or char == '！' or char == '？':
                current_line += char
                char_count += 1
                if char_count >= max_chars_per_line:
                    lines.append(current_line)
                    current_line = ""
                    char_count = 0
            else:
                current_line += char
                char_count += 1
                if char_count >= max_chars_per_line:
                    lines.append(current_line)
                    current_line = ""
                    char_count = 0
        
        if current_line:
            lines.append(current_line)
        
        # 绘制每一行
        y = content_start_y
        for i, line in enumerate(lines):
            if y > height - 200:  # 避免超出底部
                break
            
            # 居中对齐
            bbox = draw.textbbox((0, 0), line, font=content_font)
            line_width = bbox[2] - bbox[0]
            x = (width - line_width) // 2
            
            # 为每行添加轻微的背景
            line_bg_padding = 10
            draw.rectangle([
                x - line_bg_padding, 
                y - line_bg_padding, 
                x + line_width + line_bg_padding, 
                y + bbox[3] - bbox[1] + line_bg_padding
            ], fill='#FAFAF0', outline='#F0E68C', width=1)
            
            draw.text((x, y), line, fill='#2F4F4F', font=content_font)
            y += line_height
        
        # 绘制标签
        tags = article.get('tags', [])
        if tags:
            tag_y = height - 120
            tag_text = "标签：" + "，".join(tags)
            tag_bbox = draw.textbbox((0, 0), tag_text, font=author_font)
            tag_width = tag_bbox[2] - tag_bbox[0]
            tag_x = (width - tag_width) // 2
            
            # 标签背景
            tag_bg_padding = 15
            draw.rectangle([
                tag_x - tag_bg_padding, 
                tag_y - tag_bg_padding, 
                tag_x + tag_width + tag_bg_padding, 
                tag_y + tag_bbox[3] - tag_bbox[1] + tag_bg_padding
            ], fill='#F0F8FF', outline='#87CEEB', width=2)
            
            draw.text((tag_x, tag_y), tag_text, fill='#4682B4', font=author_font)
        
        # 绘制页码和装饰
        page_text = "诗篇"
        page_bbox = draw.textbbox((0, 0), page_text, font=author_font)
        page_width = page_bbox[2] - page_bbox[0]
        page_x = (width - page_width) // 2
        page_y = height - 60
        
        # 页码背景
        page_bg_padding = 10
        draw.rectangle([
            page_x - page_bg_padding, 
            page_y - page_bg_padding, 
            page_x + page_width + page_bg_padding, 
            page_y + page_bbox[3] - page_bbox[1] + page_bg_padding
        ], fill='#FFF8DC', outline='#DAA520', width=2)
        
        draw.text((page_x, page_y), page_text, fill='#8B4513', font=author_font)

        # 将图片保存到内存缓冲区
        buffer = io.BytesIO()
        image.save(buffer, format='PNG', quality=95)
        buffer.seek(0)

        # 定义文件名和存储桶
        if is_preview:
            filename = f"preview_{uuid.uuid4().hex}.png"
        else:
            filename = f"article_{uuid.uuid4().hex}.png"
        
        bucket_name = "images"

        # 上传到Supabase Storage
        supabase_client.supabase.storage.from_(bucket_name).upload(
            path=filename,
            file=buffer.read(),
            file_options={'content-type': 'image/png', 'upsert': 'true'}
        )

        # 获取公开URL
        public_url = supabase_client.supabase.storage.from_(bucket_name).get_public_url(filename)
        
        return public_url
        
    except Exception as e:
        print(f"生成图片并上传失败: {str(e)}")
        import traceback
        traceback.print_exc()
        return None


def generate_background_image():
    """生成背景图片（可选功能）"""
    try:
        # 这里可以集成AI图片生成服务，如Stability AI或OpenAI DALL-E
        # 目前返回一个简单的渐变背景
        
        width = current_app.config['IMAGE_WIDTH']
        height = current_app.config['IMAGE_HEIGHT']
        
        # 创建渐变背景
        image = Image.new('RGB', (width, height))
        draw = ImageDraw.Draw(image)
        
        # 简单的渐变效果
        for y in range(height):
            r = int(255 * (1 - y / height))
            g = int(240 * (1 - y / height))
            b = int(230 * (1 - y / height))
            draw.line([(0, y), (width, y)], fill=(r, g, b))
        
        return image
        
    except Exception as e:
        print(f"生成背景图片失败: {str(e)}")
        return None

def add_watermark(image, watermark_text="诗篇"):
    """添加水印"""
    try:
        draw = ImageDraw.Draw(image)
        
        # 尝试加载字体
        try:
            font = ImageFont.truetype('/System/Library/Fonts/PingFang.ttc', 20)
        except:
            font = ImageFont.load_default()
        
        # 计算水印位置（右下角）
        bbox = draw.textbbox((0, 0), watermark_text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        
        x = image.width - text_width - 20
        y = image.height - text_height - 20
        
        # 绘制半透明水印
        draw.text((x, y), watermark_text, fill='#808080', font=font)
        
    except Exception as e:
        print(f"添加水印失败: {str(e)}") 
        return image 