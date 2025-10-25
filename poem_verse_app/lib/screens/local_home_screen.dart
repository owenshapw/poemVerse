import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
import 'package:poem_verse_app/screens/local_poems_screen.dart';
import 'package:poem_verse_app/screens/create_article_screen.dart';
import 'package:poem_verse_app/services/local_storage_service.dart';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:poem_verse_app/utils/network_init_helper.dart';

/// 本地模式主页 - 欢迎页面（整合了splash动画）
class LocalHomeScreen extends StatefulWidget {
  final bool showTypingAnimation; // 是否显示打字动画
  
  const LocalHomeScreen({
    super.key,
    this.showTypingAnimation = true, // 默认显示
  });

  @override
  State<LocalHomeScreen> createState() => _LocalHomeScreenState();
}

class _LocalHomeScreenState extends State<LocalHomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // 打字动画相关
  final String _fullText = '在灯下读你，仿佛在夜中读光';
  int _currentIndex = 0;
  bool _showSubtitle = false; // 是否显示副标题
  bool _showButtons = false; // 是否显示按钮
  double _subtitleOpacity = 1.0;
  double _buttonsOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    
    // 动画控制器
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 淡入动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    // 缩放动画
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    
    // 启动动画流程
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.showTypingAnimation) {
        // 显示打字动画
        Timer(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              _showSubtitle = true;
            });
            _startTypingAnimation();
          }
        });
      } else {
        // 直接显示按钮
        setState(() {
          _showButtons = true;
          _buttonsOpacity = 1.0;
        });
      }
    });
  }
  
  void _startTypingAnimation() {
    debugPrint('⌨️ 开始打字动画');
    Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (_currentIndex < _fullText.length) {
        if (mounted) {
          setState(() {
            _currentIndex++;
          });
          if (_currentIndex == _fullText.length) {
            debugPrint('✅ 打字动画完成');
            // 打字完成后等待1秒，然后淡出副标题，淡入按钮
            Timer(const Duration(milliseconds: 1000), () {
              if (mounted) {
                _fadeOutSubtitleAndShowButtons();
              }
            });
          }
        }
      } else {
        timer.cancel();
      }
    });
  }
  
  /// 处理云端创作按钮点击（按需初始化网络）
  Future<void> _handleCloudCreation() async {
    if (!mounted) return;
    
    debugPrint('🌐 用户点击云端创作，开始按需初始化网络服务...');
    
    // 使用工具函数初始化网络服务
    final success = await NetworkInitHelper.ensureNetworkInitialized(context);
    
    if (success && mounted) {
      // 初始化成功，跳转到登录页
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
    // 如果初始化失败，工具函数已经显示错误提示
  }
  
  void _fadeOutSubtitleAndShowButtons() {
    debugPrint('🎭 开始淡出副标题，淡入按钮');
    // 淡出副标题
    setState(() {
      _subtitleOpacity = 0.0;
    });
    
    // 500ms后淡入按钮
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _showSubtitle = false;
          _showButtons = true;
        });
        // 延迟一点再开始淡入，让过渡更自然
        Timer(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              _buttonsOpacity = 1.0;
            });
            
            // 🔴 完全不初始化网络服务，等待用户主动触发
            debugPrint('✅ 动画完成，按钮已显示，等待用户操作');
          }
        });
      }
    });
  }
  


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          // 深邃鲜艳的渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5A7AFF), // 更深更亮的蓝色
                  Color(0xFF6B5BFF), // 更鲜艳的蓝紫色
                  Color(0xFF8A5AFF), // 更深的紫色
                  Color(0xFF6B4BA5), // 更深的紫蓝色
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          // 轻微的遮罩层，保持透亮感
          Container(
            color: Colors.black.withValues(alpha: 0.05),
          ),
          // 整体的宝石光泽叠加
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topLeft,
                radius: 1.5,
                colors: [
                  Colors.white.withValues(alpha: 0.15),
                  Colors.white.withValues(alpha: 0.05),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
          // 台灯光线效果
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: CustomPaint(
                  size: Size(
                    MediaQuery.of(context).size.width,
                    MediaQuery.of(context).size.height,
                  ),
                  painter: DeskLampPainter(),
                ),
              );
            },
          ),
          // 主要内容
          SafeArea(
            child: Column(
              children: [
                // 上半部分 - Logo和标题区域
                Expanded(
                  flex: 45,
                  child: Align(
                    alignment: const Alignment(-0.1, 0.4),
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // APP Logo
                                Container(
                                  width: 120,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Center(
                                    child: Container(
                                      width: 101,
                                      height: 101,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18.5),
                                        gradient: SweepGradient(
                                          center: Alignment.center,
                                          startAngle: 0,
                                          endAngle: 6.28,
                                          colors: [
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.4),
                                            Colors.white.withValues(alpha: 0.7),
                                            Colors.white.withValues(alpha: 0.4),
                                            Colors.transparent,
                                            Colors.transparent,
                                            Colors.white.withValues(alpha: 0.4),
                                            Colors.white.withValues(alpha: 0.7),
                                            Colors.white.withValues(alpha: 0.4),
                                            Colors.transparent,
                                          ],
                                          stops: const [0.0, 0.125, 0.1875, 0.25, 0.375, 0.5, 0.625, 0.6875, 0.75, 0.875],
                                        ),
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.all(0.5),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(18),
                                          child: Image.asset(
                                            'assets/images/poemlogo.png',
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // 诗章标题
                                SizedBox(
                                  width: 120,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '诗',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'FZZhaoGYJW-R',
                                          height: 1.0,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.4),
                                              offset: const Offset(1, 1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '章',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 36,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'FZZhaoGYJW-R',
                                          height: 1.0,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black.withValues(alpha: 0.4),
                                              offset: const Offset(1, 1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 中间部分 - 副标题区域（打字动画）
                Expanded(
                  flex: 15,
                  child: Align(
                    alignment: const Alignment(0.0, -0.5),
                    child: AnimatedOpacity(
                      opacity: _subtitleOpacity,
                      duration: const Duration(milliseconds: 500),
                      child: _showSubtitle
                          ? Container(
                              height: 40,
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_fullText.length, (index) {
                                  return AnimatedOpacity(
                                    opacity: index < _currentIndex ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    child: Text(
                                      _fullText[index],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.2,
                                        fontFamily: 'FZZhaoGYJW-R',
                                        height: 1.4,
                                        shadows: [
                                          Shadow(
                                            color: Colors.black.withValues(alpha: 0.5),
                                            offset: const Offset(1, 1),
                                            blurRadius: 3,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
                // 下半部分 - 按钮区域（淡入效果）
                Expanded(
                  flex: 40,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _buttonsOpacity,
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeInOut,
                        child: _showButtons
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // 本地创作按钮
                                  _buildActionButton(
                                    label: '本地创作',
                                    onTap: () async {
                                      // 检查是否有本地诗章
                                      final poemsCount = LocalStorageService.getPoemsCount();
                                      
                                      if (poemsCount == 0) {
                                        // 第一次使用，直接跳转到创作页面
                                        if (!mounted) return;
                                        final navigator = Navigator.of(context);
                                        final result = await navigator.push(
                                          MaterialPageRoute(
                                            builder: (_) => const CreateArticleScreen(isLocalMode: true),
                                          ),
                                        );
                                        
                                        // 创作完成后，跳转到列表页面
                                        if (result == true && mounted) {
                                          navigator.pushReplacement(
                                            MaterialPageRoute(
                                              builder: (_) => const LocalPoemsScreen(),
                                            ),
                                          );
                                        }
                                      } else {
                                        // 已有诗章，跳转到列表页面
                                        if (!mounted) return;
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const LocalPoemsScreen(),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  // 云端创作按钮
                                  _buildActionButton(
                                    label: '云端创作',
                                  onTap: () => _handleCloudCreation(),
                                                                      isSecondary: true,
                                  ),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback onTap,
    bool isSecondary = false,
  }) {
    return Container(
      width: 240,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isSecondary ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.1),
          highlightColor: Colors.white.withValues(alpha: 0.05),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 台灯光线绘制器
class DeskLampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 光源位置（在左上角外侧）
    const lightSourceX = -0.35;
    const lightSourceY = -0.25;
    final actualLightSourceX = size.width * lightSourceX;
    final actualLightSourceY = size.height * lightSourceY;
    
    // 20度扇形参数
    const fanAngle = math.pi / 7;
    final fanRadius = math.sqrt(size.width * size.width + size.height * size.height) * 1.4;
    const startAngle = 45 * math.pi / 180;
    
    // 创建扇形路径
    final fanPath = Path();
    fanPath.moveTo(actualLightSourceX, actualLightSourceY);
    fanPath.arcTo(
      Rect.fromCircle(
        center: Offset(actualLightSourceX, actualLightSourceY),
        radius: fanRadius,
      ),
      startAngle,
      fanAngle,
      false,
    );
    fanPath.close();
    
    // 创建扇形渐变效果
    final gradient = ui.Gradient.radial(
      Offset(actualLightSourceX, actualLightSourceY), 
      fanRadius,
      [
        Colors.white.withValues(alpha: 0.18),
        Colors.white.withValues(alpha: 0.15),
        Colors.white.withValues(alpha: 0.12),
        Colors.white.withValues(alpha: 0.08),
        Colors.white.withValues(alpha: 0.04),
        Colors.transparent,
      ],
      [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
    );
    
    paint.shader = gradient;
    
    // 绘制扇形台灯光线
    canvas.drawPath(fanPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
