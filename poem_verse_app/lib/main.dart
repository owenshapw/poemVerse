// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poem_verse_app/providers/auth_provider.dart';
import 'package:poem_verse_app/providers/article_provider.dart';
import 'package:poem_verse_app/screens/home_screen.dart';
import 'package:poem_verse_app/screens/reset_password_screen.dart';
import 'package:poem_verse_app/screens/login_screen.dart';

void main() {
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
        home: const HomeScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
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