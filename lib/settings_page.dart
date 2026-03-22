import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'fuzzy_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifikasi = true;
  bool modeGelap = false;
  int intervalFuzzy = 5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(),
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

  // ================= APP BAR =================
  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'PENGATURAN',
        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
      ),
    );
  }

  // ================= GENERAL =================
  Widget _generalCard() {
    return _baseCard(
      child: Column(
        children: [
          _tile('Bahasa', trailing: 'Indonesia'),
          const Divider(thickness: 1),
          _switchTile(
            'Notifikasi',
            notifikasi,
            (v) => setState(() => notifikasi = v),
          ),
          const Divider(thickness: 1),
          _switchTile(
            'Mode Gelap',
            modeGelap,
            (v) => setState(() => modeGelap = v),
          ),
        ],
      ),
    );
  }

  // ================= MODE SYSTEM =================
  Widget _modeSystemCard() {
    final fuzzy = context.watch<FuzzyController>();

    return _baseCard(
      child: _switchTile(
        'Mode Otomatis (Fuzzy)',
        fuzzy.autoMode,
        (v) => context.read<FuzzyController>().setAutoMode(v),
        subtitle: fuzzy.autoMode
            ? 'Dikontrol otomatis oleh fuzzy'
            : 'Dikontrol manual oleh pengguna',
      ),
    );
  }

  // ================= INTERVAL =================
  Widget _intervalFuzzyCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'EKSEKUSI FUZZY',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: intervalFuzzy,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xff03AF55)),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 5, child: Text('Setiap 5 menit')),
              DropdownMenuItem(value: 10, child: Text('Setiap 10 menit')),
              DropdownMenuItem(value: 30, child: Text('Setiap 30 menit')),
            ],
            onChanged: (v) => setState(() => intervalFuzzy = v!),
          ),
        ],
      ),
    );
  }

  // ================= SAFETY =================
  Widget _safetyLimitCard() {
    return _baseCard(
      child: Column(
        children: const [
          _ListItem('pH Minimum', '5.5'),
          Divider(thickness: 1),
          _ListItem('pH Maksimum', '7.5'),
          Divider(thickness: 1),
          _ListItem('TDS Maksimum', '1200 PPM'),
          SizedBox(height: 8),
          Text(
            'Jika melebihi batas, sistem masuk mode aman',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= TANAMAN =================
  Widget _plantSettingCard() {
    return _baseCard(
      child: Column(
        children: const [
          _ListItem('Jenis Tanaman', 'Selada Romaine'),
          Divider(thickness: 1),
          _ListItem('Umur Tanam', '25 HST'),
          Divider(thickness: 1),
          _ListItem('pH Ideal', '5.5 – 6.5'),
          Divider(thickness: 1),
          _ListItem('TDS Ideal', '700 – 900'),
        ],
      ),
    );
  }

  // ================= ABOUT =================
  Widget _aboutCard() {
    return _baseCard(
      child: const ListTile(
        leading: Icon(Icons.info, color: Color(0xff03AF55)),
        title: Text(
          'Tentang Aplikasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Monitoring & kontrol hidroponik berbasis Fuzzy Mamdani.',
        ),
      ),
    );
  }

  // ================= COMPONENT =================

  Widget _baseCard({required Widget child}) {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }

  Widget _tile(String title, {String? trailing}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: trailing != null ? Text(trailing) : null,
    );
  }

  Widget _switchTile(
    String title,
    bool value,
    Function(bool) onChanged, {
    String? subtitle,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
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
        if (subtitle != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}

// ================= REUSABLE ITEM =================
class _ListItem extends StatelessWidget {
  final String title;
  final String value;

  const _ListItem(this.title, this.value);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      trailing: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
