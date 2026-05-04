import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../fuzzy/fuzzy_controller.dart';
import 'settings_helper.dart';
import 'about_page.dart';
import 'package:agrinova/notification/notification_controller.dart';
import 'theme_controller.dart';
import '../providers/plant_provider.dart';
import '../providers/sensor_provider.dart';
import '../onboarding/plant_selection_page.dart';
import '../history/cycle_history_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notifikasi = true;
  bool modeGelap = false;
  int intervalFuzzy = 5;
  DateTime startDate = DateTime.now().subtract(const Duration(days: 13));
  int get hst => DateTime.now().difference(startDate).inDays + 1;

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
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _appBar(),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle("Preferensi Utama"),
            const SizedBox(height: 12),
            _generalCard(),
            const SizedBox(height: 24),
            _sectionTitle("Konfigurasi Sistem"),
            const SizedBox(height: 12),
            _modeSystemCard(),
            const SizedBox(height: 16),
            _intervalFuzzyCard(),
            const SizedBox(height: 24),
            _sectionTitle("Standardisasi & Keamanan"),
            const SizedBox(height: 12),
            _safetyLimitCard(),
            const SizedBox(height: 24),
            _sectionTitle("Informasi Budidaya"),
            const SizedBox(height: 12),
            _plantSettingCard(),
            const SizedBox(height: 24),
            _aboutCard(),
          ],
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
  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      title: const Text(
        'PENGATURAN',
        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 0.5),
      ),
    );
  }

  // ================= GENERAL =================
  Widget _generalCard() {
    return _PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _tile('Bahasa Aplikasi', trailing: 'Indonesia', icon: Icons.language),
          const Divider(indent: 50, endIndent: 20),
          _switchTile('Notifikasi Real-time', notifikasi, (v) async {
            setState(() => notifikasi = v);
            final notifController = context.read<NotificationController>();
            notifController.isEnabled = v;
            await SettingsHelper.saveNotif(v);
          }, Icons.notifications_active_outlined),
          const Divider(indent: 50, endIndent: 20),
          _switchTile('Mode Gelap / Dark', context.watch<ThemeController>().isDark, (v) {
            context.read<ThemeController>().toggleTheme(v);
          }, Icons.dark_mode_outlined),
        ],
      ),
    );
  }

  // ================= MODE SYSTEM =================
  Widget _modeSystemCard() {
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
                child: const Icon(Icons.psychology_rounded, color: Color(0xff03AF55), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('MODE OPERASI', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<SystemMode>(
                value: fuzzy.mode,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: SystemMode.auto, child: Text("Otomatis (Logika Fuzzy)", style: TextStyle(fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: SystemMode.semiAuto, child: Text("Semi Otomatis", style: TextStyle(fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: SystemMode.manual, child: Text("Manual (Kendali User)", style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                onChanged: (v) async {
                  if (v != null) {
                    context.read<FuzzyController>().setMode(v);
                    String modeStr = v == SystemMode.semiAuto ? 'semi' : (v == SystemMode.manual ? 'manual' : 'auto');
                    await SettingsHelper.saveMode(modeStr);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= INTERVAL =================
  Widget _intervalFuzzyCard() {
    return _PremiumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.timer_rounded, color: Color(0xff03AF55), size: 20),
              ),
              const SizedBox(width: 12),
              const Text('INTERVAL PEMROSESAN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: intervalFuzzy,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Update setiap 1 Detik', style: TextStyle(fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: 5, child: Text('Update setiap 5 Detik', style: TextStyle(fontWeight: FontWeight.bold))),
                  DropdownMenuItem(value: 10, child: Text('Update setiap 10 Detik', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                onChanged: (v) async {
                  if (v != null) {
                    setState(() => intervalFuzzy = v);
                    final fuzzy = context.read<FuzzyController>();
                    fuzzy.interval = v;
                    fuzzy.startTimer();
                    await SettingsHelper.saveInterval(v);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SAFETY =================
  Widget _safetyLimitCard() {
    return _PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _listItem('Ambang pH Minimum', '5.5 pH', Icons.arrow_downward_rounded),
          const Divider(indent: 50, endIndent: 20),
          _listItem('Ambang pH Maksimum', '7.5 pH', Icons.arrow_upward_rounded),
          const Divider(indent: 50, endIndent: 20),
          _listItem('Batas Aman TDS', '1200 PPM', Icons.security_rounded),
        ],
      ),
    );
  }

  // ================= TANAMAN =================
  Widget _plantSettingCard() {
    final plant = context.watch<PlantProvider>().activePlant;
    if (plant == null) return const SizedBox();

    return _PremiumCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _listItem('Jenis Komoditas', plant.name, Icons.eco_outlined),
          const Divider(indent: 50, endIndent: 20),
          _listItem('Lama Tanam', '${plant.hst} Hari Setelah Tanam', Icons.calendar_today_outlined),
          const Divider(indent: 50, endIndent: 20),
          _listItem('Parameter pH Ideal', '${plant.targetPhMin} – ${plant.targetPhMax}', Icons.opacity),
          const Divider(indent: 50, endIndent: 20),
          _listItem('Parameter TDS Ideal', '${plant.targetTdsMin.toInt()} – ${plant.targetTdsMax.toInt()} PPM', Icons.science_outlined),
          const Divider(indent: 50, endIndent: 20),
          ListTile(
            leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.edit_calendar_outlined, size: 20, color: Colors.grey)),
            title: const Text("Tanggal Mulai Tanam", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text("${plant.startDate.day}/${plant.startDate.month}/${plant.startDate.year}", style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff03AF55).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xff03AF55),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.history),
                label: const Text("RIWAYAT TANAMAN", style: TextStyle(fontWeight: FontWeight.w900)),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CycleHistoryPage())),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _showEndCycleDialog(context),
                child: const Text("SELESAI PANEN", style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }


  void _showEndCycleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Selesai Panen?"),
        content: const Text("Siklus tanam saat ini akan diakhiri. Riwayat grafik dan sensor akan disimpan ke history, dan notifikasi akan direset."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final provider = context.read<PlantProvider>();
              final historyData = context.read<SensorProvider>().historyData;
              
              // 1. Akhiri siklus dan simpan data
              await provider.endCycle(historyData);
              
              // 2. Reset Notifikasi & Rekomendasi
              context.read<NotificationController>().clearNotifications();
              context.read<FuzzyController>().clearFuzzyLog();
              
              // 3. Kembali ke Halaman Onboarding
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const PlantSelectionPage()),
                  (route) => false,
                );
              }
            },
            child: const Text("Ya, Akhiri", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  // ================= ABOUT =================
  Widget _aboutCard() {
    return _PremiumCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.info_outline_rounded, color: Color(0xff03AF55), size: 24)),
        title: const Text('Tentang AgriNova', style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text('Informasi sistem & tim pengembang', style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage())),
      ),
    );
  }

  // ================= COMPONENTS =================
  Widget _tile(String title, {String? trailing, IconData? icon}) {
    return ListTile(
      leading: icon != null ? Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 20, color: Colors.grey)) : null,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: trailing != null ? Text(trailing, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade600)) : null,
    );
  }

  Widget _switchTile(String title, bool value, Function(bool) onChanged, IconData icon) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: value ? const Color(0xff03AF55).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 20, color: value ? const Color(0xff03AF55) : Colors.grey)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.white,
        activeTrackColor: const Color(0xff03AF55),
        inactiveTrackColor: Colors.grey.shade300,
      ),
    );
  }

  Widget _listItem(String title, String val, IconData icon) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 20, color: Colors.grey)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      trailing: Text(val, style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey.shade600)),
    );
  }
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
