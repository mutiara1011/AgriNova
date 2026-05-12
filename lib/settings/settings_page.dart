import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../fuzzy/fuzzy_controller.dart';
import 'settings_helper.dart';
import 'about_page.dart';
import 'package:agrinova/notification/notification_controller.dart';
import 'theme_controller.dart';
import '../providers/plant_provider.dart';
import '../onboarding/plant_selection_page.dart';
import '../history/cycle_history_page.dart';
import 'package:agrinova/models/plant_cycle.dart';


class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}
class _SettingsPageState extends State<SettingsPage> {
  bool notifikasi = true;
  bool modeGelap = false;

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

      // Map old modes or load new ON/OFF mode
      if (modeStr == 'on' || modeStr == 'auto' || modeStr == 'semi') {
        fuzzy.setMode(SystemMode.on);
      } else {
        fuzzy.setMode(SystemMode.off);
      }

      fuzzy.interval = interval;
      fuzzy.startTimer();

      setState(() {
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          _switchTile(
            'Otomatisasi Sistem Fuzzy', 
            fuzzy.isFuzzyEnabled, 
            (v) async {
              fuzzy.toggleFuzzy(v);
              await SettingsHelper.saveMode(v ? 'on' : 'off');
            }, 
            Icons.psychology_rounded
          ),
          const Divider(indent: 50, endIndent: 20),
          _listItem('Status Operasi', fuzzy.isFuzzyEnabled ? 'AKTIF' : 'NON-AKTIF', Icons.settings_power_rounded),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            width: double.infinity,
            decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
            child: const Text(
              'Update Otomatis setiap 10 Menit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "*Interval ini dioptimalkan untuk menjaga akurasi data dan efisiensi baterai.",
            style: TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
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
          _listItem('Parameter TDS (Veg)', '${plant.targetTdsVegetatifMin.toInt()} – ${plant.targetTdsVegetatifMax.toInt()} PPM', Icons.science_outlined),
          const Divider(indent: 50, endIndent: 20),
          _listItem('Parameter TDS (Pem)', '${plant.targetTdsPembesaranMin.toInt()} – ${plant.targetTdsPembesaranMax.toInt()} PPM', Icons.science_outlined),
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
              final notifController = context.read<NotificationController>();
              final fuzzyController = context.read<FuzzyController>();
              
              // 1. Akhiri siklus di Backend
              await provider.endCycle();
              
              // 2. Reset Notifikasi & Rekomendasi
              notifController.clearNotifications();
              fuzzyController.clearFuzzyLog();
              
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
        activeThumbColor: Colors.white,
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
  final EdgeInsetsGeometry? padding;

  const _PremiumCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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

