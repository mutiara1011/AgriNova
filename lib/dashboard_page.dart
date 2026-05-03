import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:agrinova/detail_chart_page.dart';
import 'notification/notification_page.dart';
import 'dart:async';
import 'package:agrinova/fuzzy/fuzzy_controller.dart';
import 'package:agrinova/providers/sensor_provider.dart';
import 'package:agrinova/models/sensor_data.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SensorProvider>().fetchHistoryData();
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
    await provider.fetchLatestData();
    await provider.fetchHistoryData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _appBar(),
      body: Consumer<SensorProvider>(
        builder: (context, sensor, child) {
          // Loading screen saat pertama kali buka dan API belum tersambung
          if (sensor.latestData == null && sensor.historyData.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xff03AF55)),
                  SizedBox(height: 20),
                  Text(
                    "Menghubungkan ke server...",
                    style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Memuat data sensor",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Pull to refresh
          return RefreshIndicator(
            onRefresh: _onRefresh,
            color: const Color(0xff03AF55),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _plantInfoCard(context),
                  const SizedBox(height: 16),
                  _sensorGrid(context),
                  const SizedBox(height: 16),
                  _chartSlider(context),
                  const SizedBox(height: 12),
                  _lastUpdatedText(context),
                  const SizedBox(height: 16),
                  _fuzzyStatusCard(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _lastUpdatedText(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, sensor, child) {
        final date = sensor.latestData?.createdAt ?? DateTime.now();
        final timeStr = "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}";
        return Text(
          "Terakhir diperbarui: $timeStr",
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
        );
      }
    );
  }

  AppBar _appBar() {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      centerTitle: true,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo.png', height: 36),
          const SizedBox(width: 6),
          Text(
            'AGRINOVA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Theme.of(context).textTheme.bodyMedium!.color,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationPage()),
              );
            },
            child: const Icon(
              Icons.circle_notifications_outlined,
              size: 28,
              color: Color(0xff03AF55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _plantInfoCard(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shadowColor: Theme.of(context).shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/selada_romaine.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff03AF55).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Jenis Tanaman :', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                  Text('Selada Romaine', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  Text('HST :', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400)),
                  Text('Hari ke-14', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sensorGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 380;
    
    return Consumer<SensorProvider>(
      builder: (context, sensor, child) {
        final data = sensor.latestData;
        return GridView.count(
          crossAxisCount: isSmall ? 1 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isSmall ? 1.4 : 1.6,
          children: [
            _SensorCard(title: 'Ketinggian Air', value: '12.0 cm', status: 'Normal', icon: Icons.water),
            _SensorCard(title: 'Suhu Udara', value: '${data?.airTemp.toStringAsFixed(1) ?? '--'}°C', status: '', icon: Icons.device_thermostat),
            _SensorCard(title: 'Kelembapan Udara', value: '${data?.airHumidity.toStringAsFixed(1) ?? '--'}%', status: '', icon: Icons.water_drop),
            _SensorCard(title: 'Suhu Air', value: '${data?.waterTemp.toStringAsFixed(1) ?? '--'}°C', status: '', icon: Icons.thermostat),
            _SensorCard(title: 'Intensitas Cahaya', value: '${data?.lightLux.toStringAsFixed(0) ?? '--'} Lux', status: '', icon: Icons.light_mode),
            _SensorCard(title: 'TDS (Nutrisi Air)', value: '${data?.tdsPPM.toStringAsFixed(0) ?? '--'} PPM', status: '', icon: Icons.speed),
            _SensorCard(title: 'pH (Keasaman Air)', value: '${data?.phValue.toStringAsFixed(1) ?? '--'}', status: '', icon: Icons.science),
            _SensorCard(title: 'Indikator Cuaca', value: 'Cerah', status: '', icon: Icons.cloud),
          ],
        );
      }
    );
  }


  Widget _chartSlider(BuildContext context) {
    return Consumer<SensorProvider>(
      builder: (context, sensor, child) {
        final data = sensor.latestData;
        final history = sensor.historyData;
        
        // Urutan sama dengan sensor grid
        final charts = [
          chartItem("LEVEL", "Ketinggian Air", "12.0 cm", const Color(0xff0ea5e9), history, (d) => 12.0),
          chartItem("ATMOSFER", "Suhu Udara", "${data?.airTemp.toStringAsFixed(1) ?? '--'}°C", const Color(0xfff97316), history, (d) => d.airTemp),
          chartItem("UDARA", "Kelembapan Udara", "${data?.airHumidity.toStringAsFixed(1) ?? '--'}%", const Color(0xff3b82f6), history, (d) => d.airHumidity),
          chartItem("RESERVOIR", "Suhu Air", "${data?.waterTemp.toStringAsFixed(1) ?? '--'}°C", const Color(0xff06b6d4), history, (d) => d.waterTemp),
          chartItem("FOTOSINTESIS", "Intensitas Cahaya", "${data?.lightLux.toStringAsFixed(0) ?? '--'} Lux", const Color(0xffeab308), history, (d) => d.lightLux),
          chartItem("NUTRISI", "TDS (Nutrisi Air)", "${data?.tdsPPM.toStringAsFixed(0) ?? '--'} PPM", const Color(0xff8b5cf6), history, (d) => d.tdsPPM),
          chartItem("KEASAMAN", "pH (Keasaman Air)", "${data?.phValue.toStringAsFixed(1) ?? '--'}", const Color(0xff14b8a6), history, (d) => d.phValue),
        ];

        return Card(
          color: Theme.of(context).cardColor,
          elevation: 8,
          shadowColor: Theme.of(context).shadowColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  height: 250,
                  child: PageView.builder(
                    controller: controller,
                    itemCount: charts.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return charts[index];
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(charts.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: currentIndex == index ? 10 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: currentIndex == index ? const Color(0xff03AF55) : Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    );
                  }),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => DetailChartPage()));
                    },
                    child: const Text("Lihat Detail", style: TextStyle(color: Color(0xff03AF55))),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _fuzzyStatusCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final fuzzy = context.watch<FuzzyController>();
    return GestureDetector(
      onTap: () {
        widget.onTabChange(2);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1B8E3E), Color(0xff03AF55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.psychology, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                const Text(
                  "LOGIKA FUZZY",
                  style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 1),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text("Status Nutrisi Saat Ini", style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              "Nutrisi ${fuzzy.statusNutrisi}",
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (fuzzy.outputPompa / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Status pH: ${fuzzy.statusPh} | Output: ${fuzzy.outputPompa.toStringAsFixed(1)}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

Widget chartItem(String label, String title, String value, Color color, List<SensorData> history, double Function(SensorData) selector) {
  final data = generateChartSpots(history, selector);
  double minY = 0;
  double maxY = 100;

  String unit = "";
  if (label == "NUTRISI") unit = " PPM";
  else if (label == "KEASAMAN") unit = "";
  else if (label == "ATMOSFER" || label == "RESERVOIR") unit = "°C";
  else if (label == "UDARA") unit = "%";
  else if (label == "FOTOSINTESIS") unit = " Lx";
  else if (label == "LEVEL") unit = " cm";

  if (label == "KEASAMAN") { maxY = 14; minY = 0; }
  else if (label == "UDARA") { maxY = 100; minY = 0; }
  else if (label == "ATMOSFER" || label == "RESERVOIR") { maxY = 50; minY = 0; }
  else if (label == "LEVEL") { maxY = 30; minY = 0; }
  else { maxY = 1000; minY = 0; }

  if (data.isNotEmpty && data.any((s) => s.y != 0)) {
    double dataMin = data.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double dataMax = data.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    
    if (dataMax > maxY) maxY = (dataMax * 1.1).ceilToDouble();
    if (dataMin < minY) minY = (dataMin * 0.9).floorToDouble();
    
    double range = dataMax - dataMin;
    if (range > 0 && range < (maxY - minY) * 0.2) {
       minY = (dataMin - (range * 0.5)).floorToDouble();
       maxY = (dataMax + (range * 0.5)).ceilToDouble();
    }
  }
  
  if (minY < 0) minY = 0;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              const SizedBox(height: 2),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 160,
        child: LineChart(
          LineChartData(
            lineTouchData: LineTouchData(
              handleBuiltInTouches: true,
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (spot) => color.withValues(alpha: 0.8),
                tooltipRoundedRadius: 8,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final index = barSpot.x.toInt();
                    if (index < 0 || index >= history.length) return null;
                    final date = history[index].createdAt;
                    final timeStr = date != null 
                        ? "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}"
                        : "";
                    return LineTooltipItem(
                      '${barSpot.y.toStringAsFixed(label == "KEASAMAN" ? 2 : 1)}$unit\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      children: [
                        TextSpan(
                          text: timeStr,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w400, fontSize: 11),
                        ),
                      ],
                    );
                  }).toList();
                },
              ),
              getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                return spotIndexes.map((index) {
                  return TouchedSpotIndicatorData(
                    FlLine(color: color.withValues(alpha: 0.3), strokeWidth: 2),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 6,
                        color: color,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  );
                }).toList();
              },
            ),
            minX: 0,
            maxX: data.isNotEmpty ? (data.length - 1).toDouble() : 1,
            minY: minY,
            maxY: maxY,
            clipData: const FlClipData.all(),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY - minY) / 4 > 0 ? (maxY - minY) / 4 : 1,
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.withValues(alpha: 0.08),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 45,
                  interval: (maxY - minY) / 4 > 0 ? (maxY - minY) / 4 : 1,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.max || value == meta.min) return const SizedBox();
                    String labelStr = (label == "KEASAMAN" || label == "ATMOSFER" || label == "RESERVOIR") 
                        ? value.toStringAsFixed(1) 
                        : value.toInt().toString();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 10,
                      child: Text("$labelStr$unit", style: const TextStyle(fontSize: 8, color: Colors.grey, fontWeight: FontWeight.w600)),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 22,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    bool shouldShow = index == 0 || index == history.length - 1 || index % 5 == 0;
                    if (!shouldShow || index < 0 || index >= history.length) return const SizedBox();
                    final date = history[index].createdAt;
                    if (date == null) return const SizedBox();
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      space: 6,
                      child: Text(
                        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                curveSmoothness: 0.4,
                color: color,
                barWidth: 4,
                isStrokeCapRound: true,
                spots: data,
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    colors: [color.withValues(alpha: 0.25), color.withValues(alpha: 0.0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                dotData: const FlDotData(show: false),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

List<FlSpot> generateChartSpots(List<SensorData> history, double Function(SensorData) selector) {
  if (history.isEmpty) return [const FlSpot(0, 0)];
  List<FlSpot> spots = [];
  for (int i = 0; i < history.length; i++) {
    spots.add(FlSpot(i.toDouble(), selector(history[i])));
  }
  return spots;
}

class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final IconData icon;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shadowColor: Theme.of(context).shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: const Color(0xff03AF55)),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      if (status.isNotEmpty)
                        Text(status, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xff03AF55))),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
