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
  bool _isErrorDismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final plant = context.read<PlantProvider>().activePlant;
      context.read<SensorProvider>().fetchHistoryData(startDate: plant?.startDate);
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
    setState(() {
      _isErrorDismissed = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _appBar(),
      body: Consumer<SensorProvider>(
        builder: (context, sensor, child) {
          if (sensor.latestData == null && sensor.historyData.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Color(0xff03AF55)));
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xff03AF55),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 100),
              child: Column(
                children: [
                      _errorAlertBanner(context, sensor.latestData),
                      _plantStatusOverview(context, sensor.latestData),
                      const SizedBox(height: 24),
                      _sectionTitle("Monitoring Real-time"),
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

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
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
            width: 8, height: 8,
            decoration: BoxDecoration(
              color: const Color(0xff03AF55),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xff03AF55).withValues(alpha: 0.5), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 6),
        ],
        Opacity(
          opacity: 0.6,
          child: Text(
            isLive ? "LIVE · Diperbarui $timeStr" : "Data diperbarui pada $timeStr",
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
    if (data.airTemp == -1 && data.airHumidity == -1) msgs.add("Sensor Suhu/Kelembaban Udara (DHT22) Mati/Terlepas!");
    if (data.waterTemp == -1) msgs.add("Sensor Suhu Air (DS18B20) Mati/Terlepas!");
    if (data.tdsPPM == 0 && data.waterTemp > 0) msgs.add("Sensor Nutrisi (TDS) Mati/Terlepas!");
    if (data.waterTemp > 35) msgs.add("Suhu Air Terlalu Panas! (${data.waterTemp.toStringAsFixed(1)}°C)");
    if (data.tdsPPM > 1000) msgs.add("Nutrisi TDS Terlalu Tinggi! (${data.tdsPPM.toStringAsFixed(0)} ppm)");
    if (data.phValue < 3.0 || data.phValue > 10.0) msgs.add("pH Air Kritis! (${data.phValue.toStringAsFixed(1)})");
    if (data.systemState == 7 && msgs.isEmpty) msgs.add("Terjadi Kesalahan Sistem pada Alat!");
    return msgs;
  }

  Widget _errorAlertBanner(BuildContext context, SensorData? data) {
    if (_isErrorDismissed) return const SizedBox();
    final errors = _getErrorMessages(data);
    if (errors.isEmpty) return const SizedBox();

    final calibration = context.watch<CalibrationProvider>();
    final isMuted = calibration.calibrationData?.muteBuzzer ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xffFEF2F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffFCA5A5), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xffEF4444).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Color(0xffEF4444), size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Peringatan Sistem!",
                    style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isErrorDismissed = true;
                    });
                  },
                  icon: const Icon(Icons.close, color: Color(0xffDC2626), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...errors.map((msg) => Padding(
              padding: const EdgeInsets.only(bottom: 4, left: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• ", style: TextStyle(color: Color(0xffDC2626), fontWeight: FontWeight.bold)),
                  Expanded(child: Text(msg, style: const TextStyle(color: Color(0xff991B1B), fontSize: 13, fontWeight: FontWeight.w600))),
                ],
              ),
            )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      await calibration.toggleMuteBuzzer(!isMuted);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isMuted ? Colors.grey.shade200 : const Color(0xffEF4444),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isMuted ? Icons.volume_off : Icons.volume_up,
                            size: 16,
                            color: isMuted ? Colors.grey.shade600 : Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isMuted ? "Buzzer Dimatikan" : "Matikan Buzzer",
                            style: TextStyle(
                              color: isMuted ? Colors.grey.shade600 : Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isErrorDismissed = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffFCA5A5)),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "Tutup",
                        style: TextStyle(
                          color: Color(0xffDC2626),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
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
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.5),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
          icon: const Icon(Icons.notifications_active_outlined, color: Color(0xff03AF55)),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _plantStatusOverview(BuildContext context, SensorData? data) {
    final plant = context.watch<PlantProvider>().activePlant;
    final hst = plant?.hst.toString() ?? '0';
    final name = plant?.name ?? 'Belum ada tanaman';

    String getPhase() {
      final days = int.tryParse(hst) ?? 0;
      if (name.toLowerCase().contains("kangkung")) {
        if (days < 7) return "PERSEMAIAN";
        if (days < 18) return "VEGETATIF";
        return "SIAP PANEN";
      } else if (name.toLowerCase().contains("pakcoy") || name.toLowerCase().contains("selada")) {
        if (days < 10) return "PERSEMAIAN";
        if (days < 35) return "VEGETATIF";
        return "SIAP PANEN";
      }
      return days < 14 ? "VEGETATIF AWAL" : "VEGETATIF";
    }

    return _PremiumCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: const Color(0xff03AF55).withValues(alpha: 0.1),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.bottomRight,
              colors: [Colors.black.withValues(alpha: 0.8), Colors.black.withValues(alpha: 0.2)],
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xff03AF55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        getPhase(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name.toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.psychology_outlined, color: Colors.white60, size: 14),
                        const SizedBox(width: 6),
                        const Text(
                          "FUZZY MAMDANI ACTIVE",
                          style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w900),
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
                    style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900, height: 1),
                  ),
                  const Text(
                    "HST",
                    style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  }


  Widget _sensorGrid(BuildContext context, SensorData? data) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 380;
    
    return GridView.count(
      crossAxisCount: isSmall ? 1 : 2,
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isSmall ? 1.8 : 1.4,
      children: [
        _PremiumSensorTile(title: 'Level Air', value: '12.0', unit: 'cm', icon: Icons.water_drop, color: Colors.blue),
        _PremiumSensorTile(title: 'Suhu Udara', value: data?.airTemp.toStringAsFixed(1) ?? '--', unit: '°C', icon: Icons.air, color: Colors.orange),
        _PremiumSensorTile(title: 'Kelembapan', value: data?.airHumidity.toStringAsFixed(0) ?? '--', unit: '%', icon: Icons.cloud_outlined, color: Colors.lightBlue),
        _PremiumSensorTile(title: 'Suhu Air', value: data?.waterTemp.toStringAsFixed(1) ?? '--', unit: '°C', icon: Icons.thermostat, color: Colors.cyan),
        _PremiumSensorTile(title: 'Cahaya', value: data?.lightLux.toStringAsFixed(0) ?? '--', unit: 'Lx', icon: Icons.wb_sunny_outlined, color: Colors.amber),
        _PremiumSensorTile(title: 'Nutrisi/TDS', value: data?.tdsPPM.toStringAsFixed(0) ?? '--', unit: 'PPM', icon: Icons.science_outlined, color: Colors.deepPurple),
        _PremiumSensorTile(title: 'pH Air', value: data?.phValue.toStringAsFixed(1) ?? '--', unit: '', icon: Icons.opacity, color: Colors.teal),
        _PremiumSensorTile(title: 'Cuaca', value: 'Cerah', unit: '', icon: Icons.sunny, color: Colors.orangeAccent),
      ],
    );
  }

  Widget _chartSlider(BuildContext context, SensorProvider sensor) {
    final data = sensor.latestData;
    final history = sensor.historyData;
    
    final charts = [
      _chartItem("Level Air", "12.0 cm", const Color(0xff0ea5e9), history, (d) => 12.0),
      _chartItem("Suhu Udara", "${data?.airTemp.toStringAsFixed(1) ?? '--'}°C", const Color(0xfff97316), history, (d) => d.airTemp),
      _chartItem("Kelembapan", "${data?.airHumidity.toStringAsFixed(1) ?? '--'}%", const Color(0xff3b82f6), history, (d) => d.airHumidity),
      _chartItem("Suhu Air", "${data?.waterTemp.toStringAsFixed(1) ?? '--'}°C", const Color(0xff06b6d4), history, (d) => d.waterTemp),
      _chartItem("Cahaya", "${data?.lightLux.toStringAsFixed(0) ?? '--'} Lux", const Color(0xffeab308), history, (d) => d.lightLux),
      _chartItem("Nutrisi", "${data?.tdsPPM.toStringAsFixed(0) ?? '--'} PPM", const Color(0xff8b5cf6), history, (d) => d.tdsPPM),
      _chartItem("pH Air", "${data?.phValue.toStringAsFixed(1) ?? '--'}", const Color(0xff14b8a6), history, (d) => d.phValue),
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
                      color: isActive ? const Color(0xff03AF55) : Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
              TextButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DetailChartPage())),
                icon: const Icon(Icons.analytics_outlined, size: 18),
                label: const Text("Detail", style: TextStyle(fontWeight: FontWeight.w900)),
                style: TextButton.styleFrom(foregroundColor: const Color(0xff03AF55)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartItem(String title, String value, Color color, List<SensorData> history, double Function(SensorData) selector) {
    final spots = List.generate(history.length, (i) => FlSpot(i.toDouble(), selector(history[i])));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.05), strokeWidth: 1),
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
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 8, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 10, getTitlesWidget: (v, m) => const SizedBox()),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 22,
                    interval: history.length > 10 ? (history.length / 5).toDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= history.length) return const SizedBox();
                      
                      final time = history[idx].createdAt ?? DateTime.now();
                      final timeStr = DateFormat('HH.mm').format(time);
                      
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          timeStr,
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              minX: 0,
              maxX: spots.length > 1 ? (spots.length - 0.9).toDouble() : 1,
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
                      colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0)],
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
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.psychology, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("LOGIKA FUZZY", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const Spacer(),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 20),
          const Text("Status Kesehatan Nutrisi", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(
            fuzzy.statusNutrisi.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(height: 8, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 8,
                width: MediaQuery.of(context).size.width * (fuzzy.outputPompa / 100).clamp(0.0, 1.0) * 0.7,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.white38, Colors.white]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.white.withValues(alpha: 0.3), blurRadius: 4)],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _fuzzyInfo(Icons.opacity, "pH ${fuzzy.statusPh}"),
              _fuzzyInfo(Icons.bolt, "Output ${fuzzy.outputPompa.toStringAsFixed(1)}%"),
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
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
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

  const _PremiumSensorTile({required this.title, required this.value, required this.unit, required this.icon, required this.color});

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
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, size: 20, color: color),
              ),
              if (value != "--") 
                Container(
                  width: 8, height: 8, 
                  decoration: const BoxDecoration(color: Color(0xff03AF55), shape: BoxShape.circle),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  const SizedBox(width: 4),
                  Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w800)),
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
        boxShadow: color != null ? [
          BoxShadow(
            color: color!.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: color != null ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
