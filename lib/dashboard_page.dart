import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _appBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _plantInfoCard(context),
            const SizedBox(height: 16),
            _sensorGrid(context),
            const SizedBox(height: 16),
            _chartPlaceholder(),
            const SizedBox(height: 16),
            _fuzzyStatusCard(),
          ],
        ),
      ),
    );
  }

  // ================= APP BAR =================
  AppBar _appBar() {
    return AppBar(
      backgroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/images/logo.png', height: 36),
          const SizedBox(width: 6),
          const Text(
            'AGRINOVA',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 26,
              color: Colors.black,
            ),
          ),
        ],
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(
            Icons.circle_notifications_outlined,
            size: 28,
            color: Color(0xff03AF55),
          ),
        ),
      ],
    );
  }

  // ================= PLANT INFO =================
  Widget _plantInfoCard(BuildContext context) {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // KOTAK KIRI (RESPONSIVE)
            Expanded(
              flex: 2,
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: const Color(0xff03AF55),
                  borderRadius: BorderRadius.circular(11),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // TEKS KANAN
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Jenis Tanaman :',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                  Text(
                    'Selada Romaine',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'HST :',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                  ),
                  Text(
                    'Hari ke-25',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SENSOR GRID =================
  Widget _sensorGrid(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isSmall = width < 380;

    return GridView.count(
      crossAxisCount: isSmall ? 1 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: isSmall ? 1.4 : 1.6,
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
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: SizedBox(
        height: 160,
        child: Padding(
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
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= FUZZY STATUS =================
  Widget _fuzzyStatusCard() {
    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: const ListTile(
        leading: Icon(Icons.check_circle, color: Color(0xff03AF55)),
        title: Text(
          'Status Sistem (Fuzzy)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Optimal. Tidak ada tindakan diperlukan.'),
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
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 28, color: const Color(0xff03AF55)),
                const SizedBox(width: 8),

                // ⬇️ INI KUNCINYA
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (status.isNotEmpty)
                        Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xff03AF55),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
