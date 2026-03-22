import 'package:flutter/material.dart';
import 'dashboard_page.dart';

// ================= MODEL =================
class ChartData {
  final String label;
  final String title;
  final String value;
  final Color color;

  ChartData(this.label, this.title, this.value, this.color);
}

// ================= PAGE =================
class DetailChartPage extends StatelessWidget {
  const DetailChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    // DATA CHART (FLEKSIBEL)
    final charts = [
      ChartData("NUTRISI", "Grafik TDS", "850 PPM", Colors.green),
      ChartData("KEASAMAN", "Grafik PH", "6.2 pH", Colors.pink),
      ChartData("ATMOSFER", "Grafik Suhu Ruangan", "28°C", Colors.blue),
      ChartData("UDARA", "Kelembapan Ruangan", "65%", Colors.blueGrey),
      ChartData("RESERVOIR", "Grafik Suhu Air", "24°C", Colors.green),
      ChartData("FOTOSINTESIS", "Intensitas Cahaya", "1200 Lux", Colors.orange),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Grafik"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
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
                  chartItem(c.label, c.title, c.value, c.color),
                  height,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ================= WRAPPER CARD =================
  Widget _chartWrapper(BuildContext context, Widget chart, double height) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffEFFAF5),
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
      child: SizedBox(
        height: height * 0.25, // 25% layar
        child: chart,
      ),
    );
  }
}
