# AI图片生成API配置说明

## 支持的AI图片生成服务

### 1. Stability AI (推荐)
- **免费额度**: 每月25张图片
- **注册地址**: https://platform.stability.ai/
- **API文档**: https://platform.stability.ai/docs/api-reference

#### 配置步骤:
1. 访问 https://platform.stability.ai/
2. 注册账号并验证邮箱
3. 进入API Keys页面
4. 创建新的API Key
5. 将API Key添加到环境变量

### 2. Hugging Face (备用)
- **免费额度**: 每月1000次请求
- **注册地址**: https://huggingface.co/
- **API文档**: https://huggingface.co/docs/api-inference

#### 配置步骤:
1. 访问 https://huggingface.co/
2. 注册账号
3. 进入Settings -> Access Tokens
4. 创建新的Token
5. 将Token添加到环境变量

## 环境变量配置

在 `.env` 文件中添加以下配置:

```bash
# Stability AI API Key (推荐)
STABILITY_API_KEY=your_stability_api_key_here

# Hugging Face API Key (备用)
HF_API_KEY=your_huggingface_api_key_here
```

## 使用说明

1. **优先使用Stability AI**: 图片质量更高，支持1024x1024分辨率
2. **自动回退**: 如果AI生成失败，会自动使用文字排版作为备选
3. **智能提示词**: 系统会根据诗词内容自动生成合适的AI提示词

## 提示词生成逻辑

系统会根据以下内容生成AI提示词:

### 标题关键词识别:
- 春 → spring landscape, cherry blossoms
- 秋 → autumn landscape, golden leaves  
- 雪 → winter snow, white landscape
- 月 → moonlight, night sky
- 山 → mountain landscape, peaks
- 水/江/河 → river, water, flowing stream
- 花 → flowers, blooming

### 情感关键词识别:
- 愁/悲/泪/伤 → melancholy mood, soft lighting
- 喜/乐/欢/笑 → joyful mood, bright colors
- 思/念/忆/怀 → nostalgic mood, dreamy atmosphere

### 标签主题识别:
- 自然/风景 → natural landscape, scenic view
- 情感/爱情 → romantic atmosphere
- 历史/古风 → ancient Chinese style

## 示例

对于诗词《沁园春·雪》:
- 标题包含"雪" → winter snow, white landscape
- 内容包含"北国风光" → natural landscape
- 生成提示词: "Beautiful Chinese traditional painting style, winter snow, white landscape, natural landscape, high quality, detailed, artistic"

## 故障排除

1. **API Key无效**: 检查环境变量是否正确设置
2. **生成失败**: 查看后端日志，确认API调用状态
3. **图片质量差**: 可以调整提示词或使用不同的AI服务 