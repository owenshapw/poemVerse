from flask import Blueprint, request, jsonify
from models.supabase_client import supabase_client
from utils.cos_client import cos_client  # 导入 COS 客户端

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
    
    # 优先使用腾讯云 COS
    if cos_client.is_available():
        print("使用腾讯云 COS 上传文件")
        content_type = file.content_type or 'application/octet-stream'
        public_url = cos_client.upload_file(
            file_data,
            filename,
            content_type
        )
    else:
        print("COS 不可用，回退到 Supabase")
        # 回退到 Supabase
        bucket = "images"
        # 检查 supabase_client 是否初始化
        if not supabase_client.supabase:
            return jsonify({'error': 'Supabase client 未初始化'}), 500
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