import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:up_guardian/my_home_page.dart';
import 'package:up_guardian/requests_page.dart';
import 'package:up_guardian/rules_page.dart';
import 'package:up_guardian/tab_bar_example_page.dart';
import 'package:up_guardian/tests_page.dart';

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
