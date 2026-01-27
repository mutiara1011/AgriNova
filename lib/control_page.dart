import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy_controller.dart';

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  // ===== STATE LOKAL (MANUAL MODE) =====
  bool lampu = true;

  bool autoPompa = true;
  bool autoKipas = true;
  bool autoAerator = true;

  double tdsValue = 800;
  double suhuTarget = 32;
  int durasiAerator = 2;

  @override
  Widget build(BuildContext context) {
    final fuzzy = context.watch<FuzzyController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KONTROL',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _warningCard(),
            const SizedBox(height: 16),
            _switchControlCard(fuzzy),
            const SizedBox(height: 16),
            _pompaTdsCard(fuzzy),
            const SizedBox(height: 16),
            _kipasCard(fuzzy),
            const SizedBox(height: 16),
            _aeratorScheduleCard(fuzzy),
          ],
        ),
      ),
    );
  }

  // ================= SWITCH =================
  Widget _switchControlCard(FuzzyController fuzzy) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Pompa Nutrisi'),
            subtitle: Text(fuzzy.autoMode ? 'Dikontrol Fuzzy' : 'Manual'),
            value: fuzzy.autoMode ? fuzzy.pompaAktif : !autoPompa,
            onChanged: fuzzy.autoMode
                ? null
                : (v) {
                    setState(() => autoPompa = !v);
                  },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Kipas Ruangan'),
            subtitle: Text(fuzzy.autoMode ? 'Dikontrol Fuzzy' : 'Manual'),
            value: fuzzy.autoMode ? fuzzy.kipasAktif : !autoKipas,
            onChanged: fuzzy.autoMode
                ? null
                : (v) {
                    setState(() => autoKipas = !v);
                  },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Aerator'),
            subtitle: Text(fuzzy.autoMode ? 'Dikontrol Fuzzy' : 'Manual'),
            value: fuzzy.autoMode ? fuzzy.aeratorAktif : !autoAerator,
            onChanged: fuzzy.autoMode
                ? null
                : (v) {
                    setState(() => autoAerator = !v);
                  },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Lampu'),
            value: lampu,
            onChanged: (v) => setState(() => lampu = v),
          ),
        ],
      ),
    );
  }

  // ================= POMPA =================
  Widget _pompaTdsCard(FuzzyController fuzzy) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _autoHeader(
              'Pompa Nutrisi (TDS)',
              autoPompa,
              fuzzy.autoMode,
              (v) => setState(() => autoPompa = v),
            ),
            Slider(
              value: tdsValue,
              min: 500,
              max: 1200,
              divisions: 14,
              activeColor: Colors.green,
              onChanged: (!autoPompa && !fuzzy.autoMode)
                  ? (v) => setState(() => tdsValue = v)
                  : null,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _autoHeader(
              'Kipas Pendingin',
              autoKipas,
              fuzzy.autoMode,
              (v) => setState(() => autoKipas = v),
            ),
            Slider(
              value: suhuTarget,
              min: 20,
              max: 40,
              divisions: 20,
              activeColor: Colors.green,
              onChanged: (!autoKipas && !fuzzy.autoMode)
                  ? (v) => setState(() => suhuTarget = v)
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text('${suhuTarget.toInt()} °C'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= AERATOR =================
  Widget _aeratorScheduleCard(FuzzyController fuzzy) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _autoHeader(
              'Jadwal Aerator',
              autoAerator,
              fuzzy.autoMode,
              (v) => setState(() => autoAerator = v),
            ),
            DropdownButton<int>(
              value: durasiAerator,
              items: [1, 2, 3, 4]
                  .map((e) => DropdownMenuItem(value: e, child: Text('$e jam')))
                  .toList(),
              onChanged: (!autoAerator && !fuzzy.autoMode)
                  ? (v) => setState(() => durasiAerator = v!)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _autoHeader(
    String title,
    bool autoValue,
    bool fuzzyAuto,
    Function(bool) onChanged,
  ) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const Spacer(),
        const Text('Auto'),
        Switch(
          value: autoValue,
          onChanged: fuzzyAuto ? null : onChanged,
          activeThumbColor: Colors.green,
        ),
      ],
    );
  }

  Widget _warningCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning, color: Colors.white),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'PERINGATAN: Ketinggian air kritis!\nSegera isi tangki',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
