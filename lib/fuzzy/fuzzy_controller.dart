import 'package:flutter/material.dart';
import '../dummy_data.dart';
import '../notification/notification_controller.dart';
import '../notification/notification_model.dart';

class FuzzyController extends ChangeNotifier {
  final NotificationController notificationController;

  FuzzyController(this.notificationController);
  // SENSOR (dummy)
  double ph = 6.2;
  double tds = 800;

  // MODE
  bool autoMode = true;

  bool airKritisSent = false;
  bool phWarningSent = false;

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

  void updateFromSensor() {
    DummyData.update();

    ph = DummyData.ph;
    tds = DummyData.tds;

    evaluateFuzzy();

    if (DummyData.ketinggianAir < 9 && !airKritisSent) {
      notificationController.addNotification(
        "Air Kritis",
        "Segera isi tangki!",
        NotificationType.warning,
      );
      airKritisSent = true;
    }

    if (DummyData.ketinggianAir >= 9) {
      airKritisSent = false;
    }

    if ((DummyData.ph < 5.8 || DummyData.ph > 7.2) && !phWarningSent) {
      notificationController.addNotification(
        "pH Tidak Normal",
        "Nilai pH di luar batas ideal",
        NotificationType.warning,
      );
      phWarningSent = true;
    }

    if (DummyData.ph >= 5.8 && DummyData.ph <= 7.2) {
      phWarningSent = false;
    }
  }

  void evaluateFuzzy() {
    if (!autoMode) return;

    // =====================
    // 1. FUZZIFIKASI pH
    // =====================

    // pH Rendah
    if (ph <= 5.5) {
      muPhRendah = 1;
    } else if (ph > 5.5 && ph < 6.5) {
      muPhRendah = (6.5 - ph) / 1;
    } else {
      muPhRendah = 0;
    }

    // pH Normal
    if (ph >= 6 && ph <= 7) {
      muPhNormal = (ph - 6) / 1;
    } else if (ph > 7 && ph <= 8) {
      muPhNormal = (8 - ph) / 1;
    } else {
      muPhNormal = 0;
    }

    // pH Tinggi
    if (ph >= 7.5 && ph <= 8.5) {
      muPhTinggi = (ph - 7.5) / 1;
    } else if (ph > 8.5) {
      muPhTinggi = 1;
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

    kipasAktif = ph > 7;
    aeratorAktif = true;

    notifyListeners();
  }

  void setAutoMode(bool value) {
    autoMode = value;

    if (autoMode) {
      // Kalau ON → hitung fuzzy
      evaluateFuzzy();
    }

    notifyListeners();
  }

  void setPompaManual(bool value) {
    pompaAktif = value;
    notifyListeners();
  }

  void setKipasManual(bool value) {
    kipasAktif = value;
    notifyListeners();
  }

  void setAeratorManual(bool value) {
    aeratorAktif = value;
    notifyListeners();
  }
}
