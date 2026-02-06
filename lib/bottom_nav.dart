import 'package:flutter/material.dart';

import 'dashboard_page.dart';
import 'control_page.dart';
import 'fuzzy_page.dart';
import 'settings_page.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int index = 0;

  final pages = const [
    DashboardPage(),
    ControlPage(),
    FuzzyPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xff03AF55),
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tune, size: 30),
            label: 'Kontrol',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology, size: 30),
            label: 'Fuzzy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 30),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}
