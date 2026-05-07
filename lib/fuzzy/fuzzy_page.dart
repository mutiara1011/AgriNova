import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy_controller.dart';
import 'fuzzy_history_page.dart';
import 'fuzzy_info_page.dart';
import 'package:agrinova/providers/sensor_provider.dart';
import 'package:agrinova/providers/plant_provider.dart';
import 'package:agrinova/models/fuzzy_thresholds.dart';

class FuzzyPage extends StatefulWidget {
  const FuzzyPage({super.key});

  @override
  State<FuzzyPage> createState() => _FuzzyPageState();
}

class _FuzzyPageState extends State<FuzzyPage> {
  Future<void> _onRefresh() async {
    try {
      final sensor = context.read<SensorProvider>();
      await sensor.fetchLatestData();
      if (mounted) {
        context.read<FuzzyController>().updateFromSensor();
      }
    } catch (e) {
      debugPrint("Error onRefresh FuzzyPage: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _appBar(context),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: const Color(0xff03AF55),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle("Tanaman Aktif"),
              const SizedBox(height: 12),
              const _ActivePlantInfoCard(),
              const SizedBox(height: 24),
              _sectionTitle("Overview Fuzzy"),
              const SizedBox(height: 12),
              const _FuzzyStatusCard(),
              const SizedBox(height: 24),
              _sectionTitle("Detail Kondisi"),
              const SizedBox(height: 12),
              const _ConditionCard(),
              const SizedBox(height: 24),
              _sectionTitle("Membership Function"),
              const SizedBox(height: 12),
              const _MembershipCard(),
              const SizedBox(height: 24),
              _sectionTitle("Inferensi Aturan"),
              const SizedBox(height: 12),
              const _RuleCard(),
              const SizedBox(height: 24),
              _sectionTitle("Log Aktivitas"),
              const SizedBox(height: 12),
              const _HistoryCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.grey.shade500, letterSpacing: 1),
      ),
    );
  }

  // ================= APP BAR =================
  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'ANALISIS FUZZY',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FuzzyInfoPage())),
          icon: const Icon(Icons.info_outline, color: Color(0xff03AF55)),
        ),
        const SizedBox(width: 8),
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

    return _PremiumCard(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.speed_rounded, color: Color(0xff03AF55), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('STATUS EVALUASI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Gauge(
                label: 'Pompa TDS',
                value: "${fuzzy.outputPompaTDS.toStringAsFixed(0)}%",
                status: fuzzy.outputPompaTDS > 50 ? "Aktif" : "Mati",
                color: Colors.teal,
              ),
              Container(width: 1, height: 40, color: Colors.grey.withValues(alpha: 0.2)),
              _Gauge(
                label: 'Pompa pH',
                value: "${fuzzy.outputPompaPH.toStringAsFixed(0)}%",
                status: fuzzy.outputPompaPH > 50 ? "Aktif" : "Mati",
                color: Colors.deepPurple,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivePlantInfoCard extends StatelessWidget {
  const _ActivePlantInfoCard();

  @override
  Widget build(BuildContext context) {
    final plantProvider = context.watch<PlantProvider>();
    final activePlant = plantProvider.activePlant;

    if (activePlant == null) {
      return _PremiumCard(
        child: const Center(
          child: Text(
            "Tidak ada tanaman aktif",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
      );
    }

    return _PremiumCard(
      child: Column(
        children: [
          _infoRow("Komoditas", plantProvider.selectedPlant, Icons.eco),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _infoRow("Fase Pertumbuhan", plantProvider.selectedPhase, Icons.timeline),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1),
          ),
          _infoRow("Umur Tanaman", "${activePlant.hst} HSPT", Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xff03AF55)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xff03AF55), fontSize: 13)),
      ],
    );
  }
}

class _Gauge extends StatelessWidget {
  final String label;
  final String value;
  final String status;
  final Color color;

  const _Gauge({required this.label, required this.value, required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
        Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900)),
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

