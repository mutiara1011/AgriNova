import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'detail_chart_page.dart';
import 'notification_page.dart';
import 'dart:async';

class DashboardPage extends StatefulWidget {
  final Function(int) onTabChange;

  const DashboardPage({super.key, required this.onTabChange});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final PageController controller = PageController();
  double getWidth(BuildContext context) => MediaQuery.of(context).size.width;
  double getHeight(BuildContext context) => MediaQuery.of(context).size.height;
  late Timer timer;
  int currentIndex = 0;
  final int chartsLength = 6;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (currentIndex < chartsLength - 1) {
        currentIndex++;
      } else {
        currentIndex = 0;
      }

      controller.animateToPage(
        currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    timer.cancel();
    controller.dispose();
    super.dispose();
  }

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
            _chartSlider(context),
            const SizedBox(height: 16),
            _fuzzyStatusCard(context),
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
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotificationPage()),
              );
            },
            child: const Icon(
              Icons.circle_notifications_outlined,
              size: 28,
              color: Color(0xff03AF55),
            ),
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
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Stack(
                  children: [
                    // GAMBAR
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Image.asset(
                        'assets/images/selada_romaine.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),

                    // OVERLAY HIJAU (BIAR MATCH TEMA)
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xff03AF55).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ],
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
  Widget _chartSlider(BuildContext context) {
    final charts = [
      chartItem("NUTRISI", "Grafik TDS", "850 PPM", Colors.green),
      chartItem("KEASAMAN", "Grafik PH", "6.2 pH", Colors.pink),
      chartItem("ATMOSFER", "Grafik Suhu Ruangan", "28°C", Colors.blue),
      chartItem("UDARA", "Kelembapan Ruangan", "65%", Colors.blueGrey),
      chartItem("RESERVOIR", "Grafik Suhu Air", "24°C", Colors.green),
      chartItem("FOTOSINTESIS", "Intensitas Cahaya", "1200 Lux", Colors.blue),
    ];

    return Card(
      color: const Color(0xffEFFAF5),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: controller,
                itemCount: charts.length,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });

                  timer.cancel();

                  Future.delayed(const Duration(seconds: 3), () {
                    timer = Timer.periodic(const Duration(seconds: 5), (
                      Timer timer,
                    ) {
                      if (currentIndex < charts.length - 1) {
                        currentIndex++;
                      } else {
                        currentIndex = 0;
                      }

                      controller.animateToPage(
                        currentIndex,
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    });
                  });
                },
                itemBuilder: (context, index) {
                  return charts[index];
                },
              ),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(charts.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: currentIndex == index ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: currentIndex == index
                        ? const Color(0xff03AF55)
                        : Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(10),
                  ),
                );
              }),
            ),

            // BUTTON DETAIL
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailChartPage()),
                  );
                },
                child: const Text(
                  "Lihat Detail",
                  style: TextStyle(color: Color(0xff03AF55)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= FUZZY STATUS =================
  Widget _fuzzyStatusCard(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        widget.onTabChange(2);
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff1B8E3E), Color(0xff03AF55)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.psychology,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "LOGIKA FUZZY",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // STATUS
            const Text(
              "Status Nutrisi Saat Ini",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 4),

            const Text(
              "Optimal",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // PROGRESS BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: 0.85,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),

            const SizedBox(height: 12),

            // DESKRIPSI
            const Text(
              "Sistem menyesuaikan konsentrasi PPM secara otomatis untuk pertumbuhan maksimal.",
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

Widget chartItem(String label, String title, String value, Color color) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // HEADER
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),

      const SizedBox(height: 16),

      // GRAFIK
      SizedBox(
        height: 120,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(show: false),
            lineBarsData: [
              LineChartBarData(
                isCurved: true,
                color: color,
                barWidth: 3,
                spots: [
                  FlSpot(0, 2),
                  FlSpot(1, 3),
                  FlSpot(2, 2.5),
                  FlSpot(3, 4),
                  FlSpot(4, 1.5),
                  FlSpot(5, 3),
                ],
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
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
