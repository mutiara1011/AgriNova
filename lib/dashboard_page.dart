import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/images/logo.png', height: 38),
            SizedBox(width: 3),
            Text(
              'AGRINOVA',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(
              Icons.circle_notifications_outlined,
              size: 30,
              color: Color(0xff03AF55),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _plantInfoCard(),
            const SizedBox(height: 16),
            _sensorGrid(),
            const SizedBox(height: 16),
            _chartPlaceholder(),
            const SizedBox(height: 16),
            _fuzzyStatusCard(),
          ],
        ),
      ),
    );
  }

  // ================= PLANT INFO =================
  Widget _plantInfoCard() {
    return Card(
      color: Color(0xffEFFAF5),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 177,
              height: 110,
              decoration: BoxDecoration(
                color: Color(0xff03AF55),
                borderRadius: BorderRadius.circular(11),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Jenis Tanaman :',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Selada Romaine',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'HST :',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'Hari ke-25',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ================= SENSOR GRID =================
  Widget _sensorGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.8, // 👈 INI KUNCINYA
      children: const [
        _SensorCard(
          title: 'Ketinggian Air',
          value: '12 cm',
          status: 'Normal',
          icon: Icons.water,
        ),
        _SensorCard(
          title: 'Kelembapan Ruangan',
          value: '75%',
          status: '',
          icon: Icons.water_drop,
        ),
        _SensorCard(
          title: 'Suhu Air',
          value: '24°C',
          status: '',
          icon: Icons.thermostat,
        ),
        _SensorCard(
          title: 'Suhu Ruangan',
          value: '24°C',
          status: '',
          icon: Icons.device_thermostat,
        ),
        _SensorCard(
          title: 'pH Sensor',
          value: '6.2',
          status: '',
          icon: Icons.science,
        ),
        _SensorCard(
          title: 'TDS Sensor',
          value: '850 PPM',
          status: '',
          icon: Icons.speed,
        ),
        _SensorCard(
          title: 'Intensitas Cahaya',
          value: '1500 Lux',
          status: '',
          icon: Icons.light_mode,
        ),
        _SensorCard(
          title: 'Indikator Cuaca',
          value: 'Hujan',
          status: '',
          icon: Icons.cloud,
        ),
      ],
    );
  }

  // ================= CHART =================
  Widget _chartPlaceholder() {
    return Card(
      color: Color(0xffEFFAF5),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Grafik Sensor',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Expanded(
              child: Center(
                child: Text(
                  'Grafik TDS / pH / Suhu\n(placeholder)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FUZZY STATUS =================
  Widget _fuzzyStatusCard() {
    return Card(
      color: Color(0xffEFFAF5),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Color(0xff03AF55)),
        title: const Text(
          'Status Sistem (Fuzzy)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Optimal. Tidak ada tindakan diperlukan.'),
      ),
    );
  }
}

// ================= SENSOR CARD =================
class _SensorCard extends StatelessWidget {
  final String title;
  final String value;
  final String status;
  final IconData icon;

  const _SensorCard({
    required this.title,
    required this.value,
    required this.status,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ===== TITLE (ATAS - TENGAH) =====
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),

            // ===== ICON + VALUE =====
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 30, color: const Color(0xff03AF55)),
                const SizedBox(width: 8),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // VALUE
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    // STATUS (DI BAWAH VALUE)
                    if (status.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          status,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff03AF55),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
