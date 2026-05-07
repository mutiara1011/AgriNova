import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:agrinova/providers/sensor_provider.dart';
import 'package:agrinova/providers/plant_provider.dart';
import 'package:agrinova/notification/notification_controller.dart';
import 'package:agrinova/notification/notification_model.dart';
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
    sensorProvider.addListener(updateFromSensor);
    plantProvider.addListener(evaluateFuzzy);
    updateFromSensor();
    startTimer();
  }

  @override
  void dispose() {
    sensorProvider.removeListener(updateFromSensor);
    plantProvider.removeListener(evaluateFuzzy);
    _timer?.cancel();
    super.dispose();
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

  // SENSOR (actual/dummy)
  double ph = 6.2;
  double tds = 800;
  double waterTemp = 25.0; // Suhu Air dari sensor (°C)
  double ketinggianAir = 12.0; // Ketinggian Air dari sensor (cm)

  // Rumus Bak: 1x1 meter = 100x100 cm
  // Volume (Liters) = 100 * 100 * H / 1000 = 10 * H
  double get volumeAir => 10.0 * ketinggianAir;

  // Laju Alir Pompa Peristaltik secara pasti: 3.3 ml per detik
  static const double peristalticFlowRate = 3.3; // mL/second

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

  // OUTPUT FUZZY & AKTUATOR
  bool pompaAktif = false;
  bool kipasAktif = false;
  bool aeratorAktif = false;
  String rekomendasi = 'Tidak diperlukan tindakan';

  // MEMBERSHIP VALUES
  double muPhRendah = 0;
  double muPhNormal = 0;
  double muPhTinggi = 0;

  double muTdsRendah = 0;
  double muTdsNormal = 0;
  double muTdsTinggi = 0;

  double muSuhuDingin = 0;
  double muSuhuNormal = 0;
  double muSuhuPanas = 0;

  // FIRE RULE (Fuzzy Mamdani 1: TDS & Suhu)
  double r1 = 0; // TDS Rendah AND Suhu Dingin -> AB Mix Sedang (0.6)
  double r2 = 0; // TDS Rendah AND Suhu Optimal -> AB Mix Tinggi (1.0)
  double r3 = 0; // TDS Rendah AND Suhu Panas -> AB Mix Rendah (0.3)
  double r4 = 0; // TDS Normal -> AB Mix Mati (0)
  double r5 = 0; // TDS Tinggi -> AB Mix Mati (0)

  // FIRE RULE (Fuzzy Mamdani 2: pH & Suhu)
  double r6 = 0; // pH Tinggi AND Suhu Dingin -> pH Down Sedang (0.6)
  double r7 = 0; // pH Tinggi AND Suhu Optimal -> pH Down Tinggi (1.0)
  double r8 = 0; // pH Tinggi AND Suhu Panas -> pH Down Rendah (0.4)
  double r9 = 0; // pH Normal -> pH Down Mati (0)
  double r10 = 0; // pH Rendah -> pH Down Mati (0)

  // OUTPUT CRISP (Scale Factor 0-100%)
  double outputPompaTDS = 0;
  double outputPompaPH = 0;

  // Recommended durations (seconds)
  double recommendedPompaTDSSeconds = 0;
  double recommendedPompaPHSeconds = 0;

  // Volumes needed (mL)
  double abMixNeededML = 0;
  double phDownNeededML = 0;
  
  // Legacy support for UI
  double get outputPompa => outputPompaTDS > outputPompaPH ? outputPompaTDS : outputPompaPH;

  double _min(double a, double b) => a < b ? a : b;

  // Compatibility getters for rules
  bool get r1Active => r1 > 0 || r2 > 0 || r3 > 0;
  bool get r2Active => r6 > 0 || r7 > 0 || r8 > 0;
  bool get r3Active => false;

  String get membershipStatusPh {
    if (muPhRendah >= muPhNormal && muPhRendah >= muPhTinggi) return "Rendah";
    if (muPhNormal >= muPhTinggi) return "Normal";
    return "Tinggi";
  }

  String get membershipStatusTds {
    if (muTdsRendah >= muTdsNormal && muTdsRendah >= muTdsTinggi) return "Rendah";
    if (muTdsNormal >= muTdsTinggi) return "Normal";
    return "Tinggi";
  }

  String get statusPh => membershipStatusPh == "Rendah" ? "Asam" : (membershipStatusPh == "Tinggi" ? "Basa" : "Normal");

  String get statusNutrisi {
    if (outputPompaTDS > 70) return "Tinggi";
    if (outputPompaTDS > 30) return "Sedang";
    return "Optimal";
  }

  List<Map<String, dynamic>> logRekomendasi = [];
  String? lastRekomendasi;

  void updateFromSensor() {
    if (sensorProvider.latestData == null) {
      evaluateFuzzy();
      return;
    }

    // Gunakan pH, TDS, dan Suhu Air dari sensor
    ph = sensorProvider.latestData!.phValue;
    tds = sensorProvider.latestData!.tdsPPM;
    waterTemp = sensorProvider.latestData!.waterTemp;
    if (waterTemp <= 0) waterTemp = 25.0; // fallback default
    double suhu = waterTemp;
    ketinggianAir = 12.0; // Default karena API tidak memberikan ini

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

    if (suhu > 33 && !suhuWarningSent) {
      notificationController.addNotification(
        "Suhu Tinggi",
        "Suhu terlalu panas (>33°C)",
        NotificationType.warning,
      );
      suhuWarningSent = true;
    }

    if (suhu <= 33) {
      suhuWarningSent = false;
    }

    // --- SENSOR FAILURES ---
    final sData = sensorProvider.latestData!;
    bool isSensorFail =
        sData.airTemp == -1 ||
        sData.waterTemp == -1 ||
        (sData.tdsPPM == 0 && sData.waterTemp > 0);
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
    final thresholds = plantProvider.currentThresholds;
    final phL = thresholds.phLimits; // [a, b, c, d]
    final tdsL = thresholds.tdsLimits; // [low, high]

    // =========================================================================
    // 1. FUZZIFIKASI INPUTS (Mencari Derajat Keanggotaan / µ)
    // =========================================================================
    // Catatan Akademis untuk Skripsi: 
    // Pernyataan 'if-else' di bawah ini BUKAN sebagai pengambil keputusan akhir aksi pompa,
    // melainkan representasi pemrograman dari Rumus Persamaan Garis Linier per bagian (Piecewise Linear Function)
    // untuk menentukan seberapa kuat nilai sensor berada di lereng grafik keanggotaan (bernilai 0.0 s.d. 1.0).

    // --- pH Fuzzification (Rendah/Normal/Tinggi) ---
    // pH Rendah (Asam)
    if (ph <= phL[0]) {
      muPhRendah = 1;
    } else if (ph > phL[0] && ph < phL[1]) {
      muPhRendah = (phL[1] - ph) / (phL[1] - phL[0]);
    } else {
      muPhRendah = 0;
    }

    // pH Normal
    if (ph >= phL[1] && ph <= phL[2]) {
      muPhNormal = 1;
    } else if (ph > phL[0] && ph < phL[1]) {
      muPhNormal = (ph - phL[0]) / (phL[1] - phL[0]);
    } else if (ph > phL[2] && ph < phL[3]) {
      muPhNormal = (phL[3] - ph) / (phL[3] - phL[2]);
    } else {
      muPhNormal = 0;
    }

    // pH Tinggi (Basa)
    if (ph >= phL[3]) {
      muPhTinggi = 1;
    } else if (ph > phL[2] && ph < phL[3]) {
      muPhTinggi = (ph - phL[2]) / (phL[3] - phL[2]);
    } else {
      muPhTinggi = 0;
    }

    // --- TDS Fuzzification (Rendah/Normal/Tinggi) ---
    // TDS Rendah
    if (tds <= tdsL[0]) {
      muTdsRendah = 1;
    } else if (tds > tdsL[0] && tds < tdsL[1]) {
      muTdsRendah = (tdsL[1] - tds) / (tdsL[1] - tdsL[0]);
    } else {
      muTdsRendah = 0;
    }

    // TDS Normal
    if (tds > tdsL[0] && tds < tdsL[1]) {
      double mid = (tdsL[0] + tdsL[1]) / 2;
      if (tds <= mid) {
        muTdsNormal = (tds - tdsL[0]) / (mid - tdsL[0]);
      } else {
        muTdsNormal = (tdsL[1] - tds) / (tdsL[1] - mid);
      }
    } else {
      muTdsNormal = 0;
    }

    // TDS Tinggi
    if (tds >= tdsL[1]) {
      muTdsTinggi = 1;
    } else if (tds > (tdsL[0] + tdsL[1])/2 && tds < tdsL[1]) {
      double mid = (tdsL[0] + tdsL[1]) / 2;
      muTdsTinggi = (tds - mid) / (tdsL[1] - mid);
    } else {
      muTdsTinggi = 0;
    }

    // --- Suhu Air Fuzzification (Dingin/Normal/Panas) ---
    // Dikalibrasi khusus untuk iklim tropis rumah user di mana suhu air 28°C s.d. 31°C dianggap Normal/Optimal bagi tanaman.
    // Dingin (<24°C - 27°C)
    if (waterTemp <= 24) {
      muSuhuDingin = 1;
    } else if (waterTemp > 24 && waterTemp < 27) {
      muSuhuDingin = (27 - waterTemp) / (27 - 24);
    } else {
      muSuhuDingin = 0;
    }

    // Normal (Optimal: 24°C - 33°C, optimal rata di 27°C - 31°C)
    if (waterTemp >= 27 && waterTemp <= 31) {
      muSuhuNormal = 1;
    } else if (waterTemp > 24 && waterTemp < 27) {
      muSuhuNormal = (waterTemp - 24) / (27 - 24);
    } else if (waterTemp > 31 && waterTemp < 33) {
      muSuhuNormal = (33 - waterTemp) / (33 - 31);
    } else {
      muSuhuNormal = 0;
    }

    // Panas (>31°C - 33°C)
    if (waterTemp >= 33) {
      muSuhuPanas = 1;
    } else if (waterTemp > 31 && waterTemp < 33) {
      muSuhuPanas = (waterTemp - 31) / (33 - 31);
    } else {
      muSuhuPanas = 0;
    }

    // =========================================================================
    // 2. INFERENSI RULE MAMDANI (Mencari Firing Strength / α-Cut / Nilai Keaktifan Rule)
    // =========================================================================
    // Catatan Akademis untuk Skripsi:
    // Operator 'AND' dalam Logika Fuzzy diimplementasikan dengan mengambil nilai terkecil (fungsi MIN / _min).
    // Hasil dari '_min()' adalah 'Firing Strength' (contoh: nilai keaktifan 0.34 yang tampil di UI).
    // Angka tersebut mewakili derajat kebenaran seberapa kuat aturan tersebut berkontribusi pada keputusan output.

    // --- FUZZY SYSTEM 1: TDS & Suhu (Nutrient AB Mix) ---
    // R1: IF TDS Rendah AND Suhu Dingin -> AB Mix Sedang (Bobot Singleton 0.6)
    r1 = _min(muTdsRendah, muSuhuDingin);
    // R2: IF TDS Rendah AND Suhu Optimal -> AB Mix Tinggi (Bobot Singleton 1.0)
    r2 = _min(muTdsRendah, muSuhuNormal);
    // R3: IF TDS Rendah AND Suhu Panas -> AB Mix Rendah (Bobot Singleton 0.3)
    r3 = _min(muTdsRendah, muSuhuPanas);
    // R4: IF TDS Normal -> AB Mix Mati (Bobot 0)
    r4 = muTdsNormal;
    // R5: IF TDS Tinggi -> AB Mix Mati (Bobot 0)
    r5 = muTdsTinggi;

    // --- FUZZY SYSTEM 2: pH & Suhu (pH Down) ---
    // R6: IF pH Tinggi AND Suhu Dingin -> pH Down Sedang (Bobot Singleton 0.6)
    r6 = _min(muPhTinggi, muSuhuDingin);
    // R7: IF pH Tinggi AND Suhu Optimal -> pH Down Tinggi (Bobot Singleton 1.0)
    r7 = _min(muPhTinggi, muSuhuNormal);
    // R8: IF pH Tinggi AND Suhu Panas -> pH Down Rendah (Bobot Singleton 0.4)
    r8 = _min(muPhTinggi, muSuhuPanas);
    // R9: IF pH Normal -> pH Down Mati (Bobot 0)
    r9 = muPhNormal;
    // R10: IF pH Rendah -> pH Down Mati (Bobot 0)
    r10 = muPhRendah;

    // =========================================================================
    // 3. DEFUZZIFIKASI (Weighted Average / Rata-rata Terbobot)
    // =========================================================================
    // Catatan Akademis untuk Skripsi:
    // Metode Defuzzifikasi yang digunakan adalah Weighted Average (Rata-rata Terbobot) dengan fungsi keanggotaan output
    // berbentuk Singleton (konstan). Metode ini terbukti ekuivalen secara matematis dengan metode Mamdani klasik, 
    // namun jauh lebih ringan dan efisien secara komputasi untuk dijalankan pada aplikasi mobile & IoT mikrokontroler.
    
    // Fuzzy 1 AB Mix Scale Output (Skala 0.0 s.d. 1.0)
    double sumAB = r1 + r2 + r3 + r4 + r5;
    double scaleAB = 0.0;
    if (sumAB > 0) {
      scaleAB = (r1 * 0.6 + r2 * 1.0 + r3 * 0.3 + r4 * 0.0 + r5 * 0.0) / sumAB;
    }
    outputPompaTDS = scaleAB * 100.0; 

    // Fuzzy 2 pH Down Scale Output (Skala 0.0 s.d. 1.0)
    double sumPH = r6 + r7 + r8 + r9 + r10;
    double scalePH = 0.0;
    if (sumPH > 0) {
      scalePH = (r6 * 0.6 + r7 * 1.0 + r8 * 0.4 + r9 * 0.0 + r10 * 0.0) / sumPH;
    }
    outputPompaPH = scalePH * 100.0; 

    // ===================================
    // 4. FISIKA DOSIS & RUMUS BAK (1x1 meter)
    // ===================================
    
    // Volume Air = 100 cm * 100 cm * H cm / 1000 = 10 * H Liters
    double volAirLiters = 10.0 * ketinggianAir;

    // A. AB Mix dosage calculation (TDS) - Dosis dinaikkan ke batas atas optimal (tdsL[1])
    double tdsTarget = tdsL[1];
    double deltaTDS = (tdsTarget - tds).clamp(0.0, double.infinity);
    // Asumsi: 1 mL AB Mix per Liter menaikkan TDS sebesar 100 PPM -> abMixNeeded (mL) = deltaTDS * volAir / 100.0
    abMixNeededML = (deltaTDS * volAirLiters) / 100.0;
    double maxDurationTDS = abMixNeededML / peristalticFlowRate; 
    recommendedPompaTDSSeconds = scaleAB * maxDurationTDS;

    // B. pH Down dosage calculation (pH) - Dosis diturunkan ke batas atas normal (phL[2])
    double phTarget = phL[2];
    double deltaPH = (ph - phTarget).clamp(0.0, double.infinity);
    // Asumsi: 0.1 mL pH Down per Liter menurunkan pH sebesar 1.0 unit -> phDownNeeded (mL) = deltaPH * volAir * 0.1
    phDownNeededML = deltaPH * volAirLiters * 0.1;
    double maxDurationPH = phDownNeededML / peristalticFlowRate; 
    recommendedPompaPHSeconds = scalePH * maxDurationPH;

    // ===================================
    // 5. KEPUTUSAN & REKOMENDASI
    // ===================================
    pompaAktif = recommendedPompaTDSSeconds > 0.5 || recommendedPompaPHSeconds > 0.5;

    if (recommendedPompaTDSSeconds > 0.5 && recommendedPompaPHSeconds > 0.5) {
      rekomendasi = "AB Mix: ${recommendedPompaTDSSeconds.toStringAsFixed(1)}s, pH Down: ${recommendedPompaPHSeconds.toStringAsFixed(1)}s";
    } else if (recommendedPompaTDSSeconds > 0.5) {
      rekomendasi = "AB Mix: ${recommendedPompaTDSSeconds.toStringAsFixed(1)}s";
    } else if (recommendedPompaPHSeconds > 0.5) {
      rekomendasi = "pH Down: ${recommendedPompaPHSeconds.toStringAsFixed(1)}s";
    } else {
      rekomendasi = "Kondisi Optimal";
    }

    // ================= LOG REKOMENDASI =================
    if (rekomendasi != lastRekomendasi) {
      logRekomendasi.insert(0, {
        "title": rekomendasi,
        "desc": "pH: ${ph.toStringAsFixed(1)}, TDS: ${tds.toStringAsFixed(0)}, Suhu Air: ${waterTemp.toStringAsFixed(1)}°C, Vol: ${volAirLiters.toStringAsFixed(0)}L",
        "time": DateTime.now(),
      });

      if (logRekomendasi.length > 50) {
        logRekomendasi.removeLast();
      }

      lastRekomendasi = rekomendasi;
      _saveFuzzyLog();
    }

    // ================= MODE HANDLING =================
    if (!isFuzzyEnabled) {
      pompaAktif = false;
      // Tetap simpan nilai rekomendasi durasi agar tombol Dosis Manual di UI bisa bekerja!
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
