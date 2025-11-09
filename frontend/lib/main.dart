import 'package:flutter/material.dart';
import 'package:up_guardian/my_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GitHub-like dark palette
    const githubBackground = Color(0xFF0D1117);
    const githubSurface = Color(0xFF161B22);
    const githubBorder = Color(0xFF30363D);
    const githubText = Color(0xFFC9D1D9);
    const githubBlue = Color(0xFF1F6FEB);

    final base = ThemeData.dark();
    return MaterialApp(
      title: 'UpGuardian',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        scaffoldBackgroundColor: githubBackground,
        primaryColor: githubSurface,
        appBarTheme: base.appBarTheme.copyWith(
          backgroundColor: githubSurface,
          elevation: 0,
          foregroundColor: githubText,
        ),
        colorScheme: base.colorScheme.copyWith(
          primary: githubBlue,
          onPrimary: Colors.white,
          surface: githubSurface,
          onSurface: githubText,
          secondary: githubBlue,
        ),
        dividerColor: githubBorder,
        textTheme: base.textTheme.apply(
          bodyColor: githubText,
          displayColor: githubText,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: githubBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}
