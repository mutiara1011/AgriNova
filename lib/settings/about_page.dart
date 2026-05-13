import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'TENTANG AGRINOVA',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 40),
        child: Column(
          children: [
            _header(),
            _section(context, "Deskripsi Aplikasi", Icons.description_rounded, "AGRINOVA adalah aplikasi monitoring dan kontrol nutrisi hidroponik berbasis kecerdasan buatan (Fuzzy Logic) untuk efisiensi budidaya modern."),
            _section(context, "Latar Belakang", Icons.school_rounded, "Pengelolaan hidroponik membutuhkan pengawasan parameter seperti pH dan nutrisi (TDS). Logika fuzzy digunakan untuk membantu sistem mengambil keputusan secara otomatis dan lebih fleksibel dibanding kontrol manual."),
            _section(context, "Tujuan Sistem", Icons.flag_rounded, "• Membantu monitoring kondisi tanaman\n• Mengotomatisasi pengambilan keputusan\n• Mengurangi kesalahan manusia\n• Meningkatkan efisiensi sistem hidroponik"),
            _section(context, "Fitur Utama", Icons.star_rounded, "• Monitoring pH, TDS, suhu, dan kelembapan\n• Kontrol manual dan otomatis\n• Sistem rekomendasi berbasis fuzzy\n• Notifikasi kondisi sistem\n• Riwayat rekomendasi"),
            _section(context, "Mode Sistem", Icons.tune_rounded, "1. AUTO (Fuzzy): Sistem bekerja otomatis penuh.\n2. SEMI AUTO: Sistem memberi rekomendasi, user mengeksekusi.\n3. MANUAL: Kontrol penuh oleh pengguna."),
            _section(context, "Cara Kerja Sistem", Icons.settings_rounded, "1. Sensor membaca kondisi lingkungan\n2. Data dikirim ke aplikasi secara real-time\n3. Sistem fuzzy memproses data & menghasilkan rekomendasi\n4. Tindakan dieksekusi sesuai mode yang dipilih"),
            _section(context, "Teknologi yang Digunakan", Icons.memory_rounded, "• Flutter SDK (Mobile Application)\n• IoT Sensor Node (pH, TDS, Temp)\n• Fuzzy Mamdani (Decision Support)\n• Provider (State Management)"),
            _section(context, "Manfaat Sistem", Icons.eco_rounded, "• Monitoring lebih mudah & akurat\n• Menghemat waktu dan tenaga\n• Meningkatkan kualitas dan stabilitas tanaman"),
            _section(context, "Pengembang", Icons.person_pin_rounded, "MUTIARA SANDI\nInformatika - Universitas Sultan Ageng Tirtayasa"),
            const SizedBox(height: 24),
            const Text("VERSION 1.0.0 (BETA)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 2)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Image.asset('assets/images/logo.png', height: 80),
        ),
        const SizedBox(height: 20),
        const Text("AGRINOVA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const Text("SMART HYDROPONIC SOLUTION", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _section(BuildContext context, String title, IconData icon, String content) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: const Color(0xff03AF55), size: 22)),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 16),
          Text(content, style: TextStyle(height: 1.6, fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
