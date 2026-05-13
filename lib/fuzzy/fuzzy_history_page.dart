import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy_controller.dart';

class FuzzyHistoryPage extends StatelessWidget {
  const FuzzyHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();
    final logs = fuzzy.logRekomendasi;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'RIWAYAT ANALISIS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xff03AF55).withValues(alpha: 0.1),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          logs.isEmpty
              ? const Center(child: Text("Belum ada data riwayat", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 80, 16, 40),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return _PremiumLogItem(log: log);
                  },
                ),
        ],
      ),
    );
  }
}

class _PremiumLogItem extends StatelessWidget {
  final Map<String, dynamic> log;
  const _PremiumLogItem({required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = log["time"] as DateTime;
    final timeStr = "${time.day}/${time.month} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff03AF55).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.analytics_outlined, color: Color(0xff03AF55), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log["title"],
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  log["desc"],
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
