import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrinova/providers/sensor_provider.dart';
import 'package:agrinova/providers/plant_provider.dart';
import 'package:agrinova/notification/notification_controller.dart';
import 'package:agrinova/notification/notification_model.dart';
import 'package:agrinova/models/fuzzy_thresholds.dart';
import 'dart:async';

// Sistem sekarang hanya ON atau OFF
enum SystemMode { on, off }

class FuzzyController extends ChangeNotifier {
  NotificationController notificationController;
  SensorProvider sensorProvider;
  PlantProvider plantProvider;
  static const String _fuzzyLogKey = 'fuzzy_log';

  FuzzyController(this.notificationController, this.sensorProvider, this.plantProvider) {
    _loadFuzzyLog();
    startTimer();
  }

  Future<void> _loadFuzzyLog() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logStr = prefs.getString(_fuzzyLogKey);
      if (logStr != null) {
        final List decoded = jsonDecode(logStr);
        logRekomendasi = decoded.map((e) {
          return {
            "title": e["title"],
            "desc": e["desc"],
            "time": DateTime.parse(e["time"]),
          };
        }).toList();
        if (logRekomendasi.isNotEmpty) {
          lastRekomendasi = logRekomendasi.first["title"];
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error loading fuzzy log: $e");
    }
  }

  Future<void> _saveFuzzyLog() async {
    final prefs = await SharedPreferences.getInstance();
    final list = logRekomendasi.map((e) {
      return {
        "title": e["title"],
        "desc": e["desc"],
        "time": (e["time"] as DateTime).toIso8601String(),
      };
    }).toList();
    await prefs.setString(_fuzzyLogKey, jsonEncode(list));
  }

