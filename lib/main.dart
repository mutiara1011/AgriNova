import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/calibration_provider.dart';
import 'bottom_nav.dart';
import 'fuzzy/fuzzy_controller.dart';
import 'notification/notification_controller.dart';
import 'settings/theme_controller.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationController()),
        ChangeNotifierProvider(create: (_) => ThemeController()),
        ChangeNotifierProvider(create: (_) => SensorProvider()),
        ChangeNotifierProvider(create: (_) => CalibrationProvider()..fetchCalibrationData()),

        ChangeNotifierProxyProvider2<NotificationController, SensorProvider, FuzzyController>(
          create: (context) =>
              FuzzyController(context.read<NotificationController>(), context.read<SensorProvider>()),
          update: (context, notif, sensor, previous) {
            previous!.notificationController = notif;
            previous.sensorProvider = sensor;
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
