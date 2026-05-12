import 'package:flutter/material.dart';
import 'package:agrinova/models/plant_cycle.dart';
import '../models/sensor_data.dart';
import '../services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class HistoryDetailPage extends StatefulWidget {
  final PlantCycle cycle;

  const HistoryDetailPage({super.key, required this.cycle});

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
  final ApiService _apiService = ApiService();
  List<SensorData> _cycleData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCycleData();
  }

  Future<void> _loadCycleData() async {
    setState(() => _isLoading = true);
    
    try {
      // Jika di model sudah ada data (dari API history), pakai itu
      if (widget.cycle.historyData.isNotEmpty) {
        _cycleData = widget.cycle.historyData;
      } else {
        // Jika kosong, coba tarik dari sensor history umum dengan filter range
        final fetched = await _apiService.getSensorHistory(limit: 500); // Tarik banyak data
        _cycleData = fetched
            .where((d) => 
                d.createdAt != null && 
                !d.createdAt!.isBefore(widget.cycle.startDate) &&
                (widget.cycle.endDate == null || !d.createdAt!.isAfter(widget.cycle.endDate!)))
            .toList();
      }
    } catch (e) {
      print('Error loading cycle data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('dd MMM yyyy, HH:mm').format(widget.cycle.startDate);
    final endStr = widget.cycle.endDate != null 
        ? DateFormat('dd MMM yyyy, HH:mm').format(widget.cycle.endDate!) 
        : 'Sedang Berjalan';
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.cycle.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xff03AF55).withValues(alpha: 0.8),
                  const Color(0xff03AF55).withValues(alpha: 0.4),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.2, 0.5],
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCard(context, startStr, endStr),
                  const SizedBox(height: 24),
                  const Text("Analisis Data Siklus", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 16),
                  if (_isLoading)
                    const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                  else if (_cycleData.isEmpty)
                    _emptyDataPlaceholder()
                  else
                    Column(
                      children: [
                        _buildChartCard("Ketinggian Air", _cycleData, (d) => 12.0, const Color(0xff0ea5e9), "cm"), // Mock for now if not in SensorData
                        const SizedBox(height: 16),
                        _buildChartCard("Suhu Air", _cycleData, (d) => d.waterTemp, const Color(0xff06b6d4), "°C"),
                        const SizedBox(height: 16),
                        _buildChartCard("Nutrisi (TDS)", _cycleData, (d) => d.tdsPPM, const Color(0xff8b5cf6), "PPM"),
                        const SizedBox(height: 16),
                        _buildChartCard("Keasaman (pH)", _cycleData, (d) => d.phValue, const Color(0xff14b8a6), ""),
                        const SizedBox(height: 16),
                        _buildChartCard("Suhu Udara", _cycleData, (d) => d.airTemp, const Color(0xfff97316), "°C"),
                        const SizedBox(height: 16),
                        _buildChartCard("Kelembapan Udara", _cycleData, (d) => d.airHumidity, const Color(0xff3b82f6), "%"),
                        const SizedBox(height: 16),
                        _buildChartCard("Intensitas Cahaya", _cycleData, (d) => d.lightLux, const Color(0xffeab308), "Lux"),
                      ],
                    ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String start, String end) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _infoTile(context, "Mulai", start, Icons.calendar_today_rounded),
              const Spacer(),
              _infoTile(context, "Lama Tanam", "${widget.cycle.hst} Hari", Icons.timer_outlined),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(height: 1),
          ),
          _infoTile(context, "Waktu Panen", end, Icons.check_circle_outline_rounded, isFullWidth: true),
        ],
      ),
    );
  }

  Widget _infoTile(BuildContext context, String label, String value, IconData icon, {bool isFullWidth = false}) {
    return Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xff03AF55)),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800)),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
          ],
        ),
      ],
    );
  }

  Widget _emptyDataPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: const Column(
        children: [
          Icon(Icons.query_stats_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "Tidak Ada Data Sensor",
            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            "Server tidak menemukan catatan sensor selama siklus ini aktif.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, List<SensorData> history, double Function(SensorData) selector, Color color, String unit) {
    final spots = List.generate(history.length, (i) => FlSpot(i.toDouble(), selector(history[i])));
    
    return Container(
      padding: const EdgeInsets.all(20),
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
              Text(unit, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: spots.length > 1 ? (spots.length - 1).toDouble() : 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
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
      ),
    );
  }
}
