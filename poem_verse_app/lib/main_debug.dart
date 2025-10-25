import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  debugPrint('🔴 [0] main() 开始');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('🔴 [1] ensureInitialized 完成');
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  debugPrint('🔴 [2] setSystemUIOverlayStyle 完成');
  
  runApp(const TestApp());
  debugPrint('🔴 [3] runApp 完成');
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('🔴 [4] TestApp.build 开始');
    return MaterialApp(
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF5A7AFF), Color(0xFF6B5BFF), Color(0xFF8A5AFF), Color(0xFF6B4BA5)],
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '测试APP - 观察权限弹窗',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Text(
                    '如果这个简单APP不弹窗\n说明是主APP的某个包触发的',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
