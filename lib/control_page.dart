import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy/fuzzy_controller.dart';
import 'providers/sensor_provider.dart';
import 'providers/calibration_provider.dart';
import 'providers/plant_provider.dart';
import 'dart:async';
import '../notification/notification_controller.dart';
import '../notification/notification_widget.dart';
import 'package:agrinova/models/plant_cycle.dart';


class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  bool get pompa => context.read<FuzzyController>().pompaAktif;
  bool get aerator => context.read<FuzzyController>().aeratorAktif;
  bool get kipas => context.read<FuzzyController>().kipasAktif;
  bool lampu = true;

  bool autoPompa = true;
  bool autoKipas = true;
  bool autoAerator = true;

  double tdsValue = 800;
  int suhuTarget = 28;
  int durasiAerator = 2;

  late Timer timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CalibrationProvider>().fetchCalibrationData();
    });
    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      
      // Fetch calibration data to keep toggles in sync with Web client
      context.read<CalibrationProvider>().fetchCalibrationData(showLoading: false);
      
      final plant = context.read<PlantProvider>().activePlant;
      if (plant != null) {
        final phase = context.read<PlantProvider>().selectedPhase;
        setState(() {
          tdsValue = phase == "Vegetatif" ? plant.targetTdsVegetatifMax : plant.targetTdsPembesaranMax;
          suhuTarget = 28; // Default target
        });
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();
    final calibration = context.watch<CalibrationProvider>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'KONTROL SISTEM',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final calProvider = context.read<CalibrationProvider>();
          final senProvider = context.read<SensorProvider>();
          await calProvider.fetchCalibrationData();
          await senProvider.fetchLatestData();
        },
        color: const Color(0xff03AF55),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _warningCard(context),
              const SizedBox(height: 8),
              _sectionTitle("Status Rekomendasi"),
              const SizedBox(height: 12),
              _PremiumCard(
                color: const Color(0xff03AF55).withValues(alpha: 0.1),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.psychology, color: Color(0xff03AF55), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Analisis Fuzzy", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                          Text(
                            fuzzy.rekomendasi,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _sectionTitle("Konfigurasi Node"),
              const SizedBox(height: 12),
              _calibrationCard(calibration),
              const SizedBox(height: 24),
              _sectionTitle("Kendali Manual"),
              const SizedBox(height: 12),
              _switchCard(fuzzy),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1),
      ),
    );
  }

  Widget _calibrationCard(CalibrationProvider calibration) {
    return _PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _switchTile(
            'Live Monitoring (5s)',
            calibration.calibrationData?.liveModeActive ?? false,
            (v) async {
              await calibration.toggleLiveMode(v);
              if (mounted) {
                context.read<SensorProvider>().setLiveMode(v);
                context.read<SensorProvider>().fetchLatestData();
              }
            },
            calibration.isLoading,
            false,
            Icons.speed,
          ),
          const Divider(indent: 50, endIndent: 20),
          _switchTile(
            'Buzzer Alert',
            !(calibration.calibrationData?.muteBuzzer ?? false),
            (v) async {
              await calibration.toggleMuteBuzzer(!v);
            },
            calibration.isLoading,
            false,
            Icons.notifications_active_outlined,
          ),
        ],
      ),
    );
  }

  Widget _switchCard(FuzzyController fuzzy) {
    return _PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _switchTile(
            'Aerator Bak',
            aerator,
            (v) => context.read<FuzzyController>().setAeratorManual(v),
            false, // Selalu aktif (Manual)
            fuzzy.aeratorOverride != null,
            Icons.air,
          ),
          const Divider(indent: 50, endIndent: 20),
          _switchTile(
            'Kipas Ruangan',
            kipas,
            (v) => context.read<FuzzyController>().setKipasManual(v),
            false, // Selalu aktif (Manual)
            fuzzy.kipasOverride != null,
            Icons.wind_power,
          ),
          const Divider(indent: 50, endIndent: 20),
          _switchTile(
            'Lampu',
            lampu,
            (v) => setState(() => lampu = v),
            false, // Selalu aktif (Manual)
            false,
            Icons.lightbulb_outline,
          ),
        ],
      ),
    );
  }

  Widget _switchTile(String title, bool value, Function(bool) onChanged, bool disabled, bool isOverride, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: (value && !disabled) ? const Color(0xff03AF55).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: (value && !disabled) ? const Color(0xff03AF55) : Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: disabled ? Colors.grey : null),
                ),
                if (isOverride) const Text("Override Aktif", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xff03AF55),
            inactiveTrackColor: Colors.grey.shade300,
          ),
        ],
      ),
    );
  }




  Widget _warningCard(BuildContext context) {
    final notif = context.watch<NotificationController>();
    if (notif.notifications.isEmpty) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NotificationCard(notif: notif.notifications.first),
    );
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const _PremiumCard({required this.child, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
