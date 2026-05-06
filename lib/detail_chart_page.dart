import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agrinova/providers/sensor_provider.dart';
import 'package:agrinova/models/sensor_data.dart';
import 'package:agrinova/providers/plant_provider.dart';
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
    final endDateStr = focusDate.toUtc().toIso8601String();
    final plant = context.read<PlantProvider>().activePlant;
    context.read<SensorProvider>().fetchAnalysisData(
      timeRange: activeRange, 
      endDate: endDateStr,
      startDate: plant?.startDate,
    );
  }


  void _changePeriod(int direction) {
    setState(() {
      if (activeRange == "1d") {
        focusDate = focusDate.add(Duration(days: direction));
      } else if (activeRange == "1w") {
        focusDate = focusDate.add(Duration(days: direction * 7));
      } else if (activeRange == "1m") {
        focusDate = DateTime(
          focusDate.year, focusDate.month + direction, focusDate.day,
          focusDate.hour, focusDate.minute, focusDate.second
        );
      }
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Analisis Parameter", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAnalysis,
          ),
        ],
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: const Duration(seconds: 1),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  activeSensor.color.withValues(alpha: 0.8),
                  activeSensor.color.withValues(alpha: 0.4),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.2, 0.5],
              ),
            ),
          ),
          Consumer<SensorProvider>(
            builder: (context, provider, child) {
              final stats = provider.analysisStats;
              final history = provider.analysisData;
              final latestData = provider.latestData;
              final trend = _getTrend(history);

              return SafeArea(
                child: Column(
                  children: [
                    _buildSensorSelector(),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeroHeader(latestData),
                            const SizedBox(height: 24),
                            _buildAnalyticsCard(provider, history, trend),
                            const SizedBox(height: 24),
                            _buildInsightCard(latestData, stats),
                            const SizedBox(height: 24),
                            _buildStatsGrid(stats),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader(SensorData? latestData) {
    String value = "--";
    if (latestData != null) {
      final val = _getSelector(activeSensor.id)(latestData);
      value = (activeSensor.id == "phValue") ? val.toStringAsFixed(2) : val.toStringAsFixed(1);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activeSensor.label.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.w900),
                ),
                const SizedBox(width: 8),
                Text(
                  activeSensor.unit,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
          ),
          child: Icon(activeSensor.icon, color: Colors.white, size: 32),
        ),
      ],
    );
  }

  Widget _buildSensorSelector() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sensorTypes.length,
        itemBuilder: (context, index) {
          final s = sensorTypes[index];
          final isActive = activeSensor.id == s.id;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () {
                setState(() => activeSensor = s);
                _refreshAnalysis();
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isActive ? [BoxShadow(color: s.color.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                ),
                child: Row(
                  children: [
                    Icon(s.icon, size: 20, color: isActive ? s.color : Colors.white.withValues(alpha: 0.7)),
                    const SizedBox(width: 10),
                    Text(
                      s.label,
                      style: TextStyle(
                        color: isActive ? Colors.black : Colors.white.withValues(alpha: 0.7),
                        fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 14,
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

  Widget _buildAnalyticsCard(SensorProvider provider, List<SensorData> history, Map<String, dynamic> trend) {
    final trendVal = trend['value'] as double;
    final isUp = trend['isUp'] as bool;
    
    return _PremiumCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text("Tren Historis", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(_getDateLabel(), style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              _buildRangeSelector(),
            ],
          ),
          const SizedBox(height: 28),
          _buildTimeNavigator(),
          const SizedBox(height: 12),
          SizedBox(
            height: 250,
            child: provider.isLoading 
              ? const Center(child: CircularProgressIndicator()) 
              : _buildModernChart(history),
          ),

          const SizedBox(height: 24),
          if (trendVal > 0) _buildTrendIndicator(trendVal, isUp),
        ],
      ),
    );
  }

  Widget _buildRangeSelector() {
    final ranges = ["1d", "1w", "1m"];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: ranges.map((r) {
          final isActive = activeRange == r;
          return GestureDetector(
            onTap: () {
              setState(() {
                activeRange = r;
                focusDate = DateTime.now();
              });
              _refreshAnalysis();
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isActive ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)] : [],
              ),
              child: Text(
                r.toUpperCase(),
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.grey,
                  fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTimeNavigator() {
    final canGoNext = focusDate.isBefore(DateTime.now().subtract(const Duration(hours: 1)));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _navCircleBtn(Icons.chevron_left, () => _changePeriod(-1)),
        const Text("Geser untuk melihat periode lain", style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
        _navCircleBtn(Icons.chevron_right, canGoNext ? () => _changePeriod(1) : null),
      ],
    );
  }

  Widget _navCircleBtn(IconData icon, VoidCallback? onTap) {
    final isDisabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDisabled ? Colors.transparent : activeSensor.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: isDisabled ? Colors.grey.shade300 : activeSensor.color),
      ),
    );
  }

  Widget _buildModernChart(List<SensorData> history) {
    if (history.isEmpty) return const Center(child: Text("Data tidak tersedia"));
    
    final validHistory = history.where((d) => d.createdAt != null).toList();
    final spots = _indexSpots(validHistory);
    final yr = _calcYRange(spots);
    
    double xLabelInterval = (spots.length / 5).ceilToDouble();
    if (xLabelInterval < 1) xLabelInterval = 1;

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (spot) => activeSensor.color,
            tooltipRoundedRadius: 12,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) {
              final date = validHistory[s.x.toInt()].createdAt!;
              final timeLabel = activeRange == "1d" ? DateFormat('HH:mm').format(date) : DateFormat('d MMM').format(date);
              return LineTooltipItem(
                "$timeLabel\n",
                const TextStyle(color: Colors.white70, fontSize: 10),
                children: [
                  TextSpan(
                    text: "${s.y.toStringAsFixed(activeSensor.id == "phValue" ? 2 : 1)} ${activeSensor.unit}",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: (yr["maxY"]! - yr["minY"]!) / 4 > 0 ? (yr["maxY"]! - yr["minY"]!) / 4 : 1,
          getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.withValues(alpha: 0.08), strokeWidth: 1, dashArray: [4, 4]),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 45,
              interval: (yr["maxY"]! - yr["minY"]!) / 4 > 0 ? (yr["maxY"]! - yr["minY"]!) / 4 : 1,
              getTitlesWidget: (v, m) {
                if (v == m.max || v == m.min) return const SizedBox();
                return Text(
                  activeSensor.id == "phValue" ? v.toStringAsFixed(1) : v.toInt().toString(),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1, // Controlled by getTitlesWidget logic
              getTitlesWidget: (v, m) {
                final idx = v.toInt();
                if (idx < 0 || idx >= validHistory.length) return const SizedBox();
                
                // Show approx 5-6 labels
                int interval = (validHistory.length / 5).ceil();
                if (interval < 1) interval = 1;
                
                if (idx % interval != 0 && idx != validHistory.length - 1) return const SizedBox();

                // Avoid showing the second to last label if it's too close to the last one
                if (idx == validHistory.length - 1 - (interval / 2).floor() && idx != validHistory.length - 1) {
                  return const SizedBox();
                }
                
                final date = validHistory[idx].createdAt!;
                return SideTitleWidget(
                  axisSide: m.axisSide,
                  space: 8,
                  child: Text(
                    activeRange == "1d" ? DateFormat('HH:mm').format(date) : DateFormat('d MMM').format(date),
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),

          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (validHistory.length - 1).toDouble(),
        minY: yr["minY"],
        maxY: yr["maxY"],
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: activeSensor.color,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [activeSensor.color.withValues(alpha: 0.25), activeSensor.color.withValues(alpha: 0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(double val, bool isUp) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (isUp ? Colors.green : Colors.red).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(isUp ? Icons.trending_up : Icons.trending_down, color: isUp ? Colors.green : Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tren ${isUp ? 'meningkat' : 'menurun'} sebesar ${val.toStringAsFixed(1)}% dari awal periode.",
              style: TextStyle(fontSize: 12, color: isUp ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(SensorData? latestData, Map<String, dynamic> stats) {
    String insight = "Memuat analisis...";
    Color insightColor = activeSensor.color;
    IconData insightIcon = Icons.auto_awesome;

    if (latestData != null) {

      final val = _getSelector(activeSensor.id)(latestData);
      switch (activeSensor.id) {
        case "phValue":
          if (val >= 6.0 && val <= 7.0) {
            insight = "Tingkat pH sangat ideal untuk penyerapan nutrisi selada.";
            insightColor = Colors.green;
          } else if (val < 6.0) {
            insight = "pH terlalu asam. Pertimbangkan untuk menambah cairan pH Up.";
            insightColor = Colors.orange;
            insightIcon = Icons.warning_amber_rounded;
          } else {
            insight = "pH terlalu basa. Gunakan pH Down untuk menyeimbangkannya.";
            insightColor = Colors.orange;
            insightIcon = Icons.warning_amber_rounded;
          }
          break;
        case "tdsPPM":
          if (val >= 560 && val <= 840) {
            insight = "Kadar nutrisi (TDS) berada pada rentang optimal untuk fase pertumbuhan.";
            insightColor = Colors.green;
          } else if (val < 560) {
            insight = "Nutrisi kurang pekat. Tanaman mungkin membutuhkan tambahan nutrisi AB Mix.";
            insightColor = Colors.blue;
          } else {
            insight = "Nutrisi terlalu pekat. Bisa menyebabkan ujung daun terbakar (tip burn).";
            insightColor = Colors.red;
          }
          break;
        case "waterTemp":
          if (val >= 18 && val <= 24) {
            insight = "Suhu air dingin dan kaya oksigen. Sangat baik untuk akar.";
            insightColor = Colors.green;
          } else if (val > 24) {
            insight = "Suhu air mulai hangat. Oksigen terlarut mungkin menurun.";
            insightColor = Colors.orange;
          }
          break;
        default:
          insight = "Parameter ${activeSensor.label} terpantau stabil dalam 24 jam terakhir.";
      }
    }

    return _PremiumCard(
      color: insightColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: insightColor.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: Icon(insightIcon, color: insightColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Smart Insight", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text(insight, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
              ],
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

    min = (stats['min$capitalizedId'] ?? 0.0).toDouble();
    max = (stats['max$capitalizedId'] ?? 0.0).toDouble();
    avg = (stats['avg$capitalizedId'] ?? 0.0).toDouble();


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Ringkasan Statistik", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _statTile("Minimum", min, Icons.arrow_downward, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _statTile("Maksimum", max, Icons.arrow_upward, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _statTile("Rata-rata", avg, Icons.analytics, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _statTile(String label, double val, IconData icon, Color color) {
    return _PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            val.toStringAsFixed(activeSensor.id == "phValue" ? 2 : 1),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          Text(activeSensor.unit, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  double Function(SensorData) _getSelector(String id) {
    switch (id) {
      case "waterLevel": return (d) => 12.0;
      case "airTemp": return (d) => d.airTemp;
      case "airHumidity": return (d) => d.airHumidity;
      case "waterTemp": return (d) => d.waterTemp;
      case "lightLux": return (d) => d.lightLux;
      case "tdsPPM": return (d) => d.tdsPPM;
      case "phValue": return (d) => d.phValue;
      default: return (d) => d.tdsPPM;
    }
  }

  List<FlSpot> _indexSpots(List<SensorData> history) {
    final selector = _getSelector(activeSensor.id);
    return List.generate(history.length, (i) => FlSpot(i.toDouble(), selector(history[i])));
  }

  Map<String, double> _calcYRange(List<FlSpot> spots) {
    if (spots.isEmpty) return {"minY": 0, "maxY": 10};
    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    
    if (maxY == minY) { 
       maxY += 5; minY -= 5; 
    } else {
       final range = maxY - minY;
       maxY += range * 0.2;
       minY -= range * 0.2;
    }
    
    if (minY < 0 && activeSensor.id != "airTemp" && activeSensor.id != "waterTemp") minY = 0;
    return {"minY": minY, "maxY": maxY};
  }
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const _PremiumCard({required this.child, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1),
      ),
      child: child,
    );
  }
}
