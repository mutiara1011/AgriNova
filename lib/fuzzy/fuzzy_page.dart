import 'dart:async';
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
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 70,
            16,
            120,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const _ConditionCard(),
              const SizedBox(height: 24),
              _sectionTitle("TAHAP 1: FUZZIFIKASI (MEMBERSHIP FUNCTION)"),
              const SizedBox(height: 12),
              const _MembershipCard(),
              const SizedBox(height: 24),
              _sectionTitle("TAHAP 2: INFERENSI RULE MAMDANI"),
              const SizedBox(height: 12),
              const _RuleCard(),
              const SizedBox(height: 24),
              _sectionTitle("TAHAP 3: KESIMPULAN REKOMENDASI (DEFUZZIFIKASI)"),
              const SizedBox(height: 12),
              const _FuzzyStatusCard(),
              const SizedBox(height: 24),
              _sectionTitle("LOG AKTIVITAS EVALUASI"),
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
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey.shade500,
          letterSpacing: 1,
        ),
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
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FuzzyInfoPage()),
          ),
          icon: const Icon(Icons.info_outline, color: Color(0xff03AF55)),
        ),
        const SizedBox(width: 4),
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
                decoration: BoxDecoration(
                  color: const Color(0xff03AF55).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: Color(0xff03AF55),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'REKOMENDASI AKTATOR (DURASI NYALA)',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Gauge(
                label: 'Pompa AB Mix',
                durationValue: fuzzy.recommendedPompaTDSSeconds,
                status: fuzzy.recommendedPompaTDSSeconds > 0.5
                    ? "Aktif"
                    : "Mati",
                color: Colors.teal,
                isFuzzyEnabled: fuzzy.isFuzzyEnabled,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              _Gauge(
                label: 'Pompa pH Down',
                durationValue: fuzzy.recommendedPompaPHSeconds,
                status: fuzzy.recommendedPompaPHSeconds > 0.5
                    ? "Aktif"
                    : "Mati",
                color: Colors.deepPurple,
                isFuzzyEnabled: fuzzy.isFuzzyEnabled,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatefulWidget {
  final String label;
  final double durationValue;
  final String status;
  final Color color;
  final bool isFuzzyEnabled;

  const _Gauge({
    required this.label,
    required this.durationValue,
    required this.status,
    required this.color,
    required this.isFuzzyEnabled,
  });

  @override
  State<_Gauge> createState() => _GaugeState();
}

class _GaugeState extends State<_Gauge> {
  Timer? _timer;
  double? _countdownSeconds;
  bool _isSuccess = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    if (widget.durationValue <= 0.5) return;
    _timer?.cancel();
    setState(() {
      _countdownSeconds = widget.durationValue;
      _isSuccess = false;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_countdownSeconds == null) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_countdownSeconds! <= 0.1) {
          _countdownSeconds = null;
          _isSuccess = true;
          timer.cancel();
          // Hide success state after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _isSuccess = false;
              });
            }
          });
        } else {
          _countdownSeconds = _countdownSeconds! - 0.1;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool canTriggerManual = !widget.isFuzzyEnabled && widget.durationValue > 0.5;

    return Column(
      children: [
        Text(
          _countdownSeconds != null 
              ? "${_countdownSeconds!.toStringAsFixed(1)} s" 
              : "${widget.durationValue.toStringAsFixed(1)} s",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
        const SizedBox(height: 10),
        if (_countdownSeconds != null) ...[
          // Animated Pulse Dosing State
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: widget.color.withValues(alpha: 0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(widget.color),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "DOSING...",
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ] else if (_isSuccess) ...[
          // Beautiful Dosing Success State
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff03AF55).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xff03AF55).withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xff03AF55), size: 12),
                SizedBox(width: 4),
                Text(
                  "SELESAI",
                  style: TextStyle(
                    color: Color(0xff03AF55),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ] else if (canTriggerManual) ...[
          // Trigger Manual Button (When Fuzzy automation is OFF and duration is active)
          ElevatedButton(
            onPressed: _startCountdown,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.play_arrow_rounded, size: 12),
                SizedBox(width: 2),
                Text(
                  "DOSIS MANUAL",
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.3),
                ),
              ],
            ),
          ),
        ] else ...[
          // Standard Auto State (When Fuzzy automation is ON)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.status.toUpperCase(),
              style: TextStyle(
                color: widget.color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

//
// ================= KONDISI =================
//
class _ConditionCard extends StatelessWidget {
  const _ConditionCard();

  Widget _plantRow(IconData icon, String label, String val) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.85)),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.75),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();
    final plantProvider = context.watch<PlantProvider>();
    final activePlant = plantProvider.activePlant;

    return _PremiumCard(
      padding: const EdgeInsets.all(20),
      color: const Color(0xff03AF55),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Utama
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'KONDISI RIIL & DATA TANAMAN',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Nested Translucent Plant Info Card (Jika ada Tanaman Aktif)
          if (activePlant != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.0,
                ),
              ),
              child: Column(
                children: [
                  _plantRow(
                    Icons.eco,
                    "KOMODITAS",
                    plantProvider.selectedPlant,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Colors.white12, height: 1),
                  ),
                  _plantRow(
                    Icons.timeline,
                    "FASE PERTUMBUHAN",
                    plantProvider.selectedPhase,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: Colors.white12, height: 1),
                  ),
                  _plantRow(
                    Icons.calendar_today,
                    "UMUR",
                    "${activePlant.hst} HSPT",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Rekomendasi & Output
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "REKOMENDASI AKTATOR",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fuzzy.rekomendasi,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "SKALA OUTPUT",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${fuzzy.outputPompa.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar Output Pompa
          Stack(
            children: [
              Container(
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                height: 5,
                width:
                    MediaQuery.of(context).size.width *
                    (fuzzy.outputPompa / 100).clamp(0.0, 1.0) *
                    0.75,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.white38, Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Colors.white24, height: 1),
          ),

          // Detail Fisika Dosis
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dosingDetail("Ukuran Bak", "1.0 x 1.0 m"),
              _dosingDetail(
                "Tinggi Air",
                "${fuzzy.ketinggianAir.toStringAsFixed(1)} cm",
              ),
              _dosingDetail(
                "Vol Air",
                "${fuzzy.volumeAir.toStringAsFixed(1)} L",
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dosingDetail(
                "Dosis AB Mix",
                "${fuzzy.abMixNeededML.toStringAsFixed(1)} mL",
              ),
              _dosingDetail(
                "Dosis pH Down",
                "${fuzzy.phDownNeededML.toStringAsFixed(1)} mL",
              ),
              _dosingDetail("Laju Alir", "3.3 mL/s"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dosingDetail(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          val,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

//
// ================= MEMBERSHIP =================
//
class _MembershipCard extends StatefulWidget {
  const _MembershipCard();

  @override
  State<_MembershipCard> createState() => _MembershipCardState();
}

class _MembershipCardState extends State<_MembershipCard> {
  int _selectedTab = 0; // 0: pH, 1: TDS, 2: Suhu

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();
    final thresholds = context.watch<PlantProvider>().currentThresholds;

    String typeLabel = "PH";
    double inputValue = fuzzy.ph;
    String statusDominan = "NORMAL";
    String inputSuffix = "pH";
    String typeKey = 'ph';

    if (_selectedTab == 0) {
      typeLabel = "PH";
      inputValue = fuzzy.ph;
      statusDominan = fuzzy.membershipStatusPh.toUpperCase();
      inputSuffix = "pH";
      typeKey = 'ph';
    } else if (_selectedTab == 1) {
      typeLabel = "TDS";
      inputValue = fuzzy.tds;
      statusDominan = fuzzy.membershipStatusTds.toUpperCase();
      inputSuffix = "PPM";
      typeKey = 'tds';
    } else {
      typeLabel = "SUHU AIR";
      inputValue = fuzzy.waterTemp;
      if (fuzzy.muSuhuDingin > fuzzy.muSuhuNormal &&
          fuzzy.muSuhuDingin > fuzzy.muSuhuPanas) {
        statusDominan = "DINGIN";
      } else if (fuzzy.muSuhuNormal > fuzzy.muSuhuPanas) {
        statusDominan = "OPTIMAL";
      } else {
        statusDominan = "PANAS";
      }
      inputSuffix = "°C";
      typeKey = 'suhu';
    }

    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DERAJAT KEANGGOTAAN ($typeLabel)',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xff03AF55).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Color(0xff03AF55),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _tabButton(0, "pH"),
              const SizedBox(width: 8),
              _tabButton(1, "TDS"),
              const SizedBox(width: 8),
              _tabButton(2, "Suhu Air"),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 100,
            width: double.infinity,
            child: CustomPaint(
              painter: _MembershipPainter(
                type: typeKey,
                value: inputValue,
                thresholds: thresholds,
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_selectedTab == 0)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _muLabel('RENDAH', fuzzy.muPhRendah, Colors.red),
                _muLabel('NORMAL', fuzzy.muPhNormal, Colors.green),
                _muLabel('TINGGI', fuzzy.muPhTinggi, Colors.blue),
              ],
            )
          else if (_selectedTab == 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _muLabel('RENDAH', fuzzy.muTdsRendah, Colors.red),
                _muLabel('NORMAL', fuzzy.muTdsNormal, Colors.green),
                _muLabel('TINGGI', fuzzy.muTdsTinggi, Colors.blue),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _muLabel('DINGIN', fuzzy.muSuhuDingin, Colors.blue),
                _muLabel('OPTIMAL', fuzzy.muSuhuNormal, Colors.green),
                _muLabel('PANAS', fuzzy.muSuhuPanas, Colors.red),
              ],
            ),
          const SizedBox(height: 24),
          Row(
            children: [
              _infoTile(
                "Status Dominan",
                statusDominan,
                const Color(0xff03AF55),
              ),
              const SizedBox(width: 12),
              _infoTile(
                "Nilai Input",
                "${inputValue.toStringAsFixed(1)} $inputSuffix",
                Colors.grey.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tabButton(int index, String label) {
    bool active = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xff03AF55)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade700,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _muLabel(String label, double val, Color color) {
    return Column(
      children: [
        Text(
          val.toStringAsFixed(2),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              val,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
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
                decoration: BoxDecoration(
                  color: const Color(0xff03AF55).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.rule_rounded,
                  color: Color(0xff03AF55),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'INFERENSI RULE MAMDANI',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'FUZZY SYSTEM 1: NUTRISI (AB MIX)',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _ruleItem(
            context: context,
            label: 'R1',
            isActive: fuzzy.r1 > 0,
            content: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('IF TDS', style: TextStyle(fontSize: 11)),
                _chip('RENDAH', Colors.red),
                const Text('AND Suhu', style: TextStyle(fontSize: 11)),
                _chip('DINGIN', Colors.blue),
                const Text('THEN AB Mix', style: TextStyle(fontSize: 11)),
                _chip('SEDANG (0.6)', Colors.orange),
              ],
            ),
            fireValue: fuzzy.r1.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
          _ruleItem(
            context: context,
            label: 'R2',
            isActive: fuzzy.r2 > 0,
            content: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('IF TDS', style: TextStyle(fontSize: 11)),
                _chip('RENDAH', Colors.red),
                const Text('AND Suhu', style: TextStyle(fontSize: 11)),
                _chip('OPTIMAL', Colors.green),
                const Text('THEN AB Mix', style: TextStyle(fontSize: 11)),
                _chip('TINGGI (1.0)', Colors.green),
              ],
            ),
            fireValue: fuzzy.r2.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
          _ruleItem(
            context: context,
            label: 'R3',
            isActive: fuzzy.r3 > 0,
            content: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('IF TDS', style: TextStyle(fontSize: 11)),
                _chip('RENDAH', Colors.red),
                const Text('AND Suhu', style: TextStyle(fontSize: 11)),
                _chip('PANAS', Colors.orange),
                const Text('THEN AB Mix', style: TextStyle(fontSize: 11)),
                _chip('RENDAH (0.3)', Colors.teal),
              ],
            ),
            fireValue: fuzzy.r3.toStringAsFixed(2),
          ),
          const SizedBox(height: 20),
          const Text(
            'FUZZY SYSTEM 2: TINGKAT ASAM (pH DOWN)',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _ruleItem(
            context: context,
            label: 'R6',
            isActive: fuzzy.r6 > 0,
            content: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('IF pH', style: TextStyle(fontSize: 11)),
                _chip('TINGGI', Colors.red),
                const Text('AND Suhu', style: TextStyle(fontSize: 11)),
                _chip('DINGIN', Colors.blue),
                const Text('THEN pH Down', style: TextStyle(fontSize: 11)),
                _chip('SEDANG (0.6)', Colors.orange),
              ],
            ),
            fireValue: fuzzy.r6.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
          _ruleItem(
            context: context,
            label: 'R7',
            isActive: fuzzy.r7 > 0,
            content: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('IF pH', style: TextStyle(fontSize: 11)),
                _chip('TINGGI', Colors.red),
                const Text('AND Suhu', style: TextStyle(fontSize: 11)),
                _chip('OPTIMAL', Colors.green),
                const Text('THEN pH Down', style: TextStyle(fontSize: 11)),
                _chip('TINGGI (1.0)', Colors.green),
              ],
            ),
            fireValue: fuzzy.r7.toStringAsFixed(2),
          ),
          const SizedBox(height: 8),
          _ruleItem(
            context: context,
            label: 'R8',
            isActive: fuzzy.r8 > 0,
            content: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Text('IF pH', style: TextStyle(fontSize: 11)),
                _chip('TINGGI', Colors.red),
                const Text('AND Suhu', style: TextStyle(fontSize: 11)),
                _chip('PANAS', Colors.orange),
                const Text('THEN pH Down', style: TextStyle(fontSize: 11)),
                _chip('RENDAH (0.4)', Colors.teal),
              ],
            ),
            fireValue: fuzzy.r8.toStringAsFixed(2),
          ),
        ],
      ),
    );
  }

  Widget _ruleItem({
    required context,
    required String label,
    required bool isActive,
    required Widget content,
    String? fireValue,
  }) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isActive ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xff03AF55).withValues(alpha: 0.05)
              : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: isActive
              ? Border.all(
                  color: const Color(0xff03AF55).withValues(alpha: 0.2),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isActive ? const Color(0xff03AF55) : Colors.grey,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: content),
            if (fireValue != null && isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xff03AF55),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  fireValue,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w900,
        ),
      ),
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
              const Text(
                'LOG REKOMENDASI TERBARU',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FuzzyHistoryPage()),
                ),
                child: const Text(
                  'LIHAT SEMUA',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xff03AF55),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (logs.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  "Belum ada riwayat",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
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
    final timeStr =
        "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xff03AF55).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_toggle_off_rounded,
              size: 16,
              color: Color(0xff03AF55),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log["title"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                Text(
                  log["desc"],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeStr,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================================
// WIDGET VISUALISASI GRAFIK FUNGSI KEANGGOTAAN FUZZY (MEMBERSHIP FUNCTION)
// =========================================================================
// Catatan Akademis untuk Skripsi:
// Grafik ini menggambarkan fungsi keanggotaan (Membership Function) fuzzy.
// - Sumbu Mendatar (Sumbu X) mewakili Nilai Riil Sensor di lapangan (pH, TDS, Suhu).
// - Sumbu Tegak (Sumbu Y) mewakili Derajat Keanggotaan (µ) mulai dari 0.0 (0%) hingga 1.0 (100%).
// - Area Tumpang Tindih (Overlapping) melambangkan masa transisi alami di mana dua kondisi aktif bersamaan.
class _MembershipPainter extends CustomPainter {
  final String type; // 'ph', 'tds', 'suhu'
  final double value;
  final FuzzyThresholds thresholds;

  _MembershipPainter({
    required this.type,
    required this.value,
    required this.thresholds,
  });

  void _drawText(
    Canvas canvas,
    String text,
    Offset offset, {
    Color color = Colors.grey,
    double fontSize = 8,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
          fontFamily: 'sans-serif',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, offset);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final paintFill = Paint()..style = PaintingStyle.fill;
    final axisPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Batas area gambar grafik dengan ruang kosong untuk label sumbu (Padding)
    const double paddingLeft = 36.0;
    const double paddingBottom = 20.0;
    const double paddingTop = 10.0;
    const double paddingRight = 10.0;

    final double chartWidth = size.width - paddingLeft - paddingRight;
    final double chartHeight = size.height - paddingBottom - paddingTop;

    // Fungsi helper pemetaan koordinat matematika ke koordinat piksel Canvas
    double toY(double muVal) {
      // muVal 1.0 berada di atas (paddingTop), muVal 0.0 berada di bawah (paddingTop + chartHeight)
      return paddingTop + chartHeight - (muVal * chartHeight);
    }

    // Gambar Sumbu Koordinat Y & X
    canvas.drawLine(
      const Offset(paddingLeft, paddingTop),
      Offset(paddingLeft, paddingTop + chartHeight),
      axisPaint,
    ); // Sumbu Y
    canvas.drawLine(
      Offset(paddingLeft, paddingTop + chartHeight),
      Offset(paddingLeft + chartWidth, paddingTop + chartHeight),
      axisPaint,
    ); // Sumbu X

    // Label Derajat Keanggotaan pada Sumbu Y
    _drawText(
      canvas,
      "1.0 (100%)",
      const Offset(2, paddingTop - 4),
      fontWeight: FontWeight.bold,
      color: Colors.grey.shade700,
    );
    _drawText(
      canvas,
      "0.5 (50%)",
      Offset(2, toY(0.5) - 4),
      color: Colors.grey.shade500,
    );
    _drawText(
      canvas,
      "0.0 (0%)",
      Offset(2, toY(0.0) - 4),
      color: Colors.grey.shade500,
    );

    // Garis putus-putus pembatas derajat 0.5 & 1.0
    final dashedPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(paddingLeft, toY(0.5)),
      Offset(paddingLeft + chartWidth, toY(0.5)),
      dashedPaint,
    );
    canvas.drawLine(
      Offset(paddingLeft, toY(1.0)),
      Offset(paddingLeft + chartWidth, toY(1.0)),
      dashedPaint,
    );

    if (type == 'ph') {
      final phL = thresholds.phLimits;
      double toX(double val) => paddingLeft + (val / 14.0) * chartWidth;

      void drawShape(
        Color color,
        List<Offset> points,
        String label,
        Offset labelPos,
      ) {
        final path = Path()..addPolygon(points, true);
        canvas.drawPath(path, paintFill..color = color.withValues(alpha: 0.08));
        canvas.drawPath(path, paintLine..color = color.withValues(alpha: 0.25));
        _drawText(
          canvas,
          label,
          labelPos,
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        );
      }

      // pH Asam (Kurva Turun)
      drawShape(
        Colors.red,
        [
          Offset(toX(0), toY(1)),
          Offset(toX(phL[0]), toY(1)),
          Offset(toX(phL[1]), toY(0)),
          Offset(toX(0), toY(0)),
        ],
        "Asam",
        Offset(toX(1.0), toY(0.7)),
      );

      // pH Normal (Trapesium)
      drawShape(
        Colors.green,
        [
          Offset(toX(phL[0]), toY(0)),
          Offset(toX(phL[1]), toY(1)),
          Offset(toX(phL[2]), toY(1)),
          Offset(toX(phL[3]), toY(0)),
        ],
        "Normal",
        Offset(toX((phL[1] + phL[2]) / 2) - 15, toY(0.7)),
      );

      // pH Basa (Kurva Naik)
      drawShape(
        Colors.blue,
        [
          Offset(toX(phL[2]), toY(0)),
          Offset(toX(phL[3]), toY(1)),
          Offset(toX(14), toY(1)),
          Offset(toX(14), toY(0)),
        ],
        "Basa",
        Offset(toX(12.0), toY(0.7)),
      );

      // Label Nilai Sumbu X (pH)
      _drawText(canvas, "0.0", Offset(toX(0) - 5, toY(0) + 4));
      _drawText(
        canvas,
        phL[0].toStringAsFixed(1),
        Offset(toX(phL[0]) - 8, toY(0) + 4),
      );
      _drawText(
        canvas,
        phL[1].toStringAsFixed(1),
        Offset(toX(phL[1]) - 8, toY(0) + 4),
      );
      _drawText(
        canvas,
        phL[2].toStringAsFixed(1),
        Offset(toX(phL[2]) - 8, toY(0) + 4),
      );
      _drawText(
        canvas,
        phL[3].toStringAsFixed(1),
        Offset(toX(phL[3]) - 8, toY(0) + 4),
      );
      _drawText(canvas, "14.0", Offset(toX(14) - 10, toY(0) + 4));
      _drawText(
        canvas,
        "Sumbu X: Nilai pH Aktual",
        Offset(paddingLeft + chartWidth / 2 - 40, toY(0) + 14),
        color: Colors.grey.shade600,
        fontWeight: FontWeight.bold,
      );

      // Garis Indikator Nilai Aktual Sensor saat ini
      double x = toX(value.clamp(0.0, 14.0));
      canvas.drawLine(
        Offset(x, paddingTop),
        Offset(x, toY(0)),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(x, toY(0.5)),
        4,
        paintFill..color = Colors.black,
      );
      _drawText(
        canvas,
        "Aktual: ${value.toStringAsFixed(1)}",
        Offset(x + 4, toY(0.85)),
        color: Colors.black,
        fontWeight: FontWeight.bold,
      );
    } else if (type == 'tds') {
      final tdsL = thresholds.tdsLimits;
      double toX(double val) => paddingLeft + (val / 1500.0) * chartWidth;

      void drawShape(
        Color color,
        List<Offset> points,
        String label,
        Offset labelPos,
      ) {
        final path = Path()..addPolygon(points, true);
        canvas.drawPath(path, paintFill..color = color.withValues(alpha: 0.08));
        canvas.drawPath(path, paintLine..color = color.withValues(alpha: 0.25));
        _drawText(
          canvas,
          label,
          labelPos,
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        );
      }

      // TDS Rendah
      drawShape(
        Colors.red,
        [
          Offset(toX(0), toY(1)),
          Offset(toX(tdsL[0]), toY(1)),
          Offset(toX(tdsL[1]), toY(0)),
          Offset(toX(0), toY(0)),
        ],
        "Rendah",
        Offset(toX(200), toY(0.7)),
      );

      // TDS Normal
      double mid = (tdsL[0] + tdsL[1]) / 2;
      drawShape(
        Colors.green,
        [
          Offset(toX(tdsL[0]), toY(0)),
          Offset(toX(mid), toY(1)),
          Offset(toX(tdsL[1]), toY(0)),
        ],
        "Normal",
        Offset(toX(mid) - 15, toY(0.7)),
      );

      // TDS Tinggi
      drawShape(
        Colors.blue,
        [
          Offset(toX(mid), toY(0)),
          Offset(toX(tdsL[1]), toY(1)),
          Offset(toX(1500), toY(1)),
          Offset(toX(1500), toY(0)),
        ],
        "Tinggi",
        Offset(toX(1200), toY(0.7)),
      );

      // Label Nilai Sumbu X (TDS PPM)
      _drawText(canvas, "0", Offset(toX(0) - 3, toY(0) + 4));
      _drawText(
        canvas,
        tdsL[0].toStringAsFixed(0),
        Offset(toX(tdsL[0]) - 10, toY(0) + 4),
      );
      _drawText(
        canvas,
        mid.toStringAsFixed(0),
        Offset(toX(mid) - 10, toY(0) + 4),
      );
      _drawText(
        canvas,
        tdsL[1].toStringAsFixed(0),
        Offset(toX(tdsL[1]) - 10, toY(0) + 4),
      );
      _drawText(canvas, "1500", Offset(toX(1500) - 20, toY(0) + 4));
      _drawText(
        canvas,
        "Sumbu X: Nilai TDS (PPM)",
        Offset(paddingLeft + chartWidth / 2 - 45, toY(0) + 14),
        color: Colors.grey.shade600,
        fontWeight: FontWeight.bold,
      );

      // Garis Indikator Nilai Aktual Sensor saat ini
      double x = toX(value.clamp(0.0, 1500.0));
      canvas.drawLine(
        Offset(x, paddingTop),
        Offset(x, toY(0)),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(x, toY(0.5)),
        4,
        paintFill..color = Colors.black,
      );
      _drawText(
        canvas,
        "${value.toStringAsFixed(0)} PPM",
        Offset(x + 4, toY(0.85)),
        color: Colors.black,
        fontWeight: FontWeight.bold,
      );
    } else {
      // Suhu: range 15 s.d 35
      double toX(double val) =>
          paddingLeft + ((val - 15) / 20.0).clamp(0.0, 1.0) * chartWidth;

      void drawShape(
        Color color,
        List<Offset> points,
        String label,
        Offset labelPos,
      ) {
        final path = Path()..addPolygon(points, true);
        canvas.drawPath(path, paintFill..color = color.withValues(alpha: 0.08));
        canvas.drawPath(path, paintLine..color = color.withValues(alpha: 0.25));
        _drawText(
          canvas,
          label,
          labelPos,
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        );
      }

      // Dingin
      drawShape(
        Colors.blue,
        [
          Offset(toX(15), toY(1)),
          Offset(toX(24), toY(1)),
          Offset(toX(27), toY(0)),
          Offset(toX(15), toY(0)),
        ],
        "Dingin",
        Offset(toX(18), toY(0.7)),
      );

      // Normal
      drawShape(
        Colors.green,
        [
          Offset(toX(24), toY(0)),
          Offset(toX(27), toY(1)),
          Offset(toX(31), toY(1)),
          Offset(toX(33), toY(0)),
        ],
        "Normal",
        Offset(toX(29) - 15, toY(0.7)),
      );

      // Panas
      drawShape(
        Colors.red,
        [
          Offset(toX(31), toY(0)),
          Offset(toX(33), toY(1)),
          Offset(toX(35), toY(1)),
          Offset(toX(35), toY(0)),
        ],
        "Panas",
        Offset(toX(34) - 10, toY(0.7)),
      );

      // Label Nilai Sumbu X (Suhu °C)
      _drawText(canvas, "15°C", Offset(toX(15) - 5, toY(0) + 4));
      _drawText(canvas, "24°C", Offset(toX(24) - 8, toY(0) + 4));
      _drawText(canvas, "27°C", Offset(toX(27) - 8, toY(0) + 4));
      _drawText(canvas, "31°C", Offset(toX(31) - 8, toY(0) + 4));
      _drawText(canvas, "33°C", Offset(toX(33) - 8, toY(0) + 4));
      _drawText(canvas, "35°C", Offset(toX(35) - 12, toY(0) + 4));
      _drawText(
        canvas,
        "Sumbu X: Suhu Air (°C)",
        Offset(paddingLeft + chartWidth / 2 - 40, toY(0) + 14),
        color: Colors.grey.shade600,
        fontWeight: FontWeight.bold,
      );

      // Garis Indikator Nilai Aktual Sensor saat ini
      double x = toX(value.clamp(15.0, 35.0));
      canvas.drawLine(
        Offset(x, paddingTop),
        Offset(x, toY(0)),
        Paint()
          ..color = Colors.black
          ..strokeWidth = 1.5,
      );
      canvas.drawCircle(
        Offset(x, toY(0.5)),
        4,
        paintFill..color = Colors.black,
      );
      _drawText(
        canvas,
        "${value.toStringAsFixed(1)}°C",
        Offset(x + 4, toY(0.85)),
        color: Colors.black,
        fontWeight: FontWeight.bold,
      );
    }
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
