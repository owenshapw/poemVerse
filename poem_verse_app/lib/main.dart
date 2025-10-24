// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/screens/splash_screen.dart';
import 'package:poem_verse_app/screens/home_screen.dart';
import 'package:poem_verse_app/screens/reset_password_screen.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
import 'package:poem_verse_app/screens/author_works_screen.dart';
import 'package:poem_verse_app/screens/author_magazine_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // <- 必须有
  runApp(const PoemVerseApp());
}

class PoemVerseApp extends StatefulWidget {
  const PoemVerseApp({super.key});

  @override
  PoemVerseAppState createState() => PoemVerseAppState();
}

class PoemVerseAppState extends State<PoemVerseApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri);
      },
      onError: (Object err) {
        debugPrint('Deep link error: $err');
      },
    );

    // Handle link when app is launched from a deep link
    try {
      final Uri? initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (err) {
      debugPrint('Failed to get initial URI: $err');
    }
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Received deep link: $uri');
    
    // Handle custom scheme (poemverse://)
    if (uri.scheme == 'poemverse') {
      if (uri.path == '/reset-password' && uri.queryParameters.containsKey('token')) {
        final String token = uri.queryParameters['token']!;
        _navigateToResetPassword(token);
      }
    }
    // Handle Universal Links / App Links (https://)
    else if (uri.scheme == 'https' && uri.host == 'poemverse.example.com') {
      if (uri.path.startsWith('/reset-password') && uri.queryParameters.containsKey('token')) {
        final String token = uri.queryParameters['token']!;
        _navigateToResetPassword(token);
      }
    }
  }

  void _navigateToResetPassword(String token) {
    // Navigate to reset password screen
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => ResetPasswordScreen(token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'PoemVerse',
        debugShowCheckedModeBanner: false, // 隐藏DEBUG标识
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // 配置本地化
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('zh', 'CN'), // 中文简体
          Locale('en', 'US'), // 英文
        ],
        locale: const Locale('zh', 'CN'), // 设置默认语言为中文
        home: Builder(
          builder: (context) {
            // 响应式布局判断
            return MediaQuery.of(context).size.width > 600
                ? const SplashScreen() // iPad布局 - 可以替换为平板专用的启动屏
                : const SplashScreen(); // 手机布局
          },
        ),
        routes: {
          '/home': (context) {
            // 响应式布局判断
            return MediaQuery.of(context).size.width > 600
                ? const HomeScreen() // iPad布局
                : const HomeScreen(); // 手机布局
          },
          '/login': (context) {
            // 响应式布局判断
            return MediaQuery.of(context).size.width > 600
                ? const LoginScreen() // iPad布局
                : const LoginScreen(); // 手机布局
          },
          '/authorWorks': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map?;
            // 响应式布局判断
            return MediaQuery.of(context).size.width > 600
                ? AuthorWorksScreen( // iPad布局
                    author: args?['author'] ?? '',
                    initialArticle: args?['initialArticle'],
                  )
                : AuthorWorksScreen( // 手机布局
                    author: args?['author'] ?? '',
                    initialArticle: args?['initialArticle'],
                  );
          },
          '/authorMagazine': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map?;
            // 响应式布局判断
            return MediaQuery.of(context).size.width > 600
                ? AuthorMagazineScreen( // iPad布局
                    author: args?['author'] ?? '',
                    initialArticle: args?['initialArticle'],
                  )
                : AuthorMagazineScreen( // 手机布局
                    author: args?['author'] ?? '',
                    initialArticle: args?['initialArticle'],
                  );
          },
        },
        onGenerateRoute: (settings) {
          // Handle regular route-based reset password links (fallback)
          if (settings.name != null && settings.name!.startsWith('/reset-password')) {
            final uri = Uri.parse(settings.name!);
            final token = uri.queryParameters['token'];
            if (token != null) {
              return MaterialPageRoute(
                builder: (context) {
                  // 响应式布局判断
                  return MediaQuery.of(context).size.width > 600
                      ? ResetPasswordScreen(token: token) // iPad布局
                      : ResetPasswordScreen(token: token); // 手机布局
                },
              );
            }
          }
          return null;
        },
      ),
    );
  }
}
