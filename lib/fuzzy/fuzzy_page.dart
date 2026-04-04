import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy_controller.dart';
import 'fuzzy_history_page.dart';
import 'fuzzy_info_page.dart';

class FuzzyPage extends StatelessWidget {
  const FuzzyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'FUZZY LOGIC',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyMedium!.color,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FuzzyInfoPage()),
              );
            },
            child: const Icon(
              Icons.info_outline,
              size: 26,
              color: Color(0xff03AF55),
            ),
          ),
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
    final fuzzy = context.watch<FuzzyController>();

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shadowColor: Theme.of(context).shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'STATUS EVALUASI FUZZY',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _Gauge(
                  label: 'pH',
                  value: fuzzy.ph.toStringAsFixed(1),
                  status: fuzzy.statusPh,
                ),
                _Gauge(
                  label: 'TDS',
                  value: fuzzy.tds.toStringAsFixed(0),
                  status: fuzzy.muTdsTinggi > fuzzy.muTdsRendah
                      ? "Tinggi"
                      : "Rendah",
                ),
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
    final fuzzy = context.watch<FuzzyController>();

    return Card(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shadowColor: Theme.of(context).shadowColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // HEADER
            Row(
              children: const [
                Icon(Icons.analytics, color: Color(0xff03AF55)),
                SizedBox(width: 8),
                Text(
                  'KONDISI SAAT INI',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // GRID DETAIL
            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    context: context,
                    title: "pH Air",
                    value: fuzzy.ph.toStringAsFixed(1),
                    status: fuzzy.statusPh,
                  ),
                ),
                Expanded(
                  child: _infoItem(
                    title: "TDS",
                    context: context,
                    value: "${fuzzy.tds.toStringAsFixed(0)} PPM",
                    status: fuzzy.statusNutrisi,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    context: context,
                    title: "Output Pompa",
                    value: fuzzy.outputPompa.toStringAsFixed(1),
                    status: "Crisp Value",
                  ),
                ),
                Expanded(
                  child: _infoItem(
                    context: context,
                    title: "Rekomendasi",
                    value: fuzzy.rekomendasi,
                    status: "",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: (fuzzy.outputPompa / 100).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xff03AF55),
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
// ================= MEMBERSHIP =================
//
class _MembershipCard extends StatelessWidget {
  const _MembershipCard();

  String getStatus(FuzzyController fuzzy) {
    if (fuzzy.muPhRendah > fuzzy.muPhNormal &&
        fuzzy.muPhRendah > fuzzy.muPhTinggi) {
      return "Asam";
    } else if (fuzzy.muPhNormal > fuzzy.muPhTinggi) {
      return "Normal";
    } else {
      return "Basa";
    }
  }

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();
    final ph = fuzzy.ph;

    final status = getStatus(fuzzy);
    final membership = fuzzy.muPhNormal;

    return _baseCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Membership Function',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff03AF55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Live Data',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),
          const Text(
            'PARAMETER: PH AIR',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 16),

          // 🔥 GRAFIK SEDERHANA (CUSTOM PAINTER)
          SizedBox(
            height: 80,
            width: double.infinity,
            child: CustomPaint(painter: _MembershipPainter(ph)),
          ),

          const SizedBox(height: 8),

          // LABEL BAWAH
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${fuzzy.muPhRendah.toStringAsFixed(2)} (Rendah)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
              Text(
                '${fuzzy.muPhNormal.toStringAsFixed(2)} (Normal)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
              Text(
                '${fuzzy.muPhTinggi.toStringAsFixed(2)} (Tinggi)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // STATUS
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Status Dominan: $status',
              style: const TextStyle(
                color: Color(0xff03AF55),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // NILAI INPUT
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${ph.toStringAsFixed(1)} pH',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          const SizedBox(height: 8),

          // DERAJAT KEANGGOTAAN
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${membership.toStringAsFixed(2)} µ(x)',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipPainter extends CustomPainter {
  final double ph;
  _MembershipPainter(this.ph);
  @override
  void paint(Canvas canvas, Size size) {
    final pointPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;

    double x = (ph / 14) * size.width;
    double y = size.height * 0.5;

    final paintLow = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final paintMid = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final paintHigh = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    // LOW
    final low = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width * 0.3, size.height)
      ..lineTo(size.width * 0.2, 0)
      ..close();

    // MID
    final mid = Path()
      ..moveTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.5, 0)
      ..lineTo(size.width * 0.8, size.height)
      ..close();

    // HIGH
    final high = Path()
      ..moveTo(size.width * 0.7, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.8, 0)
      ..close();

    canvas.drawPath(low, paintLow);
    canvas.drawPath(mid, paintMid);
    canvas.drawPath(high, paintHigh);
    canvas.drawCircle(Offset(x, y), 4, pointPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

//
// ================= RULE =================
//
class _RuleCard extends StatelessWidget {
  const _RuleCard();

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();

    return _baseCard(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Inferensi Rule Mamdani',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),

          const SizedBox(height: 16),

          // R1 (AKTIF)
          _ruleItem(
            context: context,
            label: 'R1',
            isActive: fuzzy.r1Active,
            content: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('IF pH adalah'),
                _chip('Normal', Colors.green),
                const Text('DAN TDS adalah'),
                _chip('Rendah', Colors.green),
                _chip('Tinggi', Colors.red),
                const Text('THEN Dosis Pompa'),
                _chip('Sedang', Colors.grey),
              ],
            ),

            fireValue: fuzzy.r1.toStringAsFixed(2),
          ),

          const SizedBox(height: 12),

          // R2 (TIDAK AKTIF)
          _ruleItem(
            context: context,
            label: 'R2',
            isActive: fuzzy.r2 > 0,
            content: const Text(
              'IF pH rendah DAN TDS rendah THEN Dosis Pompa tinggi',
            ),
            fireValue: fuzzy.r2.toStringAsFixed(2),
          ),

          const SizedBox(height: 12),

          _ruleItem(
            context: context,
            label: 'R3',
            isActive: fuzzy.r3Active,
            content: const Text(
              'IF pH tinggi DAN TDS tinggi THEN Dosis Pompa rendah',
            ),
            fireValue: fuzzy.r3.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }
}

Widget _ruleItem({
  required context,
  required String label,
  required bool isActive,
  required Widget content,
  String? fireValue,
}) {
  return Opacity(
    opacity: isActive ? 1 : 0.5,
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LABEL R1 / R2
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? const Color(0xff03AF55).withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xff03AF55) : Colors.grey,
              ),
            ),
          ),

          const SizedBox(width: 12),

          // CONTENT
          Expanded(child: content),

          // FIRE VALUE
          if (fireValue != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xff03AF55).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'FIRE: $fireValue',
                style: const TextStyle(
                  color: Color(0xff03AF55),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

Widget _chip(String text, Color color) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
    ),
  );
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
      color: Theme.of(context).cardColor,
      elevation: 8,
      shadowColor: Theme.of(context).shadowColor,
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
        subtitle: Text(
          '${fuzzy.rekomendasi} (${fuzzy.outputPompa.toStringAsFixed(1)})',
        ),
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
    final fuzzy = context.watch<FuzzyController>();
    final logs = fuzzy.logRekomendasi.take(5).toList();
    return _baseCard(
      context: context,
      child: logs.isEmpty
          ? const Center(child: Text("Belum ada data"))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Log Rekomendasi',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                ),

                const SizedBox(height: 12),

                Column(
                  children: logs.map((log) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _logItem(
                        context: context,
                        color: const Color(0xff03AF55),
                        time: _formatTime(log["time"]),
                        title: log["title"],
                        desc: log["desc"],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // BUTTON
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const FuzzyHistoryPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Lihat Semua Riwayat',
                      style: TextStyle(
                        color: Color(0xff03AF55),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

String _formatTime(DateTime time) {
  final diff = DateTime.now().difference(time);

  if (diff.inSeconds < 60) return "Baru saja";
  if (diff.inMinutes < 60) return "${diff.inMinutes} menit lalu";
  if (diff.inHours < 24) return "${diff.inHours} jam lalu";

  return "${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}";
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
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(
      children: [
        // GARIS SAMPING
        Container(
          width: 4,
          height: 70,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),

        const SizedBox(width: 10),

        // TEXT
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

Widget _infoItem({
  required context,
  required String title,
  required String value,
  required String status,
}) {
  return Container(
    margin: const EdgeInsets.all(6),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        if (status.isNotEmpty)
          Text(
            status,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xff03AF55),
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    ),
  );
}

//
// ================= BASE CARD (BIAR KONSISTEN) =================
//
Widget _baseCard({
  required BuildContext context,
  required Widget child,
  double minHeight = 120,
}) {
  return Card(
    color: Theme.of(context).cardColor,
    elevation: 8,
    shadowColor: Theme.of(context).shadowColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
    child: Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight), // 🔥 KUNCI
      padding: const EdgeInsets.all(16),
      child: child,
    ),
  );
}
