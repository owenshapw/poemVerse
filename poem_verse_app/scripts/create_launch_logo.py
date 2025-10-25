#!/usr/bin/env python3
"""
创建带边框的启动 Logo
生成与 Flutter splash_screen 一致的 Logo + 边框效果

依赖安装:
    pip install -r requirements.txt
"""

from PIL import Image, ImageDraw
import os

def create_launch_logo():
    """创建带圆角白色边框的 Logo"""
    
    # 输入输出路径
    input_path = "assets/images/poemlogo.png"
    output_dir = "ios/Runner/Assets.xcassets/LaunchImage.imageset"
    
    # 确保输出目录存在
    os.makedirs(output_dir, exist_ok=True)
    
    # 生成不同尺寸
    sizes = [
        (100, "LaunchImage.png"),      # 1x
        (200, "LaunchImage@2x.png"),   # 2x
        (300, "LaunchImage@3x.png"),   # 3x
    ]
    
    for size, filename in sizes:
        create_bordered_logo(input_path, os.path.join(output_dir, filename), size)
        print(f"✅ 已创建: {filename} ({size}x{size})")

def create_bordered_logo(input_path, output_path, size):
    """创建带边框的 Logo"""
    
    # 打开原始 Logo
    try:
        logo = Image.open(input_path).convert("RGBA")
    except FileNotFoundError:
        print(f"❌ 错误: 找不到文件 {input_path}")
        return
    
    # 调整 Logo 大小（留出边框空间）
    border_width = max(1, int(size * 0.01))  # 边框宽度 1%
    logo_size = size - border_width * 2
    logo = logo.resize((logo_size, logo_size), Image.Resampling.LANCZOS)
    
    # 创建新画布（透明背景）
    canvas = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    
    # 创建圆角遮罩
    corner_radius = int(size * 0.18)  # 圆角半径 18%
    mask = create_rounded_mask(size, corner_radius)
    
    # 粘贴 Logo 到中心
    logo_pos = (border_width, border_width)
    canvas.paste(logo, logo_pos, logo)
    
    # 应用圆角遮罩
    canvas.putalpha(mask)
    
    # 添加白色边框
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle(
        [(0, 0), (size-1, size-1)],
        radius=corner_radius,
        outline=(255, 255, 255, 180),  # 半透明白色边框
        width=border_width
    )
    
    # 保存
    canvas.save(output_path, 'PNG')

def create_rounded_mask(size, radius):
    """创建圆角遮罩"""
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (size, size)], radius=radius, fill=255)
    return mask

if __name__ == '__main__':
    print("🎨 开始创建带边框的启动 Logo...")
    create_launch_logo()
    print("✅ 完成！")
