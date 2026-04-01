import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dummy_data.dart';
import 'bottom_nav.dart';
import 'fuzzy/fuzzy_controller.dart';
import 'notification/notification_controller.dart';

void main() {
  DummyData.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationController()),

        ChangeNotifierProxyProvider<NotificationController, FuzzyController>(
          create: (context) =>
              FuzzyController(context.read<NotificationController>()),
          update: (context, notif, previous) {
            previous!.notificationController = notif;
            return previous;
          },
        ),
      ],
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
