#!/usr/bin/env python3
"""
生成与 splash_screen.dart 一致的渐变背景图
用于原生启动页，确保无缝过渡
"""

from PIL import Image, ImageDraw
import os

def create_gradient_background():
    """创建渐变背景图"""
    
    # iPhone 14 Pro Max 尺寸
    width, height = 1290, 2796
    
    # 创建图片
    img = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(img)
    
    # 定义渐变颜色（与 splash_screen.dart 一致）
    colors = [
        (0x5A, 0x7A, 0xFF),  # 左上角：更深更亮的蓝色
        (0x6B, 0x5B, 0xFF),  # 蓝紫色
        (0x8A, 0x5A, 0xFF),  # 更深的紫色
        (0x6B, 0x4B, 0xA5),  # 紫蓝色
    ]
    
    # 创建对角线渐变
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
            
            draw.point((x, y), fill=color)
    
    # 添加轻微遮罩（与 splash_screen.dart 一致）
    overlay = Image.new('RGBA', (width, height), (0, 0, 0, int(255 * 0.05)))
    img = img.convert('RGBA')
    img = Image.alpha_composite(img, overlay)
    
    # 保存不同尺寸
    output_dir = 'assets/images'
    os.makedirs(output_dir, exist_ok=True)
    
    # 保存原始尺寸（用于 flutter_native_splash）
    output_path = os.path.join(output_dir, 'splash_background.png')
    img.save(output_path, 'PNG')
    print(f'✅ 已生成: {output_path} ({width}x{height})')
    
    # 生成其他尺寸（用于不同设备）
    sizes = [
        (1242, 2688, 'splash_background@3x.png'),
        (828, 1792, 'splash_background@2x.png'),
        (414, 896, 'splash_background@1x.png'),
    ]
    
    for w, h, filename in sizes:
        resized = img.resize((w, h), Image.Resampling.LANCZOS)
        output_path = os.path.join(output_dir, filename)
        resized.save(output_path, 'PNG')
        print(f'✅ 已生成: {filename} ({w}x{h})')

def blend_colors(color1, color2, t):
    """混合两个颜色"""
    return tuple(int(c1 * (1 - t) + c2 * t) for c1, c2 in zip(color1, color2))

if __name__ == '__main__':
    print('🎨 开始生成启动页背景图...')
    create_gradient_background()
    print('✨ 完成！')
    print('\n💡 提示: 运行 `dart run flutter_native_splash:create` 来应用新背景')
