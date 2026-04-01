import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../fuzzy/fuzzy_controller.dart';
import 'settings_helper.dart';

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
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final interval = await SettingsHelper.getInterval();
    final notif = await SettingsHelper.getNotif();
    final modeStr = await SettingsHelper.getMode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final fuzzy = context.read<FuzzyController>();

      if (modeStr == 'auto') fuzzy.setMode(SystemMode.auto);
      if (modeStr == 'semi') fuzzy.setMode(SystemMode.semiAuto);
      if (modeStr == 'manual') fuzzy.setMode(SystemMode.manual);

      fuzzy.interval = interval;
      fuzzy.startTimer();

      setState(() {
        intervalFuzzy = interval;
        notifikasi = notif;
      });
    });
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.settings, color: Color(0xff03AF55)),
              SizedBox(width: 8),
              Text(
                'GENERAL',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _tile('Bahasa', trailing: 'Indonesia'),
          const Divider(),

          _switchTile('Notifikasi', notifikasi, (v) async {
            setState(() => notifikasi = v);
            await SettingsHelper.saveNotif(v); // 🔥 SIMPAN
          }),
          const Divider(),

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.psychology, color: Color(0xff03AF55)),
              SizedBox(width: 8),
              Text(
                'MODE SISTEM',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          DropdownButtonFormField<SystemMode>(
            initialValue: fuzzy.mode,
            items: const [
              DropdownMenuItem(
                value: SystemMode.auto,
                child: Text("Auto (Fuzzy)"),
              ),
              DropdownMenuItem(
                value: SystemMode.semiAuto,
                child: Text("Semi Auto"),
              ),
              DropdownMenuItem(value: SystemMode.manual, child: Text("Manual")),
            ],
            onChanged: (v) async {
              if (v != null) {
                context.read<FuzzyController>().setMode(v);

                String modeStr = 'auto';
                if (v == SystemMode.semiAuto) modeStr = 'semi';
                if (v == SystemMode.manual) modeStr = 'manual';

                await SettingsHelper.saveMode(modeStr); // 🔥 SIMPAN
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= INTERVAL =================
  Widget _intervalFuzzyCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.timer, color: Color(0xff03AF55)),
              SizedBox(width: 8),
              Text(
                'EKSEKUSI FUZZY',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),

          const Text(
            'Interval eksekusi sistem fuzzy',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<int>(
            initialValue: intervalFuzzy,
            items: const [
              DropdownMenuItem(value: 1, child: Text('Setiap 1 detik')),
              DropdownMenuItem(value: 5, child: Text('Setiap 5 detik')),
              DropdownMenuItem(value: 10, child: Text('Setiap 10 detik')),
            ],
            onChanged: (v) async {
              if (v != null) {
                setState(() => intervalFuzzy = v);

                final fuzzy = context.read<FuzzyController>();
                fuzzy.interval = v;
                fuzzy.startTimer();

                await SettingsHelper.saveInterval(v); // 🔥 SIMPAN
              }
            },
          ),
        ],
      ),
    );
  }

  // ================= SAFETY =================
  Widget _safetyLimitCard() {
    return _baseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.warning, color: Color(0xff03AF55)),
              SizedBox(width: 8),
              Text(
                'BATAS AMAN',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 12),

          _ListItem('pH Minimum', '5.5'),
          Divider(),
          _ListItem('pH Maksimum', '7.5'),
          Divider(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Row(
            children: [
              Icon(Icons.local_florist, color: Color(0xff03AF55)),
              SizedBox(width: 8),
              Text(
                'TANAMAN',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          SizedBox(height: 12),

          _ListItem('Jenis Tanaman', 'Selada Romaine'),
          Divider(),
          _ListItem('Umur Tanam', '25 HST'),
          Divider(),
          _ListItem('pH Ideal', '5.5 – 6.5'),
          Divider(),
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

  Widget _switchTile(String title, bool value, Function(bool) onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: const Color(0xff03AF55),
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
