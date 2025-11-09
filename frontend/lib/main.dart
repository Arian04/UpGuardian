import 'package:flutter/material.dart';
import 'package:up_guardian/my_home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UpGuardian',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed
        (seedColor: Colors.black) ,
        useMaterial3: true),
      home: const MyHomePage(),
    );
  }
}
