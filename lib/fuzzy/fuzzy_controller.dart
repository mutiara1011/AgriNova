import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrinova/providers/sensor_provider.dart';
import 'package:agrinova/notification/notification_controller.dart';
import 'package:agrinova/notification/notification_model.dart';
import 'dart:async';

enum SystemMode { auto, semiAuto, manual }

class FuzzyController extends ChangeNotifier {
  NotificationController notificationController;
  SensorProvider sensorProvider;
  static const String _fuzzyLogKey = 'fuzzy_log';

  FuzzyController(this.notificationController, this.sensorProvider) {
    _loadFuzzyLog();
    startTimer();
  }

  Future<void> _loadFuzzyLog() async {
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
  SystemMode mode = SystemMode.auto;
  bool get isAuto => mode == SystemMode.auto;
  bool get isManual => mode == SystemMode.manual;
  bool get isSemiAuto => mode == SystemMode.semiAuto;

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
  double outputPompa = 0;

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

    if ((ph < 5.5 || ph > 6.5) && !phWarningSent) {
      notificationController.addNotification(
        "pH Tidak Normal",
        "Nilai pH di luar batas aman (5.5 - 6.5)",
        NotificationType.warning,
      );
      phWarningSent = true;
    }

    if (ph >= 5.5 && ph <= 6.5) {
      phWarningSent = false;
    }

    if ((tds < 700 || tds > 900) && !tdsWarningSent) {
      notificationController.addNotification(
        "Nutrisi Tidak Ideal",
        "TDS di luar range optimal (700-900)",
        NotificationType.warning,
      );
      tdsWarningSent = true;
    }

    if (tds >= 700 && tds <= 900) {
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
    if (isManual) return;

    // =====================
    // 1. FUZZIFIKASI pH
    // =====================

    // pH Rendah
    if (ph <= 5.5) {
      muPhRendah = 1;
    } else if (ph > 5.5 && ph < 5.8) {
      muPhRendah = (5.8 - ph) / 0.3;
    } else {
      muPhRendah = 0;
    }

    // pH Normal
    if (ph >= 5.8 && ph <= 6.2) {
      muPhNormal = 1;
    } else if (ph > 5.5 && ph < 5.8) {
      muPhNormal = (ph - 5.5) / 0.3;
    } else if (ph > 6.2 && ph < 6.5) {
      muPhNormal = (6.5 - ph) / 0.3;
    } else {
      muPhNormal = 0;
    }

    // pH Tinggi
    if (ph >= 6.5) {
      muPhTinggi = 1;
    } else if (ph > 6.2 && ph < 6.5) {
      muPhTinggi = (ph - 6.2) / 0.3;
    } else {
      muPhTinggi = 0;
    }

    // =====================
    // 2. FUZZIFIKASI TDS
    // =====================

    if (tds <= 700) {
      muTdsRendah = 1;
      muTdsTinggi = 0;
    } else if (tds > 700 && tds < 900) {
      muTdsRendah = (900 - tds) / 200;
      muTdsTinggi = (tds - 700) / 200;
    } else {
      muTdsRendah = 0;
      muTdsTinggi = 1;
    }

    // =====================
    // 3. INFERENSI (MAMDANI)
    // =====================

    // R1: IF pH Normal AND TDS Tinggi → Pompa Sedang
    r1 = _min(muPhNormal, muTdsTinggi);

    // R2: IF pH Rendah AND TDS Rendah → Pompa Tinggi
    r2 = _min(muPhRendah, muTdsRendah);

    // R3: IF pH Tinggi AND TDS Tinggi → Pompa Rendah
    r3 = _min(muPhTinggi, muTdsTinggi);

    // =====================
    // 4. DEFUZZIFIKASI
    // =====================

    // Nilai output (contoh)
    double z1 = 50; // sedang
    double z2 = 80; // tinggi

    double z3 = 20; // rendah

    double totalFire = r1 + r2 + r3;

    if (totalFire != 0) {
      outputPompa = ((r1 * z1) + (r2 * z2) + (r3 * z3)) / totalFire;
    }

    // =====================
    // 5. KEPUTUSAN AKHIR
    // =====================

    pompaAktif = outputPompa > 40;

    if (outputPompa > 70) {
      rekomendasi = "Pompa nutrisi tinggi";
    } else if (outputPompa > 40) {
      rekomendasi = "Pompa nutrisi sedang";
    } else {
      rekomendasi = "Tidak perlu pompa";
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

    kipasAktif = ph > 7;
    aeratorAktif = true;

    // hasil fuzzy asli
    bool pompaFuzzy = outputPompa > 40;
    bool kipasFuzzy = ph > 7;
    bool aeratorFuzzy = true;

    // ================= MODE HANDLING =================

    if (isManual) {
      // full manual → pakai override semua
      pompaAktif = pompaOverride ?? pompaAktif;
      kipasAktif = kipasOverride ?? kipasAktif;
      aeratorAktif = aeratorOverride ?? aeratorAktif;
    } else if (isSemiAuto) {
      // combine → pakai override kalau ada
      pompaAktif = pompaOverride ?? pompaFuzzy;
      kipasAktif = kipasOverride ?? kipasFuzzy;
      aeratorAktif = aeratorOverride ?? aeratorFuzzy;
    } else {
      // full auto → pakai fuzzy
      pompaAktif = pompaFuzzy;
      kipasAktif = kipasFuzzy;
      aeratorAktif = aeratorFuzzy;
    }

    notifyListeners();
  }

  void setMode(SystemMode newMode) {
    mode = newMode;

    if (mode == SystemMode.auto) {
      // reset override kalau full auto
      pompaOverride = null;
      kipasOverride = null;
      aeratorOverride = null;
    }

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
