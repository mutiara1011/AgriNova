import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tentang Aplikasi"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _header(),

            _section(
              "Deskripsi Aplikasi",
              Icons.description,
              "AGRINOVA adalah aplikasi mobile berbasis Flutter yang dirancang untuk membantu monitoring dan kontrol nutrisi hidroponik menggunakan metode Fuzzy Mamdani.",
            ),

            _section(
              "Latar Belakang",
              Icons.school,
              "Pengelolaan hidroponik membutuhkan pengawasan parameter seperti pH dan nutrisi (TDS). Namun, pengambilan keputusan secara manual seringkali tidak konsisten.\n\n"
                  "Oleh karena itu, digunakan logika fuzzy untuk membantu sistem mengambil keputusan secara otomatis dan lebih fleksibel.",
            ),

            _section(
              "Tujuan Sistem",
              Icons.flag,
              "• Membantu monitoring kondisi tanaman\n"
                  "• Mengotomatisasi pengambilan keputusan\n"
                  "• Mengurangi kesalahan manusia\n"
                  "• Meningkatkan efisiensi sistem hidroponik",
            ),

            _section(
              "Fitur Utama",
              Icons.star,
              "• Monitoring pH, TDS, suhu, dan kelembapan\n"
                  "• Kontrol manual dan otomatis\n"
                  "• Sistem rekomendasi berbasis fuzzy\n"
                  "• Notifikasi kondisi sistem\n"
                  "• Riwayat rekomendasi",
            ),

            _section(
              "Cara Menggunakan Aplikasi",
              Icons.menu_book,
              "1. Buka aplikasi AGRINOVA\n"
                  "2. Lihat Dashboard untuk memantau kondisi tanaman\n"
                  "3. Masuk ke halaman Kontrol untuk mengatur sistem\n"
                  "4. Gunakan mode AUTO untuk kontrol otomatis berbasis fuzzy\n"
                  "5. Gunakan mode MANUAL jika ingin kontrol langsung\n"
                  "6. Periksa halaman Fuzzy untuk melihat proses dan hasil evaluasi\n"
                  "7. Lihat notifikasi jika terjadi kondisi tidak normal\n"
                  "8. Gunakan Settings untuk mengatur sistem sesuai kebutuhan",
            ),

            _section(
              "Mode Sistem",
              Icons.tune,
              "Aplikasi AGRINOVA menyediakan 3 mode pengoperasian sistem:\n\n"
                  "1. AUTO (Fuzzy)\n"
                  "Pada mode ini, sistem bekerja secara otomatis menggunakan metode Fuzzy Mamdani.\n"
                  "Keputusan seperti mengaktifkan pompa atau menyesuaikan nutrisi akan dilakukan oleh sistem berdasarkan kondisi sensor.\n\n"
                  "2. SEMI AUTO\n"
                  "Pada mode ini, sistem tetap memberikan rekomendasi berdasarkan fuzzy, namun pengguna dapat menentukan apakah rekomendasi tersebut akan dijalankan atau tidak.\n\n"
                  "3. MANUAL\n"
                  "Pada mode ini, seluruh kontrol dilakukan oleh pengguna tanpa bantuan sistem fuzzy.\n"
                  "Pengguna memiliki kendali penuh terhadap sistem.\n\n"
                  "Mode ini memberikan fleksibilitas bagi pengguna sesuai kebutuhan dan tingkat pengalaman.",
            ),

            _section(
              "Penjelasan Menu",
              Icons.dashboard,
              "• Dashboard → Menampilkan kondisi sensor secara real-time\n"
                  "• Kontrol → Mengatur pompa dan sistem secara manual/otomatis\n"
                  "• Fuzzy → Menampilkan proses pengambilan keputusan sistem\n"
                  "• Notifikasi → Informasi kondisi penting sistem\n"
                  "• Settings → Pengaturan sistem dan aplikasi",
            ),

            _section(
              "Tips Penggunaan",
              Icons.tips_and_updates,
              "• Gunakan mode AUTO untuk hasil optimal\n"
                  "• Pastikan sensor dalam kondisi baik\n"
                  "• Perhatikan notifikasi sistem\n"
                  "• Cek riwayat rekomendasi untuk analisis\n"
                  "• Gunakan interval fuzzy sesuai kebutuhan",
            ),

            _section(
              "Teknologi yang Digunakan",
              Icons.memory,
              "• Flutter (Mobile App)\n"
                  "• IoT Sensor (pH, TDS, suhu)\n"
                  "• Fuzzy Mamdani (Decision Support System)\n"
                  "• Provider (State Management)",
            ),

            _section(
              "Cara Kerja Sistem",
              Icons.settings,
              "1. Sensor membaca kondisi lingkungan\n"
                  "2. Data dikirim ke aplikasi\n"
                  "3. Sistem fuzzy memproses data\n"
                  "4. Sistem menghasilkan rekomendasi\n"
                  "5. User atau sistem mengeksekusi tindakan",
            ),

            _section(
              "Manfaat Sistem",
              Icons.eco,
              "• Monitoring lebih mudah\n"
                  "• Pengambilan keputusan lebih akurat\n"
                  "• Menghemat waktu dan tenaga\n"
                  "• Meningkatkan kualitas tanaman",
            ),

            _section(
              "Pengembang",
              Icons.person,
              "Mutiara Sandi\nMahasiswa Informatika\nUniversitas Sultan Ageng Tirtayasa",
            ),

            const SizedBox(height: 16),

            const Text(
              "Versi 1.0.0",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Image.asset('assets/images/logo.png', height: 70),
        SizedBox(height: 5),
        Text(
          "AGRINOVA",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 4),
        Text(
          "Smart Hydroponic Monitoring System",
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _section(String title, IconData icon, String content) {
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
