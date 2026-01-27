import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'bottom_nav.dart';
import 'fuzzy_controller.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => FuzzyController()..evaluateFuzzy(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AGRINOVA',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF6F7FB),
      ),
      home: const BottomNav(),
    );
  }
}