  void clearFuzzyLog() async {
    logRekomendasi.clear();
    lastRekomendasi = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_fuzzyLogKey);
    notifyListeners();
  }


  int interval = 600; // 10 menit = 600 detik
  Timer? _timer;

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: interval), (_) {
      updateFromSensor();
    });
  }

  // SENSOR (dummy)
  double ph = 6.2;
  double tds = 800;

  // MODE
  SystemMode mode = SystemMode.on;
  bool get isFuzzyEnabled => mode == SystemMode.on;

  bool? pompaOverride;
  bool? kipasOverride;
  bool? aeratorOverride;

  bool airKritisSent = false;
  bool phWarningSent = false;
  bool tdsWarningSent = false;
  bool suhuWarningSent = false;
  bool sensorFailSent = false;
  bool ekstremSent = false;

  // OUTPUT FUZZY
  bool pompaAktif = false;
  bool kipasAktif = false;
  bool aeratorAktif = false;
  String rekomendasi = 'Tidak diperlukan tindakan';

  double muPhRendah = 0;
  double muPhNormal = 0;
  double muPhTinggi = 0;

  double muTdsRendah = 0;
  double muTdsTinggi = 0;

  // FIRE RULE
  double r1 = 0;
  double r2 = 0;
  double r3 = 0;

  // OUTPUT CRISP
  double outputPompaTDS = 0;
  double outputPompaPH = 0;
  
  // Legacy support for UI
  double get outputPompa => outputPompaTDS > outputPompaPH ? outputPompaTDS : outputPompaPH;

  double _min(double a, double b) => a < b ? a : b;

  bool get r1Active => r1 > 0;
  bool get r2Active => r2 > 0;
  bool get r3Active => r3 > 0;

  String get statusPh {
    if (muPhRendah > muPhNormal && muPhRendah > muPhTinggi) {
      return "Asam";
    } else if (muPhNormal > muPhTinggi) {
      return "Normal";
    } else {
      return "Basa";
    }
  }

  String get statusNutrisi {
    if (outputPompa > 70) return "Tinggi";
    if (outputPompa > 40) return "Sedang";
    return "Rendah";
  }

  List<Map<String, dynamic>> logRekomendasi = [];
  String? lastRekomendasi;

  void updateFromSensor() {
    if (sensorProvider.latestData == null) return;
    
    // Gunakan pH dari sensor
    ph = sensorProvider.latestData!.phValue; 
    tds = sensorProvider.latestData!.tdsPPM;
    double suhu = sensorProvider.latestData!.airTemp;
    double ketinggianAir = 12.0; // Default karena API tidak memberikan ini

    evaluateFuzzy();

    if (outputPompa > 75 && !ekstremSent) {
      notificationController.addNotification(
        "Kondisi Ekstrem",
        "Sistem mendeteksi kebutuhan nutrisi tinggi",
        NotificationType.warning,
      );
      ekstremSent = true;
    }

    if (outputPompa <= 75) {
      ekstremSent = false;
    }

    if (ketinggianAir < 9 && !airKritisSent) {
      notificationController.addNotification(
        "Air Kritis",
        "Segera isi tangki!",
        NotificationType.warning,
      );
      airKritisSent = true;
    }

    if (ketinggianAir >= 9) {
      airKritisSent = false;
    }

    final thresholds = plantProvider.currentThresholds;
    final phL = thresholds.phLimits;
    final tdsL = thresholds.tdsLimits;

    if ((ph < phL[0] || ph > phL[3]) && !phWarningSent) {
      notificationController.addNotification(
        "pH Tidak Normal",
        "Nilai pH di luar batas aman (${phL[0]} - ${phL[3]})",
        NotificationType.warning,
      );
      phWarningSent = true;
    }

    if (ph >= phL[0] && ph <= phL[3]) {
      phWarningSent = false;
    }

    if ((tds < tdsL[0] || tds > tdsL[1] * 1.2) && !tdsWarningSent) {
      notificationController.addNotification(
        "Nutrisi Tidak Ideal",
        "TDS di luar range optimal (${tdsL[0]} - ${tdsL[1]})",
        NotificationType.warning,
      );
      tdsWarningSent = true;
    }

    if (tds >= tdsL[0] && tds <= tdsL[1] * 1.2) {
      tdsWarningSent = false;
    }

    if (suhu > 30 && !suhuWarningSent) {
      notificationController.addNotification(
        "Suhu Tinggi",
        "Suhu terlalu panas (>30°C)",
        NotificationType.warning,
      );
      suhuWarningSent = true;
    }

    if (suhu <= 30) {
      suhuWarningSent = false;
    }

    // --- SENSOR FAILURES ---
    final sData = sensorProvider.latestData!;
    bool isSensorFail = sData.airTemp == -1 || sData.waterTemp == -1 || (sData.tdsPPM == 0 && sData.waterTemp > 0);
    if (isSensorFail && !sensorFailSent) {
      notificationController.addNotification(
        "Sensor Terputus!",
        "Ditemukan kegagalan pada hardware sensor. Silakan cek kabel alat.",
        NotificationType.warning,
      );
      sensorFailSent = true;
    }
    if (!isSensorFail) {
      sensorFailSent = false;
    }
  }

  void evaluateFuzzy() {
    if (!isFuzzyEnabled) {
      outputPompaTDS = 0;
      outputPompaPH = 0;
      pompaAktif = false;
      rekomendasi = "Sistem Fuzzy Dinonaktifkan";
      notifyListeners();
      return;
    }

    final thresholds = plantProvider.currentThresholds;
    final phL = thresholds.phLimits; // [a, b, c, d]
    final tdsL = thresholds.tdsLimits; // [low, high]

    // =====================
    // 1. FUZZIFIKASI pH
    // =====================

    // pH Asam (Kurva Turun)
    if (ph <= phL[0]) {
      muPhRendah = 1;
    } else if (ph > phL[0] && ph < phL[1]) {
      muPhRendah = (phL[1] - ph) / (phL[1] - phL[0]);
    } else {
      muPhRendah = 0;
    }

    // pH Normal (Trapesium)
    if (ph >= phL[1] && ph <= phL[2]) {
      muPhNormal = 1;
    } else if (ph > phL[0] && ph < phL[1]) {
      muPhNormal = (ph - phL[0]) / (phL[1] - phL[0]);
    } else if (ph > phL[2] && ph < phL[3]) {
      muPhNormal = (phL[3] - ph) / (phL[3] - phL[2]);
    } else {
      muPhNormal = 0;
    }

    // pH Basa (Kurva Naik)
    if (ph >= phL[3]) {
      muPhTinggi = 1;
    } else if (ph > phL[2] && ph < phL[3]) {
      muPhTinggi = (ph - phL[2]) / (phL[3] - phL[2]);
    } else {
      muPhTinggi = 0;
    }

    // =====================
    // 2. FUZZIFIKASI TDS
    // =====================

    // TDS Rendah (Bahu Kiri)
    if (tds <= tdsL[0]) {
      muTdsRendah = 1;
    } else if (tds > tdsL[0] && tds < tdsL[1]) {
      muTdsRendah = (tdsL[1] - tds) / (tdsL[1] - tdsL[0]);
    } else {
      muTdsRendah = 0;
    }

    // TDS Tinggi (Bahu Kanan)
    if (tds >= tdsL[1]) {
      muTdsTinggi = 1;
    } else if (tds > tdsL[0] && tds < tdsL[1]) {
      muTdsTinggi = (tds - tdsL[0]) / (tdsL[1] - tdsL[0]);
    } else {
      muTdsTinggi = 0;
    }

    // =====================
    // 3. INFERENSI (MAMDANI)
    // =====================

    // R1: IF pH Normal AND TDS Rendah → Pompa TDS Tinggi (80%), Pompa pH Mati (0%)
    r1 = _min(muPhNormal, muTdsRendah);

    // R2: IF pH Asam AND TDS Rendah → Pompa TDS Mati (0%), Pompa pH (Up) Tinggi (80%)
    r2 = _min(muPhRendah, muTdsRendah);

    // R3: IF pH Basa AND TDS Tinggi → Pompa TDS Mati (0%), Pompa pH (Down) Tinggi (80%)
    r3 = _min(muPhTinggi, muTdsTinggi);

    // =====================
    // 4. DEFUZZIFIKASI (Weighted Average)
    // =====================

    double totalFire = r1 + r2 + r3;

    if (totalFire != 0) {
      // outputPompaTDS: R1=80, R2=0, R3=0
      outputPompaTDS = (r1 * 80 + r2 * 0 + r3 * 0) / totalFire;
      
      // outputPompaPH: R1=0, R2=80, R3=80
      outputPompaPH = (r1 * 0 + r2 * 80 + r3 * 80) / totalFire;
    } else {
      outputPompaTDS = 0;
      outputPompaPH = 0;
    }

    // =====================
    // 5. KEPUTUSAN AKHIR
    // =====================

    pompaAktif = outputPompaTDS > 40 || outputPompaPH > 40;

    if (outputPompaTDS > 50 && outputPompaPH > 50) {
      rekomendasi = "Pompa Nutrisi & pH Aktif";
    } else if (outputPompaTDS > 50) {
      rekomendasi = "Pompa Nutrisi Aktif";
    } else if (outputPompaPH > 50) {
      rekomendasi = "Pompa pH Aktif";
    } else {
      rekomendasi = "Kondisi Optimal";
    }

    // ================= LOG REKOMENDASI =================
    if (rekomendasi != lastRekomendasi) {
      logRekomendasi.insert(0, {
        "title": rekomendasi,
        "desc": "pH: ${ph.toStringAsFixed(1)}, TDS: ${tds.toStringAsFixed(0)}",
        "time": DateTime.now(),
      });

      if (logRekomendasi.length > 50) {
        logRekomendasi.removeLast();
      }

      lastRekomendasi = rekomendasi;
      _saveFuzzyLog();
    }

    // ================= MODE HANDLING =================
    // Pompa hanya dikendalikan jika Fuzzy ON
    if (isFuzzyEnabled) {
      pompaAktif = outputPompaTDS > 40 || outputPompaPH > 40;
    } else {
      pompaAktif = false;
    }

    // Kipas dan Aerator tetap manual independen
    kipasAktif = kipasOverride ?? kipasAktif;
    aeratorAktif = aeratorOverride ?? aeratorAktif;

    notifyListeners();
  }

  void setMode(SystemMode newMode) {
    mode = newMode;
    evaluateFuzzy();
  }

  void toggleFuzzy(bool value) {
    mode = value ? SystemMode.on : SystemMode.off;
    evaluateFuzzy();
  }

  void setPompaManual(bool value) {
    pompaOverride = value;
    notifyListeners();
  }

  void setKipasManual(bool value) {
    kipasOverride = value;
    notifyListeners();
  }

  void setAeratorManual(bool value) {
    aeratorOverride = value;
    notifyListeners();
  }
}
