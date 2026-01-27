import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Switch states
  bool notifikasi = true;
  bool modeGelap = false;
  bool modeFuzzy = true;

  // Fuzzy interval
  int intervalFuzzy = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PENGATURAN',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _generalCard(),
            const SizedBox(height: 16),
            _modeSystemCard(),
            const SizedBox(height: 16),
            _intervalFuzzyCard(),
            const SizedBox(height: 16),
            _safetyLimitCard(),
            const SizedBox(height: 16),
            _plantSettingCard(),
            const SizedBox(height: 16),
            _aboutCard(),
          ],
        ),
      ),
    );
  }

  // ================= UMUM =================
  Widget _generalCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          ListTile(
            title: const Text('Bahasa'),
            trailing: const Text('Indonesia'),
            onTap: () {},
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Notifikasi'),
            value: notifikasi,
            activeThumbColor: Colors.green,
            onChanged: (v) {
              setState(() => notifikasi = v);
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: const Text('Mode Gelap'),
            value: modeGelap,
            activeThumbColor: Colors.green,
            onChanged: (v) {
              setState(() => modeGelap = v);
            },
          ),
        ],
      ),
    );
  }

  // ================= MODE SISTEM =================
  Widget _modeSystemCard() {
    final fuzzy = context.watch<FuzzyController>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SwitchListTile(
        title: const Text(
          'Mode Otomatis (Fuzzy Mamdani)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          fuzzy.autoMode
              ? 'Sistem dikontrol otomatis oleh fuzzy'
              : 'Sistem dikontrol manual oleh pengguna',
        ),
        value: fuzzy.autoMode,
        activeThumbColor: Colors.green,
        onChanged: (v) {
          context.read<FuzzyController>().setAutoMode(v);
        },
      ),
    );
  }

  // ================= INTERVAL FUZZY =================
  Widget _intervalFuzzyCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EKSEKUSI FUZZY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButton<int>(
              value: intervalFuzzy,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 5, child: Text('Setiap 5 menit')),
                DropdownMenuItem(value: 10, child: Text('Setiap 10 menit')),
                DropdownMenuItem(value: 30, child: Text('Setiap 30 menit')),
              ],
              onChanged: (v) {
                setState(() => intervalFuzzy = v!);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ================= SAFETY LIMIT =================
  Widget _safetyLimitCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const [
          ListTile(title: Text('pH Minimum'), trailing: Text('5.5')),
          Divider(height: 1),
          ListTile(title: Text('pH Maksimum'), trailing: Text('7.5')),
          Divider(height: 1),
          ListTile(title: Text('TDS Maksimum'), trailing: Text('1200 PPM')),
          Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Jika nilai melebihi batas, sistem akan masuk mode aman.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TANAMAN =================
  Widget _plantSettingCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: const [
          ListTile(
            title: Text('Jenis Tanaman'),
            trailing: Text('Selada Romaine'),
          ),
          Divider(height: 1),
          ListTile(title: Text('Umur Tanam'), trailing: Text('25 HST')),
          Divider(height: 1),
          ListTile(title: Text('pH Ideal'), trailing: Text('5.5 – 6.5')),
          Divider(height: 1),
          ListTile(title: Text('TDS Ideal'), trailing: Text('700 – 900')),
        ],
      ),
    );
  }

  // ================= ABOUT =================
  Widget _aboutCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: const ListTile(
        title: Text('Tentang Aplikasi'),
        subtitle: Text(
          'Aplikasi Monitoring dan Kontrol Nutrisi Hidroponik '
          'menggunakan Pendekatan Fuzzy Mamdani.',
        ),
      ),
    );
  }
}
