// debug_network_permission.dart
// 用于调试本地网络权限弹窗的触发源

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置系统样式
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );
  
  debugPrint('========================================');
  debugPrint('🔍 本地网络权限调试 - 启动测试');
  debugPrint('========================================');
  debugPrint('');
  debugPrint('📝 观察：');
  debugPrint('1. 如果现在弹出权限 → 是 WidgetsFlutterBinding 或系统样式触发的');
  debugPrint('2. 如果在 runApp 后弹出 → 是 MaterialApp 或某个 widget 触发的');
  debugPrint('3. 如果在页面显示后弹出 → 是页面代码触发的');
  debugPrint('');
  
  runApp(const DebugApp());
  
  debugPrint('✅ runApp() 已调用');
  debugPrint('');
}

class DebugApp extends StatelessWidget {
  const DebugApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 DebugApp.build() 执行');
    
    return MaterialApp(
      title: '网络权限调试',
      debugShowCheckedModeBanner: false,
      home: const DebugHomePage(),
    );
  }
}

class DebugHomePage extends StatefulWidget {
  const DebugHomePage({super.key});

  @override
  State<DebugHomePage> createState() => _DebugHomePageState();
}

class _DebugHomePageState extends State<DebugHomePage> {
  final List<String> _logs = [];
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _addLog('🚀 DebugHomePage.initState() 执行');
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addLog('🎨 首帧渲染完成');
    });
  }

  void _addLog(String log) {
    debugPrint(log);
    if (mounted) {
      setState(() {
        _logs.add('${DateTime.now().toString().substring(11, 23)} - $log');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6B5BFF),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '本地网络权限调试',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                '步骤 $_step',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListView.builder(
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          _logs[index],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '⚠️ 观察：权限弹窗在哪一步出现？',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                label: '步骤1: 测试基础渲染',
                onPressed: _step >= 1 ? null : () {
                  _addLog('✅ 步骤1完成：基础渲染正常');
                  setState(() {
                    _step = 1;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: '步骤2: 测试 Timer',
                onPressed: _step >= 2 ? null : () {
                  _addLog('⏰ 开始测试 Timer...');
                  Future.delayed(const Duration(seconds: 1), () {
                    _addLog('✅ Timer 正常');
                    setState(() {
                      _step = 2;
                    });
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                label: '步骤3: 测试动画',
                onPressed: _step >= 3 ? null : () {
                  _addLog('🎬 开始测试动画...');
                  _testAnimation();
                },
              ),
              const SizedBox(height: 24),
              const Text(
                '说明：\n'
                '如果在某个步骤后弹出权限，\n'
                '说明该步骤触发了本地网络权限。\n'
                '请截图并报告。',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _testAnimation() {
    _addLog('✅ 动画测试跳过（不影响权限检测）');
    setState(() {
      _step = 3;
    });
  }

  Widget _buildActionButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}


