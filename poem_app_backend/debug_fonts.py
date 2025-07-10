#!/usr/bin/env python3
"""
调试字体加载问题
"""

import os
from PIL import Image, ImageDraw, ImageFont

def check_fonts():
    """检查字体加载情况"""
    print("=== 字体加载调试 ===\n")
    
    # 测试字体路径
    font_paths = [
        '/System/Library/Fonts/PingFang.ttc',  # macOS
        '/System/Library/Fonts/STHeiti Light.ttc',  # macOS
        '/System/Library/Fonts/Hiragino Sans GB.ttc',  # macOS
        '/System/Library/Fonts/Arial.ttf',  # macOS
        '/System/Library/Fonts/Helvetica.ttc',  # macOS
        'C:/Windows/Fonts/simhei.ttf',  # Windows
        'C:/Windows/Fonts/simsun.ttc',  # Windows
        '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',  # Linux
    ]
    
    print("检查字体文件是否存在:")
    for font_path in font_paths:
        if os.path.exists(font_path):
            print(f"✅ {font_path}")
        else:
            print(f"❌ {font_path}")
    
    print("\n尝试加载字体:")
    title_font = None
    content_font = None
    
    for font_path in font_paths:
        if os.path.exists(font_path):
            try:
                print(f"尝试加载: {font_path}")
                title_font = ImageFont.truetype(font_path, 72)
                content_font = ImageFont.truetype(font_path, 48)
                print(f"✅ 成功加载字体: {font_path}")
                break
            except Exception as e:
                print(f"❌ 加载失败: {e}")
                continue
    
    if not title_font:
        print("⚠️ 所有字体加载失败，使用默认字体")
        title_font = ImageFont.load_default()
        content_font = ImageFont.load_default()
    
    # 测试生成简单图片
    print("\n测试生成图片:")
    try:
        # 创建测试图片
        width = 1200
        height = 1600
        image = Image.new('RGB', (width, height), color=0xFFFFFF)
        draw = ImageDraw.Draw(image)
        
        # 绘制边框
        draw.rectangle([40, 40, width-40, height-40], outline='#8B4513', width=4)
        
        # 绘制标题
        title = "测试标题"
        title_bbox = draw.textbbox((0, 0), title, font=title_font)
        title_width = title_bbox[2] - title_bbox[0]
        title_x = (width - title_width) // 2
        title_y = 120
        
        print(f"标题位置: ({title_x}, {title_y})")
        print(f"标题大小: {title_width} x {title_bbox[3] - title_bbox[1]}")
        
        draw.text((title_x, title_y), title, fill='#2F4F4F', font=title_font)
        
        # 绘制内容
        content = "测试内容\n第二行内容"
        y = title_y + 150
        
        for line in content.split('\n'):
            bbox = draw.textbbox((0, 0), line, font=content_font)
            line_width = bbox[2] - bbox[0]
            x = (width - line_width) // 2
            
            print(f"内容行位置: ({x}, {y})")
            print(f"内容行大小: {line_width} x {bbox[3] - bbox[1]}")
            
            draw.text((x, y), line, fill='#2F4F4F', font=content_font)
            y += 80
        
        # 保存测试图片
        test_filename = "debug_test.png"
        image.save(test_filename, 'PNG', quality=95)
        print(f"✅ 测试图片保存成功: {test_filename}")
        
        # 检查文件大小
        file_size = os.path.getsize(test_filename)
        print(f"文件大小: {file_size} 字节")
        
        return True
        
    except Exception as e:
        print(f"❌ 生成测试图片失败: {e}")
        return False

def test_simple_text():
    """测试简单文本渲染"""
    print("\n=== 简单文本渲染测试 ===\n")
    
    try:
        # 创建小图片测试
        image = Image.new('RGB', (400, 300), color=0xFFFFFF)
        draw = ImageDraw.Draw(image)
        
        # 使用默认字体
        font = ImageFont.load_default()
        
        # 绘制简单文本
        draw.text((50, 50), "Hello World", fill='black', font=font)
        draw.text((50, 100), "测试中文", fill='black', font=font)
        
        # 保存
        image.save("simple_test.png", 'PNG')
        print("✅ 简单文本测试成功")
        
        return True
        
    except Exception as e:
        print(f"❌ 简单文本测试失败: {e}")
        return False

if __name__ == "__main__":
    print("开始字体调试...\n")
    
    # 测试简单文本
    simple_success = test_simple_text()
    
    # 测试完整字体
    font_success = check_fonts()
    
    print(f"\n=== 调试结果 ===")
    print(f"简单文本测试: {'✅ 成功' if simple_success else '❌ 失败'}")
    print(f"字体加载测试: {'✅ 成功' if font_success else '❌ 失败'}")
    
    if not font_success:
        print("\n建议:")
        print("1. 检查系统字体是否安装")
        print("2. 尝试使用默认字体")
        print("3. 安装中文字体包") 