    return _PremiumCard(
      padding: const EdgeInsets.all(24),
      color: const Color(0xff03AF55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('KONDISI AKTUAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("REKOMENDASI DOSIS", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(fuzzy.rekomendasi, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("OUTPUT", style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text("${fuzzy.outputPompa.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              Container(height: 6, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 6,
                width: MediaQuery.of(context).size.width * (fuzzy.outputPompa / 100).clamp(0.0, 1.0) * 0.7,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.white38, Colors.white]),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
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

  String getStatus(FuzzyController fuzzy) {
    if (fuzzy.muPhRendah > fuzzy.muPhNormal && fuzzy.muPhRendah > fuzzy.muPhTinggi) return "ASAM";
    if (fuzzy.muPhNormal > fuzzy.muPhTinggi) return "NORMAL";
    return "BASA";
  }

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();
    final ph = fuzzy.ph;
    final status = getStatus(fuzzy);

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('DERAJAT KEANGGOTAAN (PH)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: const Text('LIVE', style: TextStyle(color: Color(0xff03AF55), fontSize: 9, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            height: 100, 
            width: double.infinity, 
            child: CustomPaint(
              painter: _MembershipPainter(
                ph: ph,
                thresholds: context.watch<PlantProvider>().currentThresholds,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _muLabel('RENDAH', fuzzy.muPhRendah, Colors.red),
              _muLabel('NORMAL', fuzzy.muPhNormal, Colors.green),
              _muLabel('TINGGI', fuzzy.muPhTinggi, Colors.blue),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _infoTile("Status Dominan", status, const Color(0xff03AF55)),
              const SizedBox(width: 12),
              _infoTile("Nilai Input", "${ph.toStringAsFixed(1)} pH", Colors.grey.shade700),
            ],
          ),
        ],
      ),
    );
  }

  Widget _muLabel(String label, double val, Color color) {
    return Column(
      children: [
        Text(val.toStringAsFixed(2), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _infoTile(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }
}


class _RuleCard extends StatelessWidget {
  const _RuleCard();

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.rule_rounded, color: Color(0xff03AF55), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('INFERENSI RULE MAMDANI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          _ruleItem(
            context: context,
            label: 'R1',
            isActive: fuzzy.r1Active,
            content: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('IF pH', style: TextStyle(fontSize: 12)),
                _chip('NORMAL', Colors.green),
                const Text('AND TDS', style: TextStyle(fontSize: 12)),
                _chip('RENDAH', Colors.green),
                const Text('THEN POMPA TDS', style: TextStyle(fontSize: 12)),
                _chip('TINGGI', Colors.grey),
              ],
            ),
            fireValue: fuzzy.r1.toStringAsFixed(2),
          ),
          const SizedBox(height: 12),
          _ruleItem(
            context: context,
            label: 'R2',
            isActive: fuzzy.r2 > 0,
            content: const Text('IF pH ASAM AND TDS RENDAH THEN POMPA PH (UP) TINGGI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            fireValue: fuzzy.r2.toStringAsFixed(2),
          ),
          const SizedBox(height: 12),
          _ruleItem(
            context: context,
            label: 'R3',
            isActive: fuzzy.r3Active,
            content: const Text('IF pH BASA AND TDS TINGGI THEN POMPA PH (DOWN) TINGGI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            fireValue: fuzzy.r3.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem({required context, required String label, required bool isActive, required Widget content, String? fireValue}) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xff03AF55).withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: isActive ? Border.all(color: const Color(0xff03AF55).withValues(alpha: 0.2)) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: isActive ? const Color(0xff03AF55) : Colors.grey, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(child: content),
            if (fireValue != null && isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xff03AF55), borderRadius: BorderRadius.circular(6)),
                child: Text(fireValue, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900)),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard();

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();
    final logs = fuzzy.logRekomendasi.take(5).toList();

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LOG REKOMENDASI TERBARU', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FuzzyHistoryPage())),
                child: const Text('LIHAT SEMUA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xff03AF55))),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (logs.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Belum ada riwayat", style: TextStyle(color: Colors.grey))))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final log = logs[index];
                return _logItem(context, log);
              },
            ),
        ],
      ),
    );
  }

  Widget _logItem(BuildContext context, Map<String, dynamic> log) {
    final time = log["time"] as DateTime;
    final timeStr = "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), shape: BoxShape.circle),
            child: const Icon(Icons.history_toggle_off_rounded, size: 16, color: Color(0xff03AF55)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log["title"], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                Text(log["desc"], style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          Text(timeStr, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey.shade400)),
        ],
      ),
    );
  }
}

class _MembershipPainter extends CustomPainter {
  final double ph;
  final FuzzyThresholds thresholds;
  
  _MembershipPainter({required this.ph, required this.thresholds});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()..strokeWidth = 2..style = PaintingStyle.stroke;
    final paintFill = Paint()..style = PaintingStyle.fill;

    final phL = thresholds.phLimits;
    
    // Scale pH (assume 0-14 range for visualization)
    double toX(double val) => (val / 14) * size.width;

    // Drawing Shapes for Asam, Normal, Basa
    void drawShape(Color color, List<Offset> points) {
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(path, paintFill..color = color.withValues(alpha: 0.1));
      canvas.drawPath(path, paintLine..color = color.withValues(alpha: 0.3));
    }

    // pH Asam (Kurva Turun)
    drawShape(Colors.red, [
      Offset(toX(0), 0),
      Offset(toX(phL[0]), 0),
      Offset(toX(phL[1]), size.height),
      Offset(toX(0), size.height),
    ]);

    // pH Normal (Trapesium)
    drawShape(Colors.green, [
      Offset(toX(phL[0]), size.height),
      Offset(toX(phL[1]), 0),
      Offset(toX(phL[2]), 0),
      Offset(toX(phL[3]), size.height),
    ]);

    // pH Basa (Kurva Naik)
    drawShape(Colors.blue, [
      Offset(toX(phL[2]), size.height),
      Offset(toX(phL[3]), 0),
      Offset(toX(14), 0),
      Offset(toX(14), size.height),
    ]);

    // Indicator
    double x = (ph / 14).clamp(0.0, 1.0) * size.width;
    canvas.drawLine(Offset(x, 0), Offset(x, size.height), paintLine..color = Colors.black..strokeWidth = 1.5);
    canvas.drawCircle(Offset(x, size.height * 0.5), 4, paintFill..color = Colors.black);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _PremiumCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  const _PremiumCard({required this.child, this.color, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.5),
          width: 1.5,
        ),
      ),
      child: child,
    );
  }
}
