import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        title: Row(
          children: const [
            Icon(Icons.eco, color: Colors.green),
            SizedBox(width: 8),
            Text('AGRINOVA', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.notifications_none),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Jenis Tanaman :',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  'Selada Romaine',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'HST : Hari ke-25',
                  style: TextStyle(color: Colors.black87),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.check_circle, color: Colors.green),
        title: const Text(
          'Status Sistem (Fuzzy)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('Optimal.\nTidak ada tindakan diperlukan.'),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            if (status.isNotEmpty)
              Text(
                status,
                style: const TextStyle(color: Colors.green, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
