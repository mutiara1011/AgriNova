import 'package:flutter/material.dart';

class FuzzyInfoPage extends StatelessWidget {
  const FuzzyInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'EDUKASI FUZZY',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                  colors: [
                    const Color(0xff03AF55).withValues(alpha: 0.1),
                    Theme.of(context).scaffoldBackgroundColor,
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 70, 16, 40),
            child: Column(
              children: [
                _section(
                  context: context,
                  title: "Apa itu Logika Fuzzy?",
                  icon: Icons.psychology_rounded,
                  content: "Logika fuzzy adalah metode pengambilan keputusan yang meniru cara berpikir manusia.\n\n"
                      "Berbeda dengan logika biasa (0 atau 1), fuzzy menggunakan nilai di antara, seperti:\n"
                      "• Rendah\n• Sedang\n• Tinggi\n\n"
                      "Sehingga keputusan menjadi lebih fleksibel dan realistis.",
                ),
                _section(
                  context: context,
                  title: "Kenapa Fuzzy Digunakan?",
                  icon: Icons.lightbulb_outline_rounded,
                  content: "Dalam hidroponik, kondisi seperti pH dan nutrisi tidak selalu pasti.\n\n"
                      "Kadang pH tidak langsung 'baik' atau 'buruk', tapi bisa di tengah.\n\n"
                      "Logika fuzzy membantu sistem mengambil keputusan yang lebih halus dan tidak kaku.",
                ),
                _section(
                  context: context,
                  title: "Cara Kerja di Aplikasi Ini",
                  icon: Icons.settings_input_component_rounded,
                  content: "1. Sensor membaca kondisi (pH & nutrisi)\n"
                      "2. Data diubah menjadi kategori (rendah, normal, tinggi)\n"
                      "3. Sistem menggunakan aturan IF–THEN\n"
                      "4. Sistem menentukan tindakan (pompa, aerator, dll)\n\n"
                      "Semua proses ini berjalan otomatis secara real-time.",
                ),
                _section(
                  context: context,
                  title: "Manfaat untuk Hidroponik",
                  icon: Icons.eco_outlined,
                  content: "• Monitoring lebih cerdas\n"
                      "• Mengurangi kesalahan manual\n"
                      "• Otomatisasi kontrol sistem\n"
                      "• Tanaman lebih stabil dan sehat\n"
                      "• Menghemat waktu dan tenaga",
                ),
                _section(
                  context: context,
                  title: "Kesimpulan",
                  icon: Icons.verified_user_outlined,
                  content: "Logika Fuzzy Mamdani membantu sistem mengambil keputusan secara otomatis dan adaptif.\n\n"
                      "Dengan teknologi ini, pengguna tidak perlu selalu mengecek kondisi secara manual.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({
    required context,
    required String title,
    required IconData icon,
    required String content,
  }) {
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: const Color(0xff03AF55).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: const Color(0xff03AF55), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(content, style: TextStyle(height: 1.6, fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
