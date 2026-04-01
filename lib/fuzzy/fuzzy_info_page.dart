import 'package:flutter/material.dart';

class FuzzyInfoPage extends StatelessWidget {
  const FuzzyInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edukasi Fuzzy"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _section(
              title: "Apa itu Logika Fuzzy?",
              icon: Icons.psychology,
              content:
                  "Logika fuzzy adalah metode pengambilan keputusan yang meniru cara berpikir manusia.\n\n"
                  "Berbeda dengan logika biasa (0 atau 1), fuzzy menggunakan nilai di antara, seperti:\n"
                  "• Rendah\n• Sedang\n• Tinggi\n\n"
                  "Sehingga keputusan menjadi lebih fleksibel dan realistis.",
            ),

            _section(
              title: "Kenapa Fuzzy Digunakan?",
              icon: Icons.lightbulb,
              content:
                  "Dalam hidroponik, kondisi seperti pH dan nutrisi tidak selalu pasti.\n\n"
                  "Kadang pH tidak langsung 'baik' atau 'buruk', tapi bisa di tengah.\n\n"
                  "Logika fuzzy membantu sistem mengambil keputusan yang lebih halus dan tidak kaku.",
            ),

            _section(
              title: "Cara Kerja di Aplikasi Ini",
              icon: Icons.settings,
              content:
                  "1. Sensor membaca kondisi (pH & nutrisi)\n"
                  "2. Data diubah menjadi kategori (rendah, normal, tinggi)\n"
                  "3. Sistem menggunakan aturan IF–THEN\n"
                  "4. Sistem menentukan tindakan (pompa, aerator, dll)\n\n"
                  "Semua proses ini berjalan otomatis secara real-time.",
            ),

            _section(
              title: "Contoh Kasus",
              icon: Icons.science,
              content:
                  "Jika:\n"
                  "• pH rendah\n"
                  "• Nutrisi rendah\n\n"
                  "Maka:\n"
                  "→ Sistem akan meningkatkan pompa nutrisi\n\n"
                  "Jika:\n"
                  "• pH normal\n"
                  "• Nutrisi cukup\n\n"
                  "→ Tidak perlu tindakan",
            ),

            _section(
              title: "Manfaat untuk Hidroponik",
              icon: Icons.eco,
              content:
                  "• Monitoring lebih cerdas\n"
                  "• Mengurangi kesalahan manual\n"
                  "• Otomatisasi kontrol sistem\n"
                  "• Tanaman lebih stabil dan sehat\n"
                  "• Menghemat waktu dan tenaga",
            ),

            _section(
              title: "Kesimpulan",
              icon: Icons.check_circle,
              content:
                  "Logika Fuzzy Mamdani membantu sistem mengambil keputusan secara otomatis dan adaptif.\n\n"
                  "Dengan teknologi ini, pengguna tidak perlu selalu mengecek kondisi secara manual.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required String content,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffEFFAF5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xff03AF55)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }
}
