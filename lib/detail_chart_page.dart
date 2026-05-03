import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agrinova/dashboard_page.dart';
import 'package:agrinova/providers/sensor_provider.dart';
import 'package:agrinova/models/sensor_data.dart';
import 'package:intl/intl.dart';

class SensorType {
  final String id;
  final String label;
  final String category;
  final IconData icon;
  final String unit;
  final Color color;

  SensorType({
    required this.id, 
    required this.label, 
    required this.category,
    required this.icon, 
    required this.unit, 
    required this.color
  });
}

// Urutan sama persis dengan sensor grid dan chart slider di dashboard
final List<SensorType> sensorTypes = [
  SensorType(id: "waterLevel", label: "Ketinggian Air", category: "LEVEL", icon: Icons.water, unit: "cm", color: const Color(0xff0ea5e9)),
  SensorType(id: "airTemp", label: "Suhu Udara", category: "ATMOSFER", icon: Icons.device_thermostat, unit: "°C", color: const Color(0xfff97316)),
  SensorType(id: "airHumidity", label: "Kelembapan Udara", category: "UDARA", icon: Icons.water_drop, unit: "%", color: const Color(0xff3b82f6)),
  SensorType(id: "waterTemp", label: "Suhu Air", category: "RESERVOIR", icon: Icons.thermostat, unit: "°C", color: const Color(0xff06b6d4)),
  SensorType(id: "lightLux", label: "Intensitas Cahaya", category: "FOTOSINTESIS", icon: Icons.light_mode, unit: "Lux", color: const Color(0xffeab308)),
  SensorType(id: "tdsPPM", label: "TDS (Nutrisi Air)", category: "NUTRISI", icon: Icons.speed, unit: "PPM", color: const Color(0xff8b5cf6)),
  SensorType(id: "phValue", label: "pH (Keasaman Air)", category: "KEASAMAN", icon: Icons.science, unit: "", color: const Color(0xff14b8a6)),
];

class DetailChartPage extends StatefulWidget {
  const DetailChartPage({super.key});

  @override
  State<DetailChartPage> createState() => _DetailChartPageState();
}

