// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final String _fullText = '在灯下读你，仿佛在夜中读光';
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    
    // 设置状态栏
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

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

    // 延迟1秒后开始打字动画
    Timer(const Duration(milliseconds: 1000), () {
      _startTypingAnimation();
    });

    // 5.5秒后跳转到主页
    Timer(const Duration(milliseconds: 5500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  void _startTypingAnimation() {
    Timer.periodic(const Duration(milliseconds: 180), (timer) {
      if (_currentIndex < _fullText.length) {
        if (mounted) {
          setState(() {
            _currentIndex++;
          });
        }
      } else {
        timer.cancel();
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
    return Scaffold(
      body: Stack(
        children: [
          // 宝石般透亮的渐变背景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667eea),
                  Color(0xFF7b68ee),
                  Color(0xFF9370db),
                  Color(0xFF764ba2),
                ],
                stops: [0.0, 0.3, 0.7, 1.0],
              ),
            ),
          ),
          // 轻微的遮罩层，保持透亮感
          Container(
            color: Colors.black.withValues(alpha: 0.08),
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
          // 台灯光线效果 - 从"诗篇"向下照射（先绘制，被文字遮挡）
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
          // 主要内容布局（文字在最上层，遮挡扇面）
          SafeArea(
            child: Column(
              children: [
                // 上半部分 - 标题区域
                Expanded(
                  flex: 45,
                  child: Align(
                    alignment: const Alignment(0.0, 0.33), // 中心偏下1/3位置
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Text(
                              '诗篇',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 68,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 24,
                                fontFamily: 'FZZhaoGYJW-R',
                                height: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    offset: const Offset(1, 1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // 中间部分 - 副标题区域（上移显示）
                Expanded(
                  flex: 15,
                  child: Align(
                    alignment: const Alignment(0.0, -0.5), // 在15%区域内向上偏移
                    child: Container(
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
                    ),
                  ),
                ),
                // 下半部分 - 留白区域
                const Expanded(
                  flex: 40,
                  child: SizedBox(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 自定义台灯光线绘制器
class DeskLampPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // 光源位置（在左上角外侧）
    final lightSourceX = -size.width * 0.35; // 在左上角外侧
    final lightSourceY = -size.height * 0.25; // 在左上角外侧
    
    // 20度扇形参数，保持上边缘不动，下边缘上移
    final fanAngle = math.pi / 7; // 20度扇形角度（缩小张角）
    final fanRadius = math.sqrt(size.width * size.width + size.height * size.height) * 1.4; // 保持半径不变
    final startAngle = 45 * math.pi / 180; // 上边缘（45度）
    // 下边缘从85度上移到75度，张角变为20度
    
    // 创建扇形路径
    final fanPath = Path();
    fanPath.moveTo(lightSourceX, lightSourceY); // 从光源开始
    fanPath.arcTo(
      Rect.fromCircle(
        center: Offset(lightSourceX, lightSourceY),
        radius: fanRadius,
      ),
      startAngle,
      fanAngle,
      false,
    );
    fanPath.close();
    
    // 创建扇形渐变效果（从光源中心辐射）
    final gradient = ui.Gradient.radial(
      Offset(lightSourceX, lightSourceY), 
      fanRadius,
      [
        Colors.white.withValues(alpha: 0.18), // 左上角光源处
        Colors.white.withValues(alpha: 0.15), // 标题区域
        Colors.white.withValues(alpha: 0.12), // 中间区域
        Colors.white.withValues(alpha: 0.08), // 副标题区域
        Colors.white.withValues(alpha: 0.04),
        Colors.transparent, // 右下角边缘透明
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