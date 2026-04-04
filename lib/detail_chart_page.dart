import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'dummy_data.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

// ================= MODEL =================
class ChartData {
  final String label;
  final String title;
  final String value;
  final Color color;

  ChartData(this.label, this.title, this.value, this.color);
}

// ================= PAGE =================
class DetailChartPage extends StatefulWidget {
  const DetailChartPage({super.key});

  @override
  State<DetailChartPage> createState() => _DetailChartPageState();
}

class _DetailChartPageState extends State<DetailChartPage> {
  late Timer timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    // DATA CHART (FLEKSIBEL)
    final charts = [
      ChartData(
        "NUTRISI",
        "Grafik TDS",
        "${DummyData.tds.toInt()} PPM",
        Colors.green,
      ),
      ChartData(
        "KEASAMAN",
        "Grafik PH",
        DummyData.ph.toStringAsFixed(1),
        Colors.pink,
      ),
      ChartData(
        "ATMOSFER",
        "Grafik Suhu Ruangan",
        "${DummyData.suhu.toStringAsFixed(1)}°C",
        Colors.blue,
      ),
      ChartData(
        "UDARA",
        "Kelembapan Ruangan",
        "${DummyData.kelembapan.toInt()}%",
        Colors.blueGrey,
      ),
      ChartData(
        "RESERVOIR",
        "Grafik Suhu Air",
        "${DummyData.suhuAir.toStringAsFixed(1)}°C",
        Colors.green,
      ),
      ChartData(
        "FOTOSINTESIS",
        "Intensitas Cahaya",
        "${DummyData.cahaya.toInt()} Lux",
        Colors.orange,
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Detail Grafik"),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyMedium!.color,
        elevation: 0,
      ),

      // ================= BODY =================
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16), // ⬅️ sama kayak dashboard
          child: Column(
            children: charts.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _chartWrapper(
                  context,
                  chartItem(
                    c.label,
                    c.title,
                    c.value,
                    c.color,
                    _getChartData(c.label),
                  ),
                  height,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  List<FlSpot> _getChartData(String label) {
    switch (label) {
      case "NUTRISI":
        return DummyData.tdsChart();
      case "KEASAMAN":
        return DummyData.phChart();
      case "ATMOSFER":
        return DummyData.suhuChart();
      case "UDARA":
        return DummyData.kelembapanChart();
      case "RESERVOIR":
        return DummyData.suhuAirChart();
      case "FOTOSINTESIS":
        return DummyData.cahayaChart();
      default:
        return DummyData.tdsChart();
    }
  }

  // ================= WRAPPER CARD =================
  Widget _chartWrapper(BuildContext context, Widget chart, double height) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      // ⬇️ RESPONSIVE HEIGHT
      child: Column(
        children: [
          SizedBox(
            height: height * 0.22, // sedikit dikurangi biar muat label
            child: chart,
          ),
        ],
      ),
    );
  }
}
