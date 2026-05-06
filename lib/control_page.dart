import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy/fuzzy_controller.dart';
import 'providers/sensor_provider.dart';
import 'providers/calibration_provider.dart';
import 'dart:async';
import '../notification/notification_controller.dart';
import '../notification/notification_widget.dart';

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
      
      final sensor = context.read<SensorProvider>().latestData;
      if (sensor != null) {
        setState(() {
          tdsValue = sensor.tdsPPM;
          suhuTarget = sensor.airTemp.toInt();
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
              const SizedBox(height: 24),
              _sectionTitle("Parameter Target"),
              const SizedBox(height: 12),
              _pompaCard(fuzzy),
              const SizedBox(height: 16),
              _kipasCard(fuzzy),
              const SizedBox(height: 16),
              _aeratorCard(fuzzy),
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
            'Pompa Nutrisi',
            pompa,
            (v) => context.read<FuzzyController>().setPompaManual(v),
            fuzzy.isAuto,
            fuzzy.pompaOverride != null,
            Icons.water_drop,
          ),
          const Divider(indent: 50, endIndent: 20),
          _switchTile(
            'Aerator Bak',
            aerator,
            (v) => context.read<FuzzyController>().setAeratorManual(v),
            fuzzy.isAuto,
            fuzzy.aeratorOverride != null,
            Icons.air,
          ),
          const Divider(indent: 50, endIndent: 20),
          _switchTile(
            'Kipas Ruangan',
            kipas,
            (v) => context.read<FuzzyController>().setKipasManual(v),
            fuzzy.isAuto,
            fuzzy.kipasOverride != null,
            Icons.wind_power,
          ),
          const Divider(indent: 50, endIndent: 20),
          _switchTile(
            'Lampu Growlight',
            lampu,
            (v) => setState(() => lampu = v),
            fuzzy.isAuto,
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

  Widget _pompaCard(FuzzyController fuzzy) {
    return _PremiumCard(
      child: Column(
        children: [
          _autoHeader('Target TDS (Nutrisi)', autoPompa, (v) => setState(() => autoPompa = v), fuzzy.isAuto),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xff03AF55),
              inactiveTrackColor: const Color(0xff03AF55).withValues(alpha: 0.1),
              thumbColor: Colors.white,
              overlayColor: const Color(0xff03AF55).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: tdsValue.clamp(500, 1200),
              min: 500, max: 1200,
              onChanged: (autoPompa || fuzzy.isAuto) ? null : (v) => setState(() => tdsValue = v),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('500 PPM', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('${tdsValue.toInt()} PPM', style: const TextStyle(color: Color(0xff03AF55), fontWeight: FontWeight.w900)),
              ),
              Text('1200 PPM', style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kipasCard(FuzzyController fuzzy) {
    return _PremiumCard(
      child: Column(
        children: [
          _autoHeader('Target Suhu Ruangan', autoKipas, (v) => setState(() => autoKipas = v), fuzzy.isAuto),
          const SizedBox(height: 16),
          TextField(
            enabled: !autoKipas && !fuzzy.isAuto,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontWeight: FontWeight.w900),
            decoration: InputDecoration(
              labelText: "Suhu (°C)",
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              filled: true,
              fillColor: Colors.grey.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.thermostat, color: Color(0xff03AF55)),
            ),
            controller: TextEditingController(text: suhuTarget.toString()),
            onChanged: (v) => suhuTarget = int.tryParse(v) ?? suhuTarget,
          ),
        ],
      ),
    );
  }

  Widget _aeratorCard(FuzzyController fuzzy) {
    return _PremiumCard(
      child: Column(
        children: [
          _autoHeader('Durasi Aerasi Harian', autoAerator, (v) => setState(() => autoAerator = v), fuzzy.isAuto),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: durasiAerator,
                isExpanded: true,
                items: [1, 2, 3, 4].map((e) => DropdownMenuItem(value: e, child: Text('$e Jam / Hari', style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                onChanged: (!autoAerator && !fuzzy.isAuto) ? (v) => setState(() => durasiAerator = v ?? durasiAerator) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _autoHeader(String title, bool value, Function(bool) onChanged, bool fuzzyAuto) {
    final isActive = value || fuzzyAuto;
    return Row(
      children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
        GestureDetector(
          onTap: fuzzyAuto ? null : () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xff03AF55).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(isActive ? Icons.auto_awesome : Icons.touch_app_outlined, size: 14, color: isActive ? const Color(0xff03AF55) : Colors.grey),
                const SizedBox(width: 6),
                Text(isActive ? 'AUTO' : 'MANUAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isActive ? const Color(0xff03AF55) : Colors.grey)),
              ],
            ),
          ),
        ),
      ],
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
