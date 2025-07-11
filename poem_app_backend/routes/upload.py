from flask import Blueprint, request, jsonify
from models.supabase_client import supabase_client
from utils.cloudflare_client import cloudflare_client  # 导入 Cloudflare 客户端
import os # 导入 os 模块

upload_bp = Blueprint('upload', __name__)

@upload_bp.route('/api/upload_image', methods=['POST'])
def upload_image():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    file = request.files['file']
    if not file or not file.filename:
        return jsonify({'error': 'No selected file'}), 400

    filename = file.filename
    if not filename:
        return jsonify({'error': 'Invalid filename'}), 400
    
    file_data = file.read()
    
    # 优先使用 Cloudflare Images
    if cloudflare_client.is_available():
        print("使用 Cloudflare Images 上传文件")
        content_type = file.content_type or 'application/octet-stream'
        public_url = cloudflare_client.upload_file(
            file_data,
            filename,
            content_type
        )
    else:
        print("Cloudflare Images 不可用，回退到 Supabase")
        # 回退到 Supabase
        bucket = "images"
        # 检查 supabase_client 是否初始化
        if not supabase_client.supabase:
            print("⚠️ Supabase 客户端未初始化，尝试重新初始化...")
            try:
                from supabase.client import create_client
                supabase_url = os.getenv("SUPABASE_URL")
                supabase_key = os.getenv("SUPABASE_KEY")
                if supabase_url and supabase_key:
                    supabase_client.supabase = create_client(supabase_url, supabase_key)
                    print("✅ Supabase 客户端重新初始化成功")
                else:
                    return jsonify({'error': 'Supabase 环境变量未配置'}), 500
            except Exception as e:
                print(f"❌ Supabase 客户端重新初始化失败: {e}")
                return jsonify({'error': 'Supabase 客户端初始化失败'}), 500
        
        # 再次检查客户端是否可用
        if not supabase_client.supabase:
            return jsonify({'error': 'Supabase 客户端仍然不可用'}), 500
            
        storage = supabase_client.supabase.storage
        content_type = file.content_type or 'application/octet-stream'
        res = storage.from_(bucket).upload(filename, file_data, {"content-type": content_type})
        # 检查返回值是否有 error 属性
        if isinstance(res, dict) and res.get("error"):
            return jsonify({'error': res["error"]["message"]}), 500
        # 获取公开URL
        public_url = storage.from_(bucket).get_public_url(filename)
    
    if public_url:
        return jsonify({'url': public_url})
    else:
        return jsonify({'error': '文件上传失败'}), 500