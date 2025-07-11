from flask import Blueprint, request, jsonify, current_app
from werkzeug.utils import secure_filename
import os
from models.supabase_client import supabase_client
import time

upload_bp = Blueprint('upload', __name__)

# 允许的文件扩展名
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@upload_bp.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'error': 'No file part'}), 400
    
    file = request.files['file']
    
    if file.filename == '':
        return jsonify({'error': 'No selected file'}), 400
    
    if file and allowed_file(file.filename):
        # 使用时间戳确保文件名唯一
        filename = f"{int(time.time())}_{secure_filename(file.filename)}"
        
        try:
            # 直接上传到Supabase Storage
            # Supabase Python库会自动处理文件类型
            response = supabase_client.supabase.storage.from_('images').upload(
                path=filename,
                file=file.read(),
                file_options={'cache_control': '3600', 'upsert': 'false'}
            )
            
            # 检查Supabase的响应
            if response.status_code != 200:
                # 尝试解析Supabase的错误信息
                try:
                    error_data = response.json()
                    error_message = error_data.get('message', 'Supabase upload failed')
                except:
                    error_message = response.text
                print(f"Supabase upload error: {error_message}")
                return jsonify({'error': f'Supabase upload failed: {error_message}'}), 500

            # 获取上传后的公开URL
            public_url = supabase_client.supabase.storage.from_('images').get_public_url(filename)
            
            return jsonify({'url': public_url}), 200
            
        except Exception as e:
            # 捕获其他可能的异常
            print(f"Upload exception: {str(e)}")
            return jsonify({'error': f'An unexpected error occurred: {str(e)}'}), 500
            
    return jsonify({'error': 'File type not allowed'}), 400