# 腾讯云COS API接口使用指南

## 概述

PoemVerse项目集成了腾讯云COS（对象存储）服务，提供了完整的文件管理API接口。当COS配置正确时，系统会优先使用COS存储文件，否则自动回退到Supabase存储。

## 环境变量配置

在 `.env` 文件中配置以下变量：

```bash
# 腾讯云COS配置
COS_SECRET_ID=your_cos_secret_id      # 腾讯云API密钥ID
COS_SECRET_KEY=your_cos_secret_key    # 腾讯云API密钥Key
COS_REGION=ap-beijing                 # 存储桶所在地域
COS_BUCKET=your_bucket_name          # 存储桶名称
COS_DOMAIN=https://your-domain.com   # 可选，自定义域名
```

## API接口列表

### 1. 检查COS状态
**GET** `/api/cos/status`

检查COS配置和连接状态。

**响应示例：**
```json
{
  "success": true,
  "status": {
    "secret_id": "已配置",
    "secret_key": "已配置", 
    "region": "ap-beijing",
    "bucket": "poemverse-bucket",
    "available": true
  }
}
```

### 2. 上传文件
**POST** `/api/cos/upload`

上传文件到腾讯云COS。

**请求参数：**
- `file`: 文件数据（multipart/form-data）

**响应示例：**
```json
{
  "success": true,
  "url": "https://your-bucket.cos.ap-beijing.myqcloud.com/poemverse/filename.png",
  "filename": "filename.png"
}
```

### 3. 删除文件
**POST** `/api/cos/delete`

从腾讯云COS删除文件。

**请求参数：**
```json
{
  "file_url": "https://your-bucket.cos.ap-beijing.myqcloud.com/poemverse/filename.png"
}
```

**响应示例：**
```json
{
  "success": true,
  "message": "文件删除成功"
}
```

### 4. 获取文件列表
**GET** `/api/cos/list`

获取COS中的文件列表。

**查询参数：**
- `prefix`: 文件前缀过滤（可选）
- `max_keys`: 最大返回数量（默认100）

**响应示例：**
```json
{
  "success": true,
  "files": [
    {
      "key": "poemverse/article_123.png",
      "size": 1024000,
      "last_modified": "2024-01-01T12:00:00",
      "url": "https://your-bucket.cos.ap-beijing.myqcloud.com/poemverse/article_123.png"
    }
  ]
}
```

### 5. 文件迁移
**POST** `/api/cos/migrate`

从Supabase迁移文件到腾讯云COS。

**请求参数：**
```json
{
  "file_urls": [
    "https://supabase.co/storage/v1/object/public/images/file1.jpg",
    "https://supabase.co/storage/v1/object/public/images/file2.png"
  ]
}
```

**响应示例：**
```json
{
  "success": true,
  "results": [
    {
      "original_url": "https://supabase.co/storage/v1/object/public/images/file1.jpg",
      "cos_url": "https://your-bucket.cos.ap-beijing.myqcloud.com/poemverse/file1.jpg",
      "success": true
    }
  ]
}
```

## 使用示例

### Python客户端示例

```python
import requests

# 上传文件
def upload_file(file_path):
    with open(file_path, 'rb') as f:
        files = {'file': f}
        response = requests.post('http://localhost:8080/api/cos/upload', files=files)
        return response.json()

# 删除文件
def delete_file(file_url):
    data = {'file_url': file_url}
    response = requests.post('http://localhost:8080/api/cos/delete', json=data)
    return response.json()

# 获取文件列表
def list_files(prefix='poemverse/'):
    params = {'prefix': prefix, 'max_keys': 50}
    response = requests.get('http://localhost:8080/api/cos/list', params=params)
    return response.json()
```

### JavaScript客户端示例

```javascript
// 上传文件
async function uploadFile(file) {
  const formData = new FormData();
  formData.append('file', file);
  
  const response = await fetch('/api/cos/upload', {
    method: 'POST',
    body: formData
  });
  
  return await response.json();
}

// 删除文件
async function deleteFile(fileUrl) {
  const response = await fetch('/api/cos/delete', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({ file_url: fileUrl })
  });
  
  return await response.json();
}

// 获取文件列表
async function listFiles(prefix = 'poemverse/') {
  const params = new URLSearchParams({
    prefix: prefix,
    max_keys: 50
  });
  
  const response = await fetch(`/api/cos/list?${params}`);
  return await response.json();
}
```

## 错误处理

所有API接口都会返回统一的错误格式：

```json
{
  "error": "错误描述信息"
}
```

常见错误码：
- `400`: 请求参数错误
- `500`: 服务器内部错误

## 测试

运行测试脚本验证COS API功能：

```bash
cd poem_app_backend
python test_cos_api.py
```

## 注意事项

1. **安全性**：确保COS密钥安全，不要提交到版本控制系统
2. **权限**：COS存储桶需要配置适当的访问权限
3. **域名**：建议配置自定义域名以提高访问速度
4. **回退机制**：当COS不可用时，系统会自动使用Supabase存储
5. **文件路径**：所有文件都会存储在 `poemverse/` 前缀下

## 故障排除

### 常见问题

1. **"COS客户端未初始化"**
   - 检查环境变量是否正确配置
   - 确认COS密钥有效

2. **"上传失败"**
   - 检查存储桶权限设置
   - 确认网络连接正常

3. **"删除失败"**
   - 检查文件URL格式是否正确
   - 确认文件确实存在

### 调试方法

1. 检查COS状态：
   ```bash
   curl http://localhost:8080/api/cos/status
   ```

2. 查看日志输出，COS相关操作都有详细的日志记录

3. 使用测试脚本进行功能验证 