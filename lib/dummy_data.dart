import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';

class DummyData {
  static final _rand = Random();

  // ================= TANAMAN =================
  static String plantName = "Selada Romaine";
  static int hst = 25;

  // ================= SENSOR =================
  static double tds = 800;
  static double ph = 6.2;
  static double suhu = 26;
  static double suhuAir = 24;
  static double kelembapan = 70;
  static double cahaya = 1200;
  static double ketinggianAir = 12;

  static String cuaca = "Cerah";

  static Timer? _timer;

  static void start() {
    _timer ??= Timer.periodic(const Duration(seconds: 3), (_) {
      update();
    });
  }

  // ================= UPDATE REALTIME =================
  static void update() {
    // SENSOR BERGERAK REALISTIS
    tds += _rand.nextDouble() * 20 - 10;
    ph += _rand.nextDouble() * 0.2 - 0.1;
    suhu += _rand.nextDouble() * 0.5 - 0.25;
    suhuAir += _rand.nextDouble() * 0.3 - 0.15;
    kelembapan += _rand.nextDouble() * 2 - 1;
    cahaya += _rand.nextDouble() * 50 - 25;
    ketinggianAir += _rand.nextDouble() * 0.5 - 0.2;

    // BATAS NILAI (BIAR MASUK AKAL)
    tds = tds.clamp(600, 1000);
    ph = ph.clamp(5.5, 7.5);
    suhu = suhu.clamp(24, 32);
    suhuAir = suhuAir.clamp(22, 28);
    kelembapan = kelembapan.clamp(50, 90);
    cahaya = cahaya.clamp(800, 1600);
    ketinggianAir = ketinggianAir.clamp(8, 15);

    // CUACA RANDOM
    final cuacaList = ["Cerah", "Berawan", "Hujan"];
    cuaca = cuacaList[_rand.nextInt(3)];

    if (_rand.nextDouble() < 0.05) {
      hst++; // naik perlahan
    }
  }

  // ================= GRAFIK =================
  static List<FlSpot> generateChart(double base) {
    return List.generate(7, (i) {
      double x = i * 4;
      double y = base + (_rand.nextDouble() * 10 - 5);
      return FlSpot(x, y);
    });
  }

  static List<FlSpot> tdsChart() => generateChart(tds);
  static List<FlSpot> phChart() => generateChart(ph);
  static List<FlSpot> suhuChart() => generateChart(suhu);
  static List<FlSpot> kelembapanChart() => generateChart(kelembapan);
  static List<FlSpot> cahayaChart() => generateChart(cahaya);
  static List<FlSpot> suhuAirChart() => generateChart(suhuAir);
  static List<FlSpot> reservoirChart() => generateChart(suhuAir);
}
