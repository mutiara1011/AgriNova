import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/plant_provider.dart';
import '../models/plant_cycle.dart';
import 'package:intl/intl.dart';
import 'history_detail_page.dart';


class CycleHistoryPage extends StatelessWidget {
  const CycleHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = context.watch<PlantProvider>().historyCycles.reversed.toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "RIWAYAT TANAMAN",
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5, color: Colors.white),
        ),
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
          history.isEmpty
              ? const Center(child: Text("Belum ada riwayat panen", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 40),
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _CycleCard(cycle: history[index]);
                  },
                ),
        ],
      ),
    );

  }
}

class _CycleCard extends StatelessWidget {
  final PlantCycle cycle;

  const _CycleCard({required this.cycle});

  @override
  Widget build(BuildContext context) {
    final startFormat = DateFormat('dd MMM yyyy').format(cycle.startDate);
    final endFormat = cycle.endDate != null ? DateFormat('dd MMM yyyy').format(cycle.endDate!) : 'N/A';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => HistoryDetailPage(cycle: cycle)),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
            width: 1.5,
          ),
        ),
        child: Column(

        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.eco, color: Color(0xff03AF55), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cycle.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text(
                      "Panen: $endFormat",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tgl Tanam", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800)),
                  Text(startFormat, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Data Tersimpan", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w800)),
                  Text(
                    cycle.historyData.isEmpty ? "Klik untuk Detail" : "${cycle.historyData.length} Data Sensor",
                    style: TextStyle(
                      fontWeight: FontWeight.w700, 
                      fontSize: 12,
                      color: cycle.historyData.isEmpty ? const Color(0xff03AF55) : null,
                    ),
                  ),

                ],
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

