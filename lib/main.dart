import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dummy_data.dart';
import 'bottom_nav.dart';
import 'fuzzy/fuzzy_controller.dart';
import 'notification/notification_controller.dart';
import 'settings/theme_controller.dart';

void main() {
  DummyData.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),

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

      home: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return BottomNav();
        },
      ),

      themeMode: context.watch<ThemeController>().themeMode,

      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primarySwatch: Colors.green,
      ),

      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        cardColor: const Color(0xff24252A),
        shadowColor: const Color(0xff767A78),
      ),
    );
  }
}
