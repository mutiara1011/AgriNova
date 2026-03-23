import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy_controller.dart';

class FuzzyPage extends StatelessWidget {
  const FuzzyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(context),
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

  // ================= APP BAR =================
  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'FUZZY LOGIC',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Color(0xff03AF55)),
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Fuzzy Mamdani'),
                content: const Text(
                  'Halaman ini menampilkan hasil evaluasi sistem '
                  'berdasarkan metode Fuzzy Mamdani.',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

//
// ================= STATUS =================
//
class _FuzzyStatusCard extends StatelessWidget {
  const _FuzzyStatusCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: const [
            Text(
              'STATUS EVALUASI FUZZY',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Gauge(label: 'pH', value: '6.2', status: 'Optimal'),
                _Gauge(label: 'TDS', value: '800', status: 'Optimal'),
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
        const Icon(Icons.speed, size: 40, color: Color(0xff03AF55)),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        Text(value),
        Text(
          status,
          style: const TextStyle(
            color: Color(0xff03AF55),
            fontWeight: FontWeight.w500,
          ),
        ),
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
    return _baseCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'KONDISI SAAT INI',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text('• pH Air : Normal'),
          Text('• Nutrisi (TDS) : Normal'),
          Text('• Sistem : Stabil'),
        ],
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
    return _baseCard(
      child: SizedBox(
        height: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'MEMBERSHIP FUNCTION',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Text(
                  'Grafik Membership\n(placeholder)',
                  textAlign: TextAlign.center,
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
    return _baseCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RULE FUZZY',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text('IF pH = Normal'),
          Text('AND TDS = Normal'),
          Text('THEN'),
          Text('• Pompa Nutrisi : Mati'),
          Text('• Aerator : Normal'),
        ],
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
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: ListTile(
        leading: Icon(
          fuzzy.pompaAktif ? Icons.warning : Icons.check_circle,
          color: fuzzy.pompaAktif ? Colors.orange : const Color(0xff03AF55),
        ),
        title: const Text(
          'REKOMENDASI',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(fuzzy.rekomendasi),
      ),
    );
  }
}

//
// ================= HISTORY =================
//
class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    return _baseCard(
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RIWAYAT FUZZY',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text('10:30 - Tidak ada aksi'),
          Text('09:30 - Pompa nutrisi aktif'),
        ],
      ),
    );
  }
}

//
// ================= BASE CARD (BIAR KONSISTEN) =================
//
Widget _baseCard({required Widget child, double minHeight = 120}) {
  return Card(
    color: const Color(0xffEFFAF5),
    elevation: 8,
    shadowColor: Colors.black.withValues(alpha: 0.25),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    child: Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight), // 🔥 KUNCI
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  );
}
