import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'control_page.dart';
import 'fuzzy/fuzzy_page.dart';
import 'settings/settings_page.dart';
import 'notification/notification_controller.dart';
import 'notification/notification_service.dart';
import 'package:provider/provider.dart';

class BottomNav extends StatefulWidget {
  const BottomNav({super.key});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  int index = 0;
  int lastNotifCount = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardPage(onTabChange: (i) => setState(() => index = i)),
      const ControlPage(),
      const FuzzyPage(),
      const SettingsPage(),
    ];

    final notifController = context.watch<NotificationController>();

    if (notifController.notifications.length != lastNotifCount) {
      lastNotifCount = notifController.notifications.length;

      final latest = notifController.notifications.first;

      // 🔥 CEK SETTING
      if (notifController.isEnabled) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showGlobalNotification(context, latest);
        });
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xff03AF55),
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
