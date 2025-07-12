from flask import Blueprint, request, jsonify
from models.supabase_client import supabase_client
from utils.cos_client import cos_client
import os

cos_bp = Blueprint('cos', __name__)

@cos_bp.route('/api/cos/upload', methods=['POST'])
def cos_upload():
    """上传文件到腾讯云COS"""
    if 'file' not in request.files:
        return jsonify({'error': '没有文件'}), 400
    
    file = request.files['file']
    if not file or not file.filename:
        return jsonify({'error': '文件无效'}), 400
    
    try:
        file_data = file.read()
        content_type = file.content_type or 'application/octet-stream'
        
        # 使用COS客户端上传
        public_url = cos_client.upload_file(
            file_data,
            file.filename,
            content_type
        )
        
        if public_url:
            return jsonify({
                'success': True,
                'url': public_url,
                'filename': file.filename
            })
        else:
            return jsonify({'error': '上传失败'}), 500
            
    except Exception as e:
        print(f"COS上传错误: {str(e)}")
        return jsonify({'error': f'上传失败: {str(e)}'}), 500

@cos_bp.route('/api/cos/delete', methods=['POST'])
def cos_delete():
    """从腾讯云COS删除文件"""
    try:
        data = request.get_json()
        file_url = data.get('file_url')
        
        if not file_url:
            return jsonify({'error': '文件URL不能为空'}), 400
        
        success = cos_client.delete_file(file_url)
        
        if success:
            return jsonify({'success': True, 'message': '文件删除成功'})
        else:
            return jsonify({'error': '文件删除失败'}), 500
            
    except Exception as e:
        print(f"COS删除错误: {str(e)}")
        return jsonify({'error': f'删除失败: {str(e)}'}), 500

@cos_bp.route('/api/cos/list', methods=['GET'])
def cos_list():
    """获取腾讯云COS文件列表"""
    try:
        prefix = request.args.get('prefix', '')
        max_keys = int(request.args.get('max_keys', 100))
        
        files = cos_client.list_files(prefix, max_keys)
        
        return jsonify({
            'success': True,
            'files': files
        })
        
    except Exception as e:
        print(f"COS列表错误: {str(e)}")
        return jsonify({'error': f'获取文件列表失败: {str(e)}'}), 500

@cos_bp.route('/api/cos/status', methods=['GET'])
def cos_status():
    """检查腾讯云COS状态"""
    try:
        is_available = cos_client.is_available()
        config_info = {
            'secret_id': '已配置' if os.getenv('COS_SECRET_ID') else '未配置',
            'secret_key': '已配置' if os.getenv('COS_SECRET_KEY') else '未配置',
            'region': os.getenv('COS_REGION', '未配置'),
            'bucket': os.getenv('COS_BUCKET', '未配置'),
            'available': is_available
        }
        
        return jsonify({
            'success': True,
            'status': config_info
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'error': str(e)
        }), 500

@cos_bp.route('/api/cos/migrate', methods=['POST'])
def cos_migrate():
    """从Supabase迁移文件到腾讯云COS"""
    try:
        data = request.get_json()
        file_urls = data.get('file_urls', [])
        
        if not file_urls:
            return jsonify({'error': '文件URL列表不能为空'}), 400
        
        results = []
        for file_url in file_urls:
            try:
                # 从URL中提取文件名
                filename = file_url.split('/')[-1]
                
                # 下载文件
                import requests
                response = requests.get(file_url)
                if response.status_code == 200:
                    # 上传到COS
                    public_url = cos_client.upload_file(
                        response.content,
                        filename,
                        'application/octet-stream'
                    )
                    
                    results.append({
                        'original_url': file_url,
                        'cos_url': public_url,
                        'success': True
                    })
                else:
                    results.append({
                        'original_url': file_url,
                        'success': False,
                        'error': f'下载失败: {response.status_code}'
                    })
                    
            except Exception as e:
                results.append({
                    'original_url': file_url,
                    'success': False,
                    'error': str(e)
                })
        
        return jsonify({
            'success': True,
            'results': results
        })
        
    except Exception as e:
        print(f"迁移错误: {str(e)}")
        return jsonify({'error': f'迁移失败: {str(e)}'}), 500 