class _DetailChartPageState extends State<DetailChartPage> {
  late SensorType activeSensor;
  String activeRange = "1d";
  DateTime focusDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    activeSensor = sensorTypes[0];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAnalysis();
    });
  }

  void _refreshAnalysis() {
    // Sama seperti web client: endDate berupa ISO string agar rentang 24 jam ke belakang presisi dari waktu saat ini
    final endDateStr = focusDate.toUtc().toIso8601String();
    context.read<SensorProvider>().fetchAnalysisData(timeRange: activeRange, endDate: endDateStr);
  }

  void _changePeriod(int direction) {
    setState(() {
      if (activeRange == "1d") {
        focusDate = focusDate.add(Duration(days: direction));
      } else if (activeRange == "1w") {
        focusDate = focusDate.add(Duration(days: direction * 7));
      } else if (activeRange == "1m") {
        // Pertahankan komponen jam/menit saat geser bulan
        focusDate = DateTime(
          focusDate.year, focusDate.month + direction, focusDate.day,
          focusDate.hour, focusDate.minute, focusDate.second
        );
      }

      // Jangan izinkan endDate melebihi waktu sekarang (sama seperti web)
      if (focusDate.isAfter(DateTime.now())) {
        focusDate = DateTime.now();
      }
    });
    _refreshAnalysis();
  }

  String _getDateLabel() {
    if (activeRange == "1d") {
      return DateFormat('EEEE, dd MMM yyyy').format(focusDate);
    } else if (activeRange == "1w") {
      final start = focusDate.subtract(const Duration(days: 6));
      return "${DateFormat('dd MMM').format(start)} - ${DateFormat('dd MMM yyyy').format(focusDate)}";
    } else {
      return DateFormat('MMMM yyyy').format(focusDate);
    }
  }

  Map<String, dynamic> _getTrend(List<SensorData> history) {
    if (history.length < 2) return {"value": 0.0, "isUp": true};
    final selector = _getSelector(activeSensor.id);
    final first = selector(history.first);
    final last = selector(history.last);
    if (first == 0) return {"value": 0.0, "isUp": true};
    final diff = ((last - first) / first) * 100;
    return {"value": diff.abs(), "isUp": diff >= 0};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Detail Grafik", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAnalysis,
          ),
        ],
      ),
      body: Consumer<SensorProvider>(
        builder: (context, provider, child) {
          final stats = provider.analysisStats;
          final analysisHistory = provider.analysisData;
          final dashboardHistory = provider.historyData;
          final latestData = provider.latestData;
          final trend = _getTrend(analysisHistory);

          return Column(
            children: [
              _buildSensorSelector(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      // --- BAGIAN 1: Grafik Realtime (seperti Dashboard) ---
                      _buildDashboardChart(dashboardHistory, latestData),
                      const SizedBox(height: 28),
                      // --- BAGIAN 2: Tren Analitik (1D/1W/1M) ---
                      _buildAnalyticsSection(provider, analysisHistory, stats, trend),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================
  // BAGIAN 1: Grafik Realtime dari Dashboard
  // ============================================================
  Widget _buildDashboardChart(List<SensorData> history, SensorData? latestData) {
    String currentValue = "--";
    if (latestData != null) {
      final selector = _getSelector(activeSensor.id);
      final val = selector(latestData);
      currentValue = (activeSensor.id == "phValue") ? val.toStringAsFixed(2) : val.toStringAsFixed(1);
      if (activeSensor.unit.isNotEmpty) currentValue = "$currentValue ${activeSensor.unit}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(activeSensor.icon, size: 22, color: activeSensor.color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activeSensor.category, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                  Text("Grafik ${activeSensor.label}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 6)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: chartItem(
              activeSensor.category, 
              activeSensor.label, 
              currentValue,
              activeSensor.color, 
              history, 
              _getSelector(activeSensor.id),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BAGIAN 2: Tren Analitik (1D/1W/1M + Ringkasan Statistik)
  // ============================================================
  Widget _buildAnalyticsSection(SensorProvider provider, List<SensorData> analysisHistory, Map<String, dynamic> stats, Map<String, dynamic> trend) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header + Range Selector
        _buildHeaderWithRange(),
        const SizedBox(height: 16),
        // Time Navigator
        _buildTimeNavigator(),
        // Analytics Chart Card
        _buildAnalyticsChartCard(provider, analysisHistory, trend),
        const SizedBox(height: 24),
        // Stats Grid
        _buildStatsGrid(stats),
      ],
    );
  }

  Widget _buildSensorSelector() {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: sensorTypes.length,
        itemBuilder: (context, index) {
          final s = sensorTypes[index];
          final isActive = activeSensor.id == s.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  activeSensor = s;
                });
                _refreshAnalysis();
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isActive ? s.color.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isActive ? s.color : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(s.icon, size: 18, color: isActive ? s.color : Colors.grey.shade400),
                    const SizedBox(width: 8),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: isActive ? s.color : Colors.grey.shade500,
                        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderWithRange() {
    final ranges = [
      {"id": "1d", "label": "1D"},
      {"id": "1w", "label": "1W"},
      {"id": "1m", "label": "1M"},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TREN ANALITIK", style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(
                "${activeSensor.label} Overview",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: ranges.map((r) {
              final isActive = activeRange == r["id"];
              return InkWell(
                onTap: () {
                  setState(() {
                    activeRange = r["id"]!;
                    focusDate = DateTime.now();
                  });
                  _refreshAnalysis();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isActive ? [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
                    ] : [],
                  ),
                  child: Text(
                    r["label"]!,
                    style: TextStyle(
                      color: isActive ? Colors.black : Colors.grey.shade500,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeNavigator() {
    final canGoNext = focusDate.isBefore(DateTime.now().subtract(const Duration(hours: 1)));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _navBtn(Icons.chevron_left, () => _changePeriod(-1)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              _getDateLabel(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          _navBtn(Icons.chevron_right, canGoNext ? () => _changePeriod(1) : null),
        ],
      ),
    );
  }

  Widget _navBtn(IconData icon, VoidCallback? onPressed) {
    final isDisabled = onPressed == null;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Icon(icon, size: 20, color: isDisabled ? Colors.grey.shade300 : Colors.black),
      ),
    );
  }

  Widget _buildAnalyticsChartCard(SensorProvider provider, List<SensorData> history, Map<String, dynamic> trend) {
    final trendVal = trend['value'] as double;
    final isUp = trend['isUp'] as bool;
    
    double chartWidth = history.length * 60.0;
    final screenWidth = MediaQuery.of(context).size.width - 64;
    if (chartWidth < screenWidth) chartWidth = screenWidth;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, 8)),
        ],
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Trend Analitik", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              if (trendVal > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(isUp ? Icons.arrow_upward : Icons.arrow_downward, size: 14, color: isUp ? Colors.green : Colors.red),
                      const SizedBox(width: 4),
                      Text(
                        "${trendVal.toStringAsFixed(1)}%",
                        style: TextStyle(color: isUp ? Colors.green : Colors.red, fontWeight: FontWeight.w800, fontSize: 12),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          provider.isLoading
            ? Container(
                height: 250,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(color: Color(0xff03AF55)),
              )
            : history.isEmpty
              ? Container(
                  height: 250,
                  alignment: Alignment.center,
                  child: const Text("Tidak ada data untuk periode ini", style: TextStyle(color: Colors.grey)),
                )
              : SizedBox(
                  height: 320,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFixedYAxis(history),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Container(
                            width: chartWidth,
                            height: 320,
                            padding: const EdgeInsets.only(right: 20, bottom: 10),
                            child: _buildAnalyticsLineChart(history),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // Kunci agar sama persis dengan web (Recharts): Gunakan Index-Based Categorical X-Axis
  // Setiap data point diletakkan pada x = 0, 1, 2, 3... sehingga jarak antar titik selalu sama.
  List<FlSpot> _indexSpots(List<SensorData> history) {
    final selector = _getSelector(activeSensor.id);
    List<FlSpot> spots = [];
    for (int i = 0; i < history.length; i++) {
      spots.add(FlSpot(i.toDouble(), selector(history[i])));
    }
    return spots;
  }

  // Hitung Y range dari spots
  Map<String, double> _calcYRange(List<FlSpot> spots) {
    double minY = 0, maxY = 100;
    if (spots.isNotEmpty) {
      minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
      maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    }
    if (maxY == minY) { maxY += 10; minY -= 10; }
    else {
      final range = maxY - minY;
      maxY += range * 0.15;
      minY -= range * 0.15;
    }
    if (minY < 0) minY = 0;
    return {"minY": minY, "maxY": maxY};
  }

  Widget _buildFixedYAxis(List<SensorData> history) {
    final spots = _indexSpots(history);
    if (spots.isEmpty) return const SizedBox(width: 55);

    final yr = _calcYRange(spots);
    final minY = yr["minY"]!;
    final maxY = yr["maxY"]!;
    
    const int divisions = 6;
    final double interval = (maxY - minY) / 5;

    return Container(
      width: 55,
      margin: const EdgeInsets.only(bottom: 38, top: 8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(divisions, (index) {
          double val = maxY - (index * interval);
          String label = (activeSensor.id == "phValue") ? val.toStringAsFixed(1) : val.toInt().toString();
          return Text(
            "$label${activeSensor.unit}",
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w800),
          );
        }),
      ),
    );
  }

  Widget _buildAnalyticsLineChart(List<SensorData> history) {
    final validHistory = history.where((d) => d.createdAt != null).toList();
    final spots = _indexSpots(validHistory);
    if (spots.isEmpty) return const SizedBox();

    final yr = _calcYRange(spots);
    final minY = yr["minY"]!;
    final maxY = yr["maxY"]!;

    // Tentukan berapa banyak titik yang harus dilewati agar label X tidak menumpuk
    // Mirip dengan auto-skip ticks di web
    double xLabelInterval;
    if (spots.length <= 6) {
      xLabelInterval = 1;
    } else {
      xLabelInterval = (spots.length / 6).ceilToDouble();
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(color: Colors.grey.withValues(alpha: 0.3), strokeWidth: 1, dashArray: [3, 3]),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                    radius: 4,
                    color: activeSensor.color,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
                ),
              );
            }).toList();
          },
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipMargin: 16,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            tooltipRoundedRadius: 8,
            getTooltipColor: (spot) => Theme.of(context).cardColor,
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final index = s.x.toInt();
              if (index < 0 || index >= validHistory.length) return null;
              final date = validHistory[index].createdAt!;
              
              // Format tooltip sesuai rentang waktu (sama dengan web)
              String timeLabel;
              if (activeRange == "1d") {
                timeLabel = DateFormat('HH:mm').format(date);
              } else {
                timeLabel = DateFormat('d MMM').format(date);
              }

              return LineTooltipItem(
                "$timeLabel\n",
                const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.normal),
                children: [
                  TextSpan(
                    text: "${s.y.toStringAsFixed(activeSensor.id == "phValue" ? 2 : 1)} ${activeSensor.unit}",
                    style: TextStyle(color: activeSensor.color, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (maxY - minY) / 5 > 0 ? (maxY - minY) / 5 : 1,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1, dashArray: [3, 3]),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: xLabelInterval,
              getTitlesWidget: (val, meta) {
                final index = val.toInt();
                // Hanya render teks jika indeks valid
                if (index < 0 || index >= validHistory.length) return const SizedBox();
                
                // Pastikan yang dirender hanya titik sesuai interval untuk mencegah text overlapping di indeks lain yang ter-draw otomatis
                if (index % xLabelInterval.toInt() != 0 && index != validHistory.length - 1 && index != 0) {
                  return const SizedBox();
                }

                final date = validHistory[index].createdAt!;
                String label;

                // Format sesuai web
                if (activeRange == "1d") {
                  label = DateFormat('HH:mm').format(date);
                } else {
                  label = DateFormat('d MMM').format(date);
                }

                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 8,
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                );
              },
            ),
          ),
        ),
        clipData: const FlClipData.none(),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (validHistory.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: activeSensor.color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [activeSensor.color.withValues(alpha: 0.4), activeSensor.color.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    final sensorId = activeSensor.id;
    final capitalizedId = sensorId[0].toUpperCase() + sensorId.substring(1);

    double min, max, avg;

    // Ketinggian air belum ada dari API, gunakan nilai placeholder
    if (sensorId == "waterLevel") {
      min = 12.0;
      max = 12.0;
      avg = 12.0;
    } else {
      min = (stats['min$capitalizedId'] ?? 0.0).toDouble();
      max = (stats['max$capitalizedId'] ?? 0.0).toDouble();
      avg = (stats['avg$capitalizedId'] ?? 0.0).toDouble();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ringkasan Statistik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statCard("Terendah", min, activeSensor.unit, Colors.red, Icons.arrow_downward)),
            const SizedBox(width: 12),
            Expanded(child: _statCard("Tertinggi", max, activeSensor.unit, Colors.green, Icons.arrow_upward)),
          ],
        ),
        const SizedBox(height: 12),
        _statCard("Rata-rata Periode", avg, activeSensor.unit, Colors.blue, Icons.analytics, isWide: true),
      ],
    );
  }

  Widget _statCard(String label, double value, String unit, Color color, IconData icon, {bool isWide = false}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value.toStringAsFixed(activeSensor.id == "phValue" ? 2 : 1),
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 4),
              Text(unit, style: TextStyle(fontSize: 14, color: Colors.grey.shade400, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }

  double Function(SensorData) _getSelector(String id) {
    switch (id) {
      case "waterLevel": return (d) => 12.0; // Placeholder - belum ada sensor fisik
      case "airTemp": return (d) => d.airTemp;
      case "airHumidity": return (d) => d.airHumidity;
      case "waterTemp": return (d) => d.waterTemp;
      case "lightLux": return (d) => d.lightLux;
      case "tdsPPM": return (d) => d.tdsPPM;
      case "phValue": return (d) => d.phValue;
      default: return (d) => d.tdsPPM;
    }
  }
}
