// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/screens/home_screen.dart';
import 'package:poem_verse_app/screens/reset_password_screen.dart';
import 'package:poem_verse_app/screens/login_screen.dart';
import 'package:poem_verse_app/screens/author_works_screen.dart';
import 'package:poem_verse_app/screens/author_magazine_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // <- 必须有
  runApp(const PoemVerseApp());
}

class PoemVerseApp extends StatelessWidget {
  const PoemVerseApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ArticleProvider()),
      ],
      child: MaterialApp(
        title: 'PoemVerse',
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
        home: const HomeScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/authorWorks': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map?;
            return AuthorWorksScreen(
              author: args?['author'] ?? '',
              initialArticle: args?['initialArticle'],
            );
          },
          '/authorMagazine': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map?;
            return AuthorMagazineScreen(
              author: args?['author'] ?? '',
              initialArticle: args?['initialArticle'],
            );
          },
        },
        onGenerateRoute: (settings) {
          if (settings.name != null && settings.name!.startsWith('/reset-password')) {
            final uri = Uri.parse(settings.name!);
            final token = uri.queryParameters['token'];
            if (token != null) {
              return MaterialPageRoute(
                builder: (context) => ResetPasswordScreen(token: token),
              );
            }
          }
          return null;
        },
      ),
    );
  }
}