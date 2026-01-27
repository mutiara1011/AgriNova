import 'package:flutter/material.dart';

class FuzzyController extends ChangeNotifier {
  // SENSOR (dummy)
  double ph = 6.2;
  double tds = 800;

  // MODE
  bool autoMode = true;

  // OUTPUT FUZZY
  bool pompaAktif = false;
  bool kipasAktif = false;
  bool aeratorAktif = false;
  String rekomendasi = 'Tidak diperlukan tindakan';

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
