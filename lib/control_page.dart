import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy/fuzzy_controller.dart';
import 'dummy_data.dart';
import 'dart:async';
import '../notification/notification_controller.dart';
import '../notification/notification_widget.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  bool pompa = true;
  bool aerator = true;
  bool kipas = false;
  bool lampu = true;

  bool autoPompa = true;
  bool autoKipas = true;
  bool autoAerator = true;

  double tdsValue = DummyData.tds;
  int suhuTarget = DummyData.suhu.toInt();
  int durasiAerator = 2;

  late Timer timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;

      setState(() {
        tdsValue = DummyData.tds;
        suhuTarget = DummyData.suhu.toInt();
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'KONTROL',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _warningCard(context),
            const SizedBox(height: 16),
            _switchCard(fuzzy),
            const SizedBox(height: 16),
            _pompaCard(fuzzy),
            const SizedBox(height: 16),
            _kipasCard(fuzzy),
            const SizedBox(height: 16),
            _aeratorCard(fuzzy),
          ],
        ),
      ),
    );
  }

  // ================= SWITCH CARD =================
  Widget _switchCard(FuzzyController fuzzy) {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _switchTile(
            'Pompa Nutrisi',
            pompa,
            (v) => setState(() => pompa = v),
            fuzzy.autoMode,
          ),
          const Divider(thickness: 1.2),
          _switchTile(
            'Aerator',
            aerator,
            (v) => setState(() => aerator = v),
            fuzzy.autoMode,
          ),
          const Divider(thickness: 1.2),
          _switchTile(
            'Kipas Ruangan',
            kipas,
            (v) => setState(() => kipas = v),
            fuzzy.autoMode,
          ),
          const Divider(thickness: 1.2),
          _switchTile(
            'Lampu',
            lampu,
            (v) => setState(() => lampu = v),
            fuzzy.autoMode,
          ),
        ],
      ),
    );
  }

  Widget _switchTile(
    String title,
    bool value,
    Function(bool) onChanged,
    bool disabled,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: disabled ? Colors.grey : Colors.black,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: disabled ? null : onChanged,
            thumbColor: WidgetStateProperty.all(Colors.white),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const Color(0xff03AF55);
              }
              return const Color(0xff767A78);
            }),
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
          ),
        ],
      ),
    );
  }

  // ================= POMPA =================
  Widget _pompaCard(FuzzyController fuzzy) {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _autoHeader(
              'Pompa Nutrisi (TDS)',
              autoPompa,
              (v) => setState(() => autoPompa = v),
              fuzzy.autoMode,
            ),
            Slider(
              value: tdsValue,
              min: 500,
              max: 1200,
              activeColor: const Color(0xff03AF55),
              onChanged: (autoPompa || fuzzy.autoMode)
                  ? null
                  : (v) => setState(() => tdsValue = v),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${tdsValue.toInt()} PPM'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= KIPAS =================
  Widget _kipasCard(FuzzyController fuzzy) {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _autoHeader(
              'Kipas Pendingin',
              autoKipas,
              (v) => setState(() => autoKipas = v),
              fuzzy.autoMode,
            ),
            const SizedBox(height: 10),
            TextField(
              enabled: !autoKipas && !fuzzy.autoMode,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              controller: TextEditingController(
                text: DummyData.suhu.toStringAsFixed(1),
              ),
              onChanged: (v) => suhuTarget = int.tryParse(v) ?? suhuTarget,
            ),
          ],
        ),
      ),
    );
  }

  // ================= AERATOR =================
  Widget _aeratorCard(FuzzyController fuzzy) {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _autoHeader(
              'Jadwal Aerator Harian',
              autoAerator,
              (v) => setState(() => autoAerator = v),
              fuzzy.autoMode,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: durasiAerator,
              items: [1, 2, 3, 4]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e jam')))
                  .toList(),
              onChanged: (!autoAerator && !fuzzy.autoMode)
                  ? (v) => setState(() => durasiAerator = v ?? durasiAerator)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ================= AUTO HEADER =================
  Widget _autoHeader(
    String title,
    bool value,
    Function(bool) onChanged,
    bool fuzzyAuto,
  ) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const Spacer(),
        GestureDetector(
          onTap: fuzzyAuto ? null : () => onChanged(!value),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: fuzzyAuto
                      ? Colors.grey.shade400
                      : (value ? const Color(0xff03AF55) : Colors.grey),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Auto',
                style: TextStyle(
                  fontSize: 12,
                  color: fuzzyAuto ? Colors.grey : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= WARNING =================
  Widget _warningCard(BuildContext context) {
    final notif = context.watch<NotificationController>();

    if (notif.notifications.isEmpty) {
      return const SizedBox();
    }

    final latest = notif.notifications.first;

    return NotificationCard(notif: latest);
  }
}
