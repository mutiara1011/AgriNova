import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../fuzzy/fuzzy_controller.dart';
import 'settings_helper.dart';
import 'about_page.dart';
import 'package:agrinova/notification/notification_controller.dart';
import 'package:agrinova/dummy_data.dart';
import 'theme_controller.dart';

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
      final notifController = context.read<NotificationController>();

      notifController.isEnabled = notif;

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: true,
      title: Text(
        'PENGATURAN',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyMedium!.color,
        ),
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

            final notifController = context.read<NotificationController>();
            notifController.isEnabled = v;

            await SettingsHelper.saveNotif(v);
          }),
          const Divider(),

          _switchTile('Mode Gelap', context.watch<ThemeController>().isDark, (
            v,
          ) {
            context.read<ThemeController>().toggleTheme(v);
          }),
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
        children: [
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
          _ListItem('Umur Tanam', '${DummyData.hst} HST'),
          Divider(),
          _ListItem('pH Ideal', '5.5 – 6.5'),
          Divider(),
          _ListItem('TDS Ideal', '700 – 900'),
          ListTile(
            title: const Text("Tanggal Tanam"),
            subtitle: Text(
              "${DummyData.startDate.day}/${DummyData.startDate.month}/${DummyData.startDate.year}",
            ),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DummyData.startDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );

              if (picked != null) {
                setState(() {
                  DummyData.startDate = picked;
                });
              }
            },
          ),
          const Divider(),
        ],
      ),
    );
  }

  // ================= ABOUT =================
  Widget _aboutCard() {
    return _baseCard(
      child: ListTile(
        leading: const Icon(Icons.info, color: Color(0xff03AF55)),
        title: const Text(
          'Tentang Aplikasi',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Informasi lengkap tentang aplikasi'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutPage()),
          );
        },
      ),
    );
  }

  // ================= COMPONENT =================
  Widget _baseCard({required Widget child}) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: 8,
      shadowColor: Theme.of(context).shadowColor,
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
