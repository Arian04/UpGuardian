import 'package:buttons_tabbar/buttons_tabbar.dart';
import 'package:flutter/material.dart';
import 'package:up_guardian/requests_page.dart';
import 'package:up_guardian/rules_page.dart';
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
      home: const TabBarExamplePage(),
    );
  }
}

class TabBarExamplePage extends StatefulWidget {
  const TabBarExamplePage({super.key});

  @override
  State<TabBarExamplePage> createState() => _TabBarExamplePageState();
}

class _TabBarExamplePageState extends State<TabBarExamplePage> {
  @override
  Widget build(BuildContext contect) {
    return DefaultTabController(
      initialIndex: 1,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("TabBar"),
          bottom: ButtonsTabBar(
          backgroundColor: Colors.black, 
          unselectedBackgroundColor:Colors.grey[400],
          unselectedLabelStyle: const TextStyle(color: Colors.white),
          labelStyle: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
          tabs:const [
            Tab(
              icon: Icon(Icons.directions_bike),
            text:"Requests",),
            Tab(
              icon: Icon(Icons.lock_clock_sharp),
            text:"Test",),
            Tab(
              icon: Icon(Icons.lock_clock_sharp),
            text:"Rules",)
          ],
          ),
          ),
          body:const TabBarView(
          children:[
            Center(
            child: RequestsPage(),
          ),
           Center(
            child:  TestsPage(),
           ),
          Center(
            child: RulesPage(),
          ),
          ],
          )
        ),
      );
  }
}
