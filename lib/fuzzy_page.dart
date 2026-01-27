import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy_controller.dart';

class FuzzyPage extends StatelessWidget {
  const FuzzyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FUZZY LOGIC',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Fuzzy Mamdani'),
                  content: const Text(
                    'Halaman ini menampilkan hasil evaluasi sistem '
                    'berdasarkan metode Fuzzy Mamdani dari data sensor.',
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            _FuzzyStatusCard(),
            SizedBox(height: 16),
            _ConditionCard(),
            SizedBox(height: 16),
            _MembershipCard(),
            SizedBox(height: 16),
            _RuleCard(),
            SizedBox(height: 16),
            _RecommendationCard(),
            SizedBox(height: 16),
            _HistoryCard(),
          ],
        ),
      ),
    );
  }
}

//
// ================= STATUS FUZZY =================
//
class _FuzzyStatusCard extends StatelessWidget {
  const _FuzzyStatusCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text(
              'STATUS EVALUASI FUZZY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Gauge(label: 'pH', value: '6.2', status: 'Optimal'),
                _Gauge(label: 'TDS', value: '800 PPM', status: 'Optimal'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  final String label;
  final String value;
  final String status;

  const _Gauge({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.speed, size: 48, color: Colors.green),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(value),
        Text(status, style: const TextStyle(color: Colors.green)),
      ],
    );
  }
}

//
// ================= KONDISI =================
//
class _ConditionCard extends StatelessWidget {
  const _ConditionCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'KONDISI SAAT INI',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• pH Air : Normal'),
            Text('• Nutrisi (TDS) : Normal'),
            Text('• Sistem : Stabil'),
          ],
        ),
      ),
    );
  }
}

//
// ================= MEMBERSHIP =================
//
class _MembershipCard extends StatelessWidget {
  const _MembershipCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'MEMBERSHIP FUNCTION',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Text(
                  'Grafik Membership pH & TDS\n(placeholder)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//
// ================= RULE =================
//
class _RuleCard extends StatelessWidget {
  const _RuleCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'RULE YANG DIGUNAKAN',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('IF pH = Normal'),
            Text('AND TDS = Normal'),
            Text('THEN'),
            Text('• Pompa Nutrisi : Mati'),
            Text('• Aerator : Normal'),
          ],
        ),
      ),
    );
  }
}

//
// ================= REKOMENDASI =================
//
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(
          fuzzy.pompaAktif ? Icons.warning : Icons.check_circle,
          color: fuzzy.pompaAktif ? Colors.orange : Colors.green,
        ),
        title: const Text(
          'REKOMENDASI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(fuzzy.rekomendasi),
      ),
    );
  }
}

//
// ================= RIWAYAT =================
//
class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'RIWAYAT FUZZY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('10:30 - Tidak ada aksi'),
            Text('09:30 - Pompa nutrisi aktif'),
          ],
        ),
      ),
    );
  }
}
