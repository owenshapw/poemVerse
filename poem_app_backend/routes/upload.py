from flask import Blueprint, request, jsonify
from models.supabase_client import supabase_client

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
    bucket = "images"
    file_data = file.read()
    # 检查 supabase_client 是否初始化
    if not supabase_client.supabase:
        return jsonify({'error': 'Supabase client 未初始化'}), 500
    storage = supabase_client.supabase.storage
    res = storage.from_(bucket).upload(filename, file_data, {"content-type": file.mimetype})
    # 检查返回值是否有 error 属性
    if isinstance(res, dict) and res.get("error"):
        return jsonify({'error': res["error"]["message"]}), 500
    # 获取公开URL
    public_url = storage.from_(bucket).get_public_url(filename)
    return jsonify({'url': public_url})