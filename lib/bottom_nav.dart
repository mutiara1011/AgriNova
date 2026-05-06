import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'control_page.dart';
import 'fuzzy/fuzzy_page.dart';
import 'settings/settings_page.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int index = 0;
  List<Widget>? _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      DashboardPage(onTabChange: (i) => setState(() => index = i)),
      const ControlPage(),
      const FuzzyPage(),
      const SettingsPage(),
    ];
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: index,
        children: _pages!,
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        height: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark 
              ? const Color(0xff1E1E22).withValues(alpha: 0.95) 
              : Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white.withValues(alpha: 0.05) 
                : Colors.grey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.grid_view_rounded, "Home"),
              _navItem(1, Icons.tune_rounded, "Kontrol"),
              _navItem(2, Icons.psychology_rounded, "Fuzzy"),
              _navItem(3, Icons.settings_rounded, "Setting"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int i, IconData icon, String label) {
    final isActive = index == i;
    final color = isActive ? const Color(0xff03AF55) : Colors.grey.shade500;
    
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => index = i),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xff03AF55).withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            if (isActive) 
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 4, height: 4,
                decoration: const BoxDecoration(color: Color(0xff03AF55), shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}
