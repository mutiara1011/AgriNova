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
      appBar: AppBar(
        title: const Text("Riwayat Rekomendasi"),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyMedium!.color,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: logs.isEmpty
          ? const Center(child: Text("Belum ada riwayat"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _logItem(
                    context: context,
                    color: const Color(0xff03AF55),
                    time: _formatTime(log["time"]),
                    title: log["title"],
                    desc: log["desc"],
                  ),
                );
              },
            ),
    );
  }
}

String _formatTime(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inSeconds < 60) return "Baru saja";
  if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
  if (diff.inHours < 24) return "${diff.inHours} jam lalu";

  return "${time.day}/${time.month}";
}

Widget _logItem({
  required context,
  required Color color,
  required String time,
  required String title,
  required String desc,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium!.color,
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
