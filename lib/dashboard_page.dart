import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:agrinova/detail_chart_page.dart';
import 'notification/notification_page.dart';
import 'dart:async';
import 'package:agrinova/fuzzy/fuzzy_controller.dart';
import 'package:intl/intl.dart';
import 'package:agrinova/providers/sensor_provider.dart';
import 'package:agrinova/providers/calibration_provider.dart';
import 'package:agrinova/models/sensor_data.dart';
import 'package:agrinova/providers/plant_provider.dart';
import 'package:agrinova/notification/notification_controller.dart';
import 'package:agrinova/notification/notification_model.dart';
import 'package:agrinova/onboarding/plant_selection_page.dart';
import 'package:agrinova/models/plant_cycle.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onTabChange;

  const DashboardPage({super.key, required this.onTabChange});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PageController controller = PageController();
  late Timer slideTimer;
  int currentIndex = 0;
  final int chartsLength = 7; // 6 + ketinggian air = 7
  static bool _hasShownSystemAlert = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plant = context.read<PlantProvider>().activePlant;
      context.read<SensorProvider>().fetchHistoryData(
        startDate: plant?.startDate,
      );
    });

    slideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (controller.hasClients) {
        currentIndex++;
        if (currentIndex >= chartsLength) {
          currentIndex = 0;
        }
        controller.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    slideTimer.cancel();
    controller.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    final provider = context.read<SensorProvider>();
    final plant = context.read<PlantProvider>().activePlant;
    await provider.fetchLatestData();
    await provider.fetchHistoryData(startDate: plant?.startDate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _appBar(context),
      body: Consumer<SensorProvider>(
        builder: (context, sensor, child) {
          final hasNoData =
              sensor.latestData == null && sensor.historyData.isEmpty;

          // 🔥 SYSTEM ALERT POP-UP (Triggered once if errors exist)
          if (!_hasShownSystemAlert && sensor.latestData != null) {
            final errors = _getErrorMessages(sensor.latestData);
            if (errors.isNotEmpty) {
              _hasShownSystemAlert = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _showSystemErrorDialog(context, errors);
              });
            }
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xff03AF55),
            child: hasNoData && sensor.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xff03AF55)),
                  )
                : hasNoData
                ? _emptyStateView(context)
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                      16,
                      MediaQuery.of(context).padding.top + 20,
                      16,
                      100,
                    ),
                    child: Column(
                      children: [
                        _plantStatusOverview(context, sensor.latestData),
                        if (context.watch<PlantProvider>().activePlant !=
                            null) ...[
                          const SizedBox(height: 16),
                          _plantDetailsSection(context),
                        ],
                        const SizedBox(height: 24),
                        _sectionTitle("Monitoring Realtime"),
                        const SizedBox(height: 8),
                        _sensorGrid(context, sensor.latestData),
                        const SizedBox(height: 24),
                        _sectionTitle("Analisis Tren"),
                        const SizedBox(height: 8),
                        _chartSlider(context, sensor),
                        const SizedBox(height: 24),
                        _fuzzyStatusCard(context),
                        const SizedBox(height: 12),
                        _lastUpdatedText(context, sensor),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _emptyStateView(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height - 100,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xff03AF55).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Color(0xff03AF55),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Gagal Memuat Data",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              "Pastikan perangkat Anda terhubung ke internet dan alat AgriNova sedang aktif.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 160,
              child: ElevatedButton.icon(
                onPressed: _onRefresh,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text(
                  "COBA LAGI",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff03AF55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _lastUpdatedText(BuildContext context, SensorProvider sensor) {
    final date = sensor.lastFetchedAt ?? DateTime.now();
    final timeStr = DateFormat('HH:mm:ss').format(date);
    final isLive = sensor.isLiveMode;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLive) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xff03AF55),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff03AF55).withValues(alpha: 0.5),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
        Opacity(
          opacity: 0.6,
          child: Text(
            isLive
                ? "LIVE · Diperbarui $timeStr"
                : "Data diperbarui pada $timeStr",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // ================= ERROR ALERT BANNER (like Web client) =================
  List<String> _getErrorMessages(SensorData? data) {
    final msgs = <String>[];
    if (data == null) return msgs;
    if (data.airTemp == -1 && data.airHumidity == -1)
      msgs.add("Sensor Suhu/Kelembaban Udara (DHT22) Mati/Terlepas!");
    if (data.waterTemp == -1)
      msgs.add("Sensor Suhu Air (DS18B20) Mati/Terlepas!");
    if (data.tdsPPM == 0 && data.waterTemp > 0)
      msgs.add("Sensor Nutrisi (TDS) Mati/Terlepas!");
    if (data.waterTemp > 35)
      msgs.add(
        "Suhu Air Terlalu Panas! (${data.waterTemp.toStringAsFixed(1)}°C)",
      );
    if (data.tdsPPM > 1000)
      msgs.add(
        "Nutrisi TDS Terlalu Tinggi! (${data.tdsPPM.toStringAsFixed(0)} ppm)",
      );
    if (data.phValue < 3.0 || data.phValue > 10.0)
      msgs.add("pH Air Kritis! (${data.phValue.toStringAsFixed(1)})");
    if (data.systemState == 7 && msgs.isEmpty)
      msgs.add("Terjadi Kesalahan Sistem pada Alat!");
    return msgs;
  }

  void _showSystemErrorDialog(BuildContext context, List<String> errors) {
    final calibration = context.read<CalibrationProvider>();
    final isMuted = calibration.calibrationData?.muteBuzzer ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xff1A1D23) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Gradient
              Container(
                height: 140,
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffFF5F6D), Color(0xffFFC371)],
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle background pattern
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Icon(
                        Icons.warning_amber_rounded,
                        size: 150,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.priority_high_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Column(
                  children: [
                    Text(
                      "Peringatan Sistem!",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xff1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Ditemukan beberapa anomali pada alat AgriNova Anda:",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Error List in Stylized Cards
              Flexible(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    child: Column(
                      children: errors
                          .map(
                            (msg) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xffEF4444,
                                ).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(
                                    0xffEF4444,
                                  ).withValues(alpha: 0.1),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 16,
                                    color: Color(0xffEF4444),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      msg,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xffB91C1C),
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ),

              // Action Buttons
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          await calibration.toggleMuteBuzzer(!isMuted);
                          if (context.mounted) Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isMuted
                              ? Colors.grey.shade200
                              : const Color(0xff1F2937),
                          foregroundColor: isMuted
                              ? Colors.grey.shade700
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isMuted ? Icons.volume_up : Icons.volume_off,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isMuted ? "AKTIFKAN BUZZER" : "MATIKAN BUZZER",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "SAYA MENGERTI",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xff03AF55).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Image.asset('assets/images/logo.png', height: 28),
          ),
          const SizedBox(width: 12),
          const Text(
            'AGRINOVA',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationPage()),
          ),
          icon: const Icon(
            Icons.notifications_active_outlined,
            color: Color(0xff03AF55),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _plantStatusOverview(BuildContext context, SensorData? data) {
    final plant = context.watch<PlantProvider>().activePlant;
    final fuzzy = context.watch<FuzzyController>();

    if (plant == null) {
      return _PremiumCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PlantSelectionPage()),
          ),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff03AF55), Color(0xff028A43)],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "SIAP MENANAM?",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Mulai Siklus\nBaru Sekarang",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "PILIH TANAMAN",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 80,
                  color: Colors.white24,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final hst = plant.hst.toString();
    final name = plant.name;

    String getPhase() {
      return context.read<PlantProvider>().selectedPhase.toUpperCase();
    }

    return _PremiumCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xff03AF55).withValues(alpha: 0.1),
          image: DecorationImage(
            image: AssetImage(
              name.toLowerCase().contains("kangkung")
                  ? 'assets/images/kangkung.png'
                  : name.toLowerCase().contains("pakcoy")
                      ? 'assets/images/pakcoy.png'
                      : name.toLowerCase().contains("selada")
                          ? 'assets/images/selada.png'
                          : 'assets/images/selada_romaine.jpg',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: 0.2),
              BlendMode.darken,
            ),
          ),

        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              colors: [
                Colors.black.withValues(alpha: 0.8),
                Colors.black.withValues(alpha: 0.2),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xff03AF55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        getPhase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          fuzzy.isFuzzyEnabled ? Icons.psychology_outlined : Icons.do_not_disturb_on_outlined,
                          color: Colors.white60,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          fuzzy.isFuzzyEnabled ? "FUZZY MAMDANI ACTIVE" : "SISTEM OTOMATIS NONAKTIF",
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    hst,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const Text(
                    "HSPT",
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _plantDetailsSection(BuildContext context) {
    PlantCycle? plant = context.watch<PlantProvider>().activePlant;
    if (plant == null) return const SizedBox();

    final dateFormat = DateFormat('dd MMM yyyy');
    final startStr = dateFormat.format(plant.startDate);

    // Estimate harvest based on plant type
    int estDays = 30;
    if (plant.name.toLowerCase().contains("kangkung")) estDays = 21;
    if (plant.name.toLowerCase().contains("pakcoy")) estDays = 35;
    if (plant.name.toLowerCase().contains("selada")) estDays = 45;

    final harvestDate = plant.startDate.add(Duration(days: estDays));
    final harvestStr = dateFormat.format(harvestDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle("Informasi Siklus Tanam"),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoBox(Icons.calendar_month, "Mulai Tanam", startStr),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoBox(
                Icons.event_available,
                "Perkiraan Panen",
                harvestStr,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoBox(
                Icons.science_outlined,
                "Target pH",
                "${plant.targetPhMin} - ${plant.targetPhMax}",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _infoBox(
                Icons.water_drop_outlined,
                "TDS (Veg)",
                "${plant.targetTdsVegetatifMin.toInt()} - ${plant.targetTdsVegetatifMax.toInt()} PPM",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _infoBox(
                Icons.water_drop_outlined,
                "TDS (Pem)",
                "${plant.targetTdsPembesaranMin.toInt()} - ${plant.targetTdsPembesaranMax.toInt()} PPM",
              ),
            ),
            const SizedBox(width: 12),
            const Spacer(),
          ],
        ),
        if (harvestDate.difference(DateTime.now()).inDays <= 5) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff03AF55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              onPressed: () => _showHarvestDialog(
                context,
                harvestDate.difference(DateTime.now()).inDays,
                plant,
              ),
              icon: const Icon(Icons.grass, color: Colors.white),
              label: const Text(
                "SELESAI PANEN SEKARANG",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showHarvestDialog(
    BuildContext context,
    int daysLeft,
    PlantCycle plant,
  ) {
    bool isEarly = daysLeft > 5;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isEarly ? "Panen Lebih Awal?" : "Selesai Panen?",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isEarly
              ? "Siklus tanam belum mencapai perkiraan panen ($daysLeft hari lagi). Apakah kamu ingin mengakhiri siklus ini lebih awal (misal: karena gagal panen, busuk, dll)?"
              : "Siklus tanam saat ini akan diakhiri. Riwayat grafik dan sensor akan disimpan ke history, dan notifikasi akan direset.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<PlantProvider>();
              final notifController = context.read<NotificationController>();
              final fuzzyController = context.read<FuzzyController>();

              // 1. Akhiri siklus di Backend
              await provider.endCycle(
                notes: isEarly
                    ? "Panen lebih awal / Gagal panen"
                    : "Panen sukses",
              );

              // 2. Reset Notifikasi & Rekomendasi
              notifController.clearNotifications();
              fuzzyController.clearFuzzyLog();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Siklus tanam berhasil diakhiri.",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: Color(0xff03AF55),
                  ),
                );
              }
            },
            child: Text(
              isEarly ? "Ya, Akhiri Siklus" : "Ya, Panen",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String title, String value) {
    return _PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xff03AF55)),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _sensorGrid(BuildContext context, SensorData? data) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 380;

    String weatherValue = '--';
    IconData weatherIcon = Icons.nights_stay;
    Color weatherColor = Colors.indigo;

    if (data != null) {
      final hour = DateTime.now().hour;
      final isDaylight = hour >= 6 && hour < 18;

      if (isDaylight) {
        final lux = data.lightLux;
        if (lux >= 40000) {
          weatherValue = 'Sangat Terik';
          weatherIcon = Icons.wb_sunny;
          weatherColor = Colors.orange;
        } else if (lux >= 15000) {
          weatherValue = 'Cerah';
          weatherIcon = Icons.sunny;
          weatherColor = Colors.amber;
        } else if (lux >= 2000) {
          weatherValue = 'Berawan';
          weatherIcon = Icons.cloud;
          weatherColor = Colors.blueGrey;
        } else {
          weatherValue = 'Mendung';
          weatherIcon = Icons.thunderstorm_rounded;
          weatherColor = Colors.grey;
        }
      } else {
        weatherValue = 'Malam';
        weatherIcon = Icons.nights_stay;
        weatherColor = Colors.indigoAccent;
      }
    }

    return GridView.count(
      crossAxisCount: isSmall ? 1 : 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isSmall ? 1.8 : 1.4,
      children: [
        _PremiumSensorTile(
          title: 'Level Air',
          value: '12.0',
          unit: 'cm',
          icon: Icons.water_drop,
          color: Colors.blue,
        ),
        _PremiumSensorTile(
          title: 'Suhu Udara',
          value: data?.airTemp.toStringAsFixed(1) ?? '--',
          unit: '°C',
          icon: Icons.air,
          color: Colors.orange,
        ),
        _PremiumSensorTile(
          title: 'Kelembapan',
          value: data?.airHumidity.toStringAsFixed(0) ?? '--',
          unit: '%',
          icon: Icons.cloud_outlined,
          color: Colors.lightBlue,
        ),
        _PremiumSensorTile(
          title: 'Suhu Air',
          value: data?.waterTemp.toStringAsFixed(1) ?? '--',
          unit: '°C',
          icon: Icons.thermostat,
          color: Colors.cyan,
        ),
        _PremiumSensorTile(
          title: 'Cahaya',
          value: data?.lightLux.toStringAsFixed(0) ?? '--',
          unit: 'Lx',
          icon: Icons.wb_sunny_outlined,
          color: Colors.amber,
        ),
        _PremiumSensorTile(
          title: 'Nutrisi/TDS',
          value: data?.tdsPPM.toStringAsFixed(0) ?? '--',
          unit: 'PPM',
          icon: Icons.science_outlined,
          color: Colors.deepPurple,
        ),
        _PremiumSensorTile(
          title: 'pH Air',
          value: data?.phValue.toStringAsFixed(1) ?? '--',
          unit: '',
          icon: Icons.opacity,
          color: Colors.teal,
        ),
        _PremiumSensorTile(
          title: 'Cuaca',
          value: weatherValue,
          unit: '',
          icon: weatherIcon,
          color: weatherColor,
        ),
      ],
    );
  }


  Widget _chartSlider(BuildContext context, SensorProvider sensor) {
    final data = sensor.latestData;
    final history = sensor.historyData;

    final charts = [
      _chartItem(
        "Level Air",
        "12.0 cm",
        const Color(0xff0ea5e9),
        history,
        (d) => 12.0,
      ),
      _chartItem(
        "Suhu Udara",
        "${data?.airTemp.toStringAsFixed(1) ?? '--'}°C",
        const Color(0xfff97316),
        history,
        (d) => d.airTemp,
      ),
      _chartItem(
        "Kelembapan",
        "${data?.airHumidity.toStringAsFixed(1) ?? '--'}%",
        const Color(0xff3b82f6),
        history,
        (d) => d.airHumidity,
      ),
      _chartItem(
        "Suhu Air",
        "${data?.waterTemp.toStringAsFixed(1) ?? '--'}°C",
        const Color(0xff06b6d4),
        history,
        (d) => d.waterTemp,
      ),
      _chartItem(
        "Cahaya",
        "${data?.lightLux.toStringAsFixed(0) ?? '--'} Lux",
        const Color(0xffeab308),
        history,
        (d) => d.lightLux,
      ),
      _chartItem(
        "Nutrisi",
        "${data?.tdsPPM.toStringAsFixed(0) ?? '--'} PPM",
        const Color(0xff8b5cf6),
        history,
        (d) => d.tdsPPM,
      ),
      _chartItem(
        "pH Air",
        data?.phValue.toStringAsFixed(1) ?? '--',
        const Color(0xff14b8a6),
        history,
        (d) => d.phValue,
      ),
    ];

    final screenHeight = MediaQuery.of(context).size.height;

    return _PremiumCard(
      child: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.25, // Dinamis berdasarkan tinggi layar
            child: PageView.builder(
              controller: controller,
              itemCount: charts.length,
              onPageChanged: (index) => setState(() => currentIndex = index),
              itemBuilder: (context, index) => charts[index],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(charts.length, (index) {
                  final isActive = currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xff03AF55)
                          : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DetailChartPage()),
                ),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text(
                  "Detail",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xff03AF55),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartItem(
    String title,
    String value,
    Color color,
    List<SensorData> history,
    double Function(SensorData) selector,
  ) {
    final spots = List.generate(
      history.length,
      (i) => FlSpot(i.toDouble(), selector(history[i])),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.05),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      String unit = "";
                      if (title.contains("Suhu")) unit = "°";
                      if (title.contains("Kelembapan")) unit = "%";
                      if (title.contains("Cahaya")) unit = "Lx";
                      if (title.contains("Nutrisi")) unit = "";

                      return Text(
                        "${value.toStringAsFixed(0)}$unit",
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 10,
                    getTitlesWidget: (v, m) => const SizedBox(),
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    interval: 1, // Let getTitlesWidget decide based on value
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      // Only show labels for every ~20% of data to avoid crowding
                      int interval = (history.length / 4).ceil();
                      if (interval < 1) interval = 1;
                      
                      if (idx < 0 || idx >= history.length || idx % interval != 0) {
                        return const SizedBox();
                      }

                      // Avoid showing the very last label if it's too close to the end
                      if (idx > history.length - (interval / 2) && idx != history.length - 1) {
                         return const SizedBox();
                      }

                      final time = history[idx].createdAt ?? DateTime.now();
                      final timeStr = DateFormat('HH:mm').format(time);

                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        space: 8,
                        child: Text(
                          timeStr,
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: history.length > 1 ? (history.length - 1).toDouble() : 1,

              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 4,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fuzzyStatusCard(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();
    return InkWell(
      onTap: () => widget.onTabChange(2),
      borderRadius: BorderRadius.circular(28),

      child: _PremiumCard(
        color: const Color(0xff03AF55),
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  fuzzy.isFuzzyEnabled ? "LOGIKA FUZZY" : "FUZZY DINONAKTIFKAN",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              "Status Kesehatan Nutrisi",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fuzzy.isFuzzyEnabled ? fuzzy.statusNutrisi.toUpperCase() : "NON-AKTIF",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              children: [
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(seconds: 1),
                  height: 8,
                  width:
                      MediaQuery.of(context).size.width *
                      (fuzzy.outputPompa / 100).clamp(0.0, 1.0) *
                      0.7,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.white38, Colors.white],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _fuzzyInfo(Icons.opacity, "pH ${fuzzy.statusPh}"),
                _fuzzyInfo(
                  Icons.bolt,
                  "Output ${fuzzy.outputPompa.toStringAsFixed(1)}%",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fuzzyInfo(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 14),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PremiumSensorTile extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _PremiumSensorTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _PremiumCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              if (value != "--")
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xff03AF55),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
        boxShadow: color != null
            ? [
                BoxShadow(
                  color: color!.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
        border: Border.all(
          color: color != null
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
