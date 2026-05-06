import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/sensor_provider.dart';
import 'providers/calibration_provider.dart';
import 'providers/plant_provider.dart';
import 'bottom_nav.dart';
import 'fuzzy/fuzzy_controller.dart';
import 'notification/notification_controller.dart';
import 'settings/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final plantProvider = PlantProvider();
  await plantProvider.loadData();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: plantProvider),
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
          return const BottomNav();
        },
      ),

      themeMode: context.watch<ThemeController>().themeMode,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xffF8FAF9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff03AF55),
          primary: const Color(0xff03AF55),
        ),
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: Colors.white,
        ),
      ),

      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xff0F1115),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xff03AF55),
          surface: const Color(0xff1A1D23),
        ),
        fontFamily: 'Inter',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          color: const Color(0xff1A1D23),
        ),
      ),
    );
  }
}
