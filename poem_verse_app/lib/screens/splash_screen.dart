// lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/screens/local_home_screen.dart';
import 'package:poem_verse_app/screens/my_articles_screen.dart';
import 'package:poem_verse_app/screens/local_poems_screen.dart';
import 'package:poem_verse_app/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    
    // ⚡ 立即设置状态栏（同步操作，不阻塞）
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    // 🎨 立即初始化动画（同步操作，不阻塞）
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    // ✅ 立即启动动画
    _controller.forward();

    // 🚀 使用 WidgetsBinding.instance.addPostFrameCallback 确保 UI 先渲染
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 延迟1秒后开始打字动画
      Timer(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _startTypingAnimation();
        }
      });

      // 🔧 后台异步初始化（不阻塞UI渲染）
      _initializeApp();
    });
  }

  Future<void> _initializeApp() async {
    final startTime = DateTime.now();
    debugPrint('⏱️ 开始后台初始化: ${startTime.toIso8601String()}');
    
    try {
      // 🚀 优化：并行初始化，保证足够时间展示打字动画
      // 副标题13个字 × 180ms/字 + 1秒延迟 = 3.34秒 + 0.5秒缓冲 = 4秒
      await Future.wait([
        _initServices().timeout(
          const Duration(seconds: 5), // 5秒超时保护
          onTimeout: () {
            debugPrint('⚠️ 初始化超时，但应用继续启动');
          },
        ),
        Future.delayed(const Duration(milliseconds: 4000)), // 4秒最小显示时间
      ]);
      
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      debugPrint('✅ 初始化完成，总耗时: ${duration.inMilliseconds}ms');
    } catch (e) {
      debugPrint('❌ 初始化错误: $e');
      // 即使出错也要保证最少显示时间
      final elapsed = DateTime.now().difference(startTime);
      final remaining = 4000 - elapsed.inMilliseconds;
      if (remaining > 0) {
        debugPrint('⏳ 等待剩余 ${remaining}ms 以完成动画');
        await Future.delayed(Duration(milliseconds: remaining));
      }
    }
    
    if (mounted) {
      setState(() {
        _isInitialized = true;
      });
      debugPrint('🚀 开始跳转到主页面');
      _navigateToMainScreen();
    }
  }

  Future<void> _initServices() async {
    final initStartTime = DateTime.now();
    debugPrint('🔧 后台初始化服务开始...');
    
    // 🚀 优化：并行初始化，更快完成
    await Future.wait([
      // 初始化本地存储
      Future(() async {
        try {
          final dbStartTime = DateTime.now();
          await LocalStorageService.init().timeout(
            const Duration(seconds: 2), // 缩短到2秒超时
            onTimeout: () {
              debugPrint('⚠️ 本地存储初始化超时');
            },
          );
          final dbDuration = DateTime.now().difference(dbStartTime);
          debugPrint('✅ 本地存储初始化完成 (${dbDuration.inMilliseconds}ms)');
        } catch (e) {
          debugPrint('❌ 本地存储初始化失败: $e');
        }
      }),
      // 初始化 AuthProvider
      Future(() async {
        if (!mounted) return;
        try {
          final authStartTime = DateTime.now();
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (!authProvider.isInitialized) {
            await authProvider.init().timeout(
              const Duration(seconds: 1), // 缩短到1秒超时
              onTimeout: () {
                debugPrint('⚠️ AuthProvider 初始化超时');
              },
            );
          }
          final authDuration = DateTime.now().difference(authStartTime);
          debugPrint('✅ AuthProvider 初始化完成 (${authDuration.inMilliseconds}ms)');
        } catch (e) {
          debugPrint('❌ AuthProvider 初始化失败: $e');
        }
      }),
    ]);
    
    final initDuration = DateTime.now().difference(initStartTime);
    debugPrint('✅ 后台初始化完成，总耗时: ${initDuration.inMilliseconds}ms');
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
          }
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _navigateToMainScreen() async {
    if (!mounted || !_isInitialized) return;
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      
      // 🔍 更可靠的首次启动判断：
      // 1. 检查 SharedPreferences 标记
      // 2. 检查本地数据库是否为空
      final hasLaunchedBefore = prefs.getBool('is_first_launch') == false;
      final poemsCount = LocalStorageService.getPoemsCount();
      final isFirstLaunch = !hasLaunchedBefore && poemsCount == 0;
      
      debugPrint('=== 启动判断 ===');
      debugPrint('hasLaunchedBefore: $hasLaunchedBefore');
      debugPrint('poemsCount: $poemsCount');
      debugPrint('isAuthenticated: ${authProvider.isAuthenticated}');
      debugPrint('isFirstLaunch: $isFirstLaunch');
      debugPrint('===============');
      
      if (!mounted) return;
      
      if (isFirstLaunch) {
        // ✅ 第一次启动：跳转到欢迎页面
        debugPrint('✨ 首次启动，跳转到欢迎页面');
        await prefs.setBool('is_first_launch', false);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const LocalHomeScreen(),
            ),
          );
        }
      } else {
        // 非第一次启动：根据登录状态跳转
        if (authProvider.isAuthenticated) {
          // 已登录：跳转到个人作品列表
          debugPrint('🔐 检测到已登录状态，跳转到个人作品页');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const MyArticlesScreen(),
              ),
            );
          }
        } else {
          // 未登录：跳转到本地作品列表
          debugPrint('📱 未登录，跳转到本地作品页');
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => const LocalPoemsScreen(),
              ),
            );
          }
        }
      }
    } catch (e) {
      // 如果出现错误，默认跳转到欢迎页面（最安全的选择）
      debugPrint('❌ 启动页面出错: $e');
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const LocalHomeScreen(),
          ),
        );
      }
    }
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
            color: Colors.black.withValues(alpha: 0.05), // 减少遮罩，让背景更亮
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
          // 台灯光线效果 - 从"诗章"向下照射（先绘制，被文字遮挡）
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
                // 上半部分 - Logo和标题区域
                Expanded(
                  flex: 45,
                  child: Align(
                    alignment: const Alignment(-0.1, 0.4), // 向左下移动，让logo位于光柱内
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
                                                                                                // APP Logo - 圆角边缘轮廓高光效果
                                Container(
                                  width: 120, // 与“诗章”文字容器宽度一致
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Center(
                                    child: Container(
                                      width: 101, // 更细的边框，0.5px边框宽度
                                      height: 101,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(18.5), // 对应的圆角
                                        gradient: SweepGradient( // 只在特定区域显示高光
                                          center: Alignment.center,
                                          startAngle: 0, // 从右边开始(0°)
                                          endAngle: 6.28, // 完整一圈
                                          colors: [
                                            Colors.transparent, // 0° 右边 - 无高光
                                            Colors.white.withValues(alpha: 0.4), // 45° 右下角高光开始
                                            Colors.white.withValues(alpha: 0.7), // 67.5° 右下角高光最亮
                                            Colors.white.withValues(alpha: 0.4), // 90° 下边中心 - 右下高光结束
                                            Colors.transparent, // 135° 左下角 - 无高光
                                            Colors.transparent, // 180° 左边 - 无高光
                                            Colors.white.withValues(alpha: 0.4), // 225° 左上角高光开始
                                            Colors.white.withValues(alpha: 0.7), // 247.5° 左上角高光最亮
                                            Colors.white.withValues(alpha: 0.4), // 270° 上边中心 - 左上高光结束
                                            Colors.transparent, // 315° 右上角 - 无高光
                                          ],
                                          stops: const [0.0, 0.125, 0.1875, 0.25, 0.375, 0.5, 0.625, 0.6875, 0.75, 0.875],
                                        ),
                                            ),
                                      child: Container(
                                        margin: const EdgeInsets.all(0.5), // 0.5px超细边框宽度
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
                                // 诗章标题 - 与logo完美对齐
                                SizedBox(
                                  width: 120, // 与logo宽度一致
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
                                      const SizedBox(width: 12), // 字间距
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
    const lightSourceX = -0.35; // 在左上角外侧比例
    const lightSourceY = -0.25; // 在左上角外侧比例
    final actualLightSourceX = size.width * lightSourceX;
    final actualLightSourceY = size.height * lightSourceY;
    
    // 20度扇形参数，保持上边缘不动，下边缘上移
    const fanAngle = math.pi / 7; // 20度扇形角度（缩小张角）
    final fanRadius = math.sqrt(size.width * size.width + size.height * size.height) * 1.4; // 保持半径不变
    const startAngle = 45 * math.pi / 180; // 上边缘（45度）
    // 下边缘从85度上移到75度，张角变为20度
    
    // 创建扇形路径
    final fanPath = Path();
    fanPath.moveTo(actualLightSourceX, actualLightSourceY); // 从光源开始
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
    
    // 创建扇形渐变效果（从光源中心辐射）
    final gradient = ui.Gradient.radial(
      Offset(actualLightSourceX, actualLightSourceY), 
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