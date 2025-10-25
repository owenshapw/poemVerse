#!/usr/bin/env python3
"""
生成"诗章"文字图片
用于原生启动页的品牌文字显示
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_app_title():
    """创建"诗章"文字图片"""
    
    # 图片尺寸（足够显示文字）
    width, height = 300, 100
    
    # 创建透明背景
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 文字内容
    text = "诗章"
    
    # 尝试使用中文字体
    try:
        # macOS 系统字体路径
        font_paths = [
            '/System/Library/Fonts/PingFang.ttc',
            '/System/Library/Fonts/STHeiti Light.ttc',
            '/System/Library/Fonts/Hiragino Sans GB.ttc',
            # 如果有自定义字体
            '../assets/fonts/FZZhaoGYJW-R.ttf',
        ]
        
        font = None
        for font_path in font_paths:
            full_path = os.path.join(os.path.dirname(__file__), font_path)
            if os.path.exists(full_path):
                font = ImageFont.truetype(full_path, 72)  # 36pt * 2
                print(f'✅ 使用字体: {font_path}')
                break
        
        if font is None:
            print('⚠️  未找到中文字体，使用默认字体')
            font = ImageFont.load_default()
    except Exception as e:
        print(f'⚠️  加载字体失败: {e}')
        font = ImageFont.load_default()
    
    # 计算文字位置（居中）
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    text_x = (width - text_width) // 2
    text_y = (height - text_height) // 2
    
    # 绘制文字阴影
    shadow_offset = 2
    draw.text(
        (text_x + shadow_offset, text_y + shadow_offset),
        text,
        font=font,
        fill=(0, 0, 0, int(255 * 0.4))
    )
    
    # 绘制白色文字
    draw.text(
        (text_x, text_y),
        text,
        font=font,
        fill=(255, 255, 255, 255)
    )
    
    # 裁剪到实际文字大小
    img = img.crop((
        text_x - 10,
        text_y - 10,
        text_x + text_width + 10,
        text_y + text_height + 10
    ))
    
    # 保存
    output_dir = 'assets/images'
    os.makedirs(output_dir, exist_ok=True)
    
    output_path = os.path.join(output_dir, 'app_title.png')
    img.save(output_path, 'PNG')
    print(f'✅ 已生成: {output_path} ({img.width}x{img.height})')
    
    # 生成不同尺寸
    sizes = [
        (3, 'app_title@3x.png'),
        (2, 'app_title@2x.png'),
        (1, 'app_title@1x.png'),
    ]
    
    for scale, filename in sizes:
        scaled_width = img.width * scale
        scaled_height = img.height * scale
        resized = img.resize((scaled_width, scaled_height), Image.Resampling.LANCZOS)
        output_path = os.path.join(output_dir, filename)
        resized.save(output_path, 'PNG')
        print(f'✅ 已生成: {filename} ({scaled_width}x{scaled_height})')

if __name__ == '__main__':
    print('✍️  开始生成"诗章"文字图片...')
    create_app_title()
    print('✨ 完成！')
    print('\n💡 提示: 运行 `dart run flutter_native_splash:create` 来应用新图片')
