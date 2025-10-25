#!/usr/bin/env python3
"""
创建完整的启动屏图片
包含：渐变背景 + Logo + "诗章"文字

依赖安装:
    pip install -r requirements.txt
"""

import matplotlib.pyplot as plt  # type: ignore
import matplotlib.patches as mpatches  # type: ignore
from matplotlib.patches import FancyBboxPatch  # type: ignore
import numpy as np  # type: ignore
from PIL import Image, ImageDraw, ImageFont
import os

def create_gradient_background(width, height):
    """创建渐变背景"""
    # 创建渐变色数组
    gradient = np.zeros((height, width, 4))
    
    # 定义渐变颜色 (RGBA)
    colors = [
        (0x5A/255, 0x7A/255, 0xFF/255, 1.0),  # 左上角：深蓝色
        (0x6B/255, 0x5B/255, 0xFF/255, 1.0),  # 蓝紫色
        (0x8A/255, 0x5A/255, 0xFF/255, 1.0),  # 深紫色
        (0x6B/255, 0x4B/255, 0xA5/255, 1.0),  # 紫蓝色
    ]
    
    # 创建径向渐变
    for y in range(height):
        for x in range(width):
            # 计算位置比例
            x_ratio = x / width
            y_ratio = y / height
            
            # 对角线渐变
            ratio = (x_ratio + y_ratio) / 2
            
            # 在颜色之间插值
            if ratio < 0.33:
                t = ratio / 0.33
                color = blend_colors(colors[0], colors[1], t)
            elif ratio < 0.67:
                t = (ratio - 0.33) / 0.34
                color = blend_colors(colors[1], colors[2], t)
            else:
                t = (ratio - 0.67) / 0.33
                color = blend_colors(colors[2], colors[3], t)
            
            gradient[y, x] = color
    
    return gradient

def blend_colors(color1, color2, t):
    """混合两个颜色"""
    return tuple(c1 * (1 - t) + c2 * t for c1, c2 in zip(color1, color2))

def create_splash_image():
    """创建完整的启动屏图片"""
    
    # iPhone 尺寸（3x）
    width, height = 1242, 2688  # iPhone 14 Pro Max
    
    print("🎨 创建渐变背景...")
    # 创建背景
    background = create_gradient_background(width, height)
    
    # 转换为 PIL Image
    img = Image.fromarray((background * 255).astype(np.uint8), 'RGBA')
    
    # 添加轻微的遮罩层
    overlay = Image.new('RGBA', (width, height), (0, 0, 0, int(255 * 0.05)))
    img = Image.alpha_composite(img, overlay)
    
    print("🖼️  添加 Logo...")
    # 加载并添加 Logo
    try:
        logo = Image.open('assets/images/poemlogo.png').convert('RGBA')
        logo_size = 300  # 3x scale (100pt * 3)
        logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
        
        # 添加圆角和边框
        logo_with_border = add_border_to_logo(logo, logo_size)
        
        # Logo 位置（居中偏上，35% 位置）
        logo_x = (width - logo_size) // 2
        logo_y = int(height * 0.35) - logo_size // 2
        
        img.paste(logo_with_border, (logo_x, logo_y), logo_with_border)
    except FileNotFoundError:
        print("⚠️  找不到 poemlogo.png，跳过 Logo")
    
    print("✍️  添加 '诗章' 文字...")
    # 添加"诗章"文字
    draw = ImageDraw.Draw(img)
    
    # 尝试使用中文字体
    try:
        # macOS 系统字体路径
        font_paths = [
            '/System/Library/Fonts/PingFang.ttc',
            '/System/Library/Fonts/STHeiti Light.ttc',
            '/System/Library/Fonts/Hiragino Sans GB.ttc',
        ]
        
        font = None
        for font_path in font_paths:
            if os.path.exists(font_path):
                font = ImageFont.truetype(font_path, 108)  # 36pt * 3
                break
        
        if font is None:
            font = ImageFont.load_default()
    except:
        font = ImageFont.load_default()
    
    # "诗章"文字位置（Logo 下方）
    text = "诗章"
    # 获取文字边界框
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    text_x = (width - text_width) // 2
    text_y = logo_y + logo_size + 48  # Logo 下方 16pt * 3
    
    # 绘制文字阴影
    shadow_offset = 3
    draw.text(
        (text_x + shadow_offset, text_y + shadow_offset),
        text,
        font=font,
        fill=(0, 0, 0, int(255 * 0.4))
    )
    
    # 绘制文字
    draw.text(
        (text_x, text_y),
        text,
        font=font,
        fill=(255, 255, 255, 255)
    )
    
    # 保存不同尺寸
    sizes = [
        (width, height, 'LaunchImage@3x.png'),
        (width // 3 * 2, height // 3 * 2, 'LaunchImage@2x.png'),
        (width // 3, height // 3, 'LaunchImage.png'),
    ]
    
    output_dir = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    os.makedirs(output_dir, exist_ok=True)
    
    for w, h, filename in sizes:
        if w == width and h == height:
            output_img = img
        else:
            output_img = img.resize((w, h), Image.Resampling.LANCZOS)
        
        output_path = os.path.join(output_dir, filename)
        output_img.save(output_path, 'PNG')
        print(f"✅ 已保存: {filename} ({w}x{h})")

def add_border_to_logo(logo, size):
    """添加圆角边框到 Logo"""
    # 创建圆角遮罩
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    corner_radius = int(size * 0.18)
    draw.rounded_rectangle([(0, 0), (size, size)], radius=corner_radius, fill=255)
    
    # 应用遮罩
    output = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    output.paste(logo, (0, 0), mask)
    
    # 添加白色边框
    draw = ImageDraw.Draw(output)
    border_width = max(2, int(size * 0.01))
    draw.rounded_rectangle(
        [(0, 0), (size - 1, size - 1)],
        radius=corner_radius,
        outline=(255, 255, 255, int(255 * 0.7)),
        width=border_width
    )
    
    return output

if __name__ == '__main__':
    print("🚀 开始创建启动屏图片...")
    create_splash_image()
    print("✨ 完成！")
