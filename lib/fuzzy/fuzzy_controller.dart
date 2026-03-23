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

    // Rule Mamdani sederhana
    if (tds < 700) {
      pompaAktif = true;
      rekomendasi = 'Pompa nutrisi diaktifkan';
    } else {
      pompaAktif = false;
      rekomendasi = 'Tidak diperlukan tindakan';
    }

    kipasAktif = ph > 7.0;
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
