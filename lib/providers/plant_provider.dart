import 'package:flutter/material.dart';
import '../models/fuzzy_thresholds.dart';
import 'package:agrinova/models/plant_cycle.dart';
import '../services/api_service.dart';

class PlantProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  PlantCycle? _activePlant;
  List<PlantCycle> _historyCycles = [];
  bool _isLoading = false;

  PlantCycle? get activePlant => _activePlant;
  List<PlantCycle> get historyCycles => _historyCycles;
  bool get hasActivePlant => _activePlant != null && _activePlant!.isActive;
  bool get isLoading => _isLoading;

  String get selectedPlant {
    if (_activePlant == null) return "Selada Keriting";
    return _activePlant!.name;
  }

  String get selectedPhase {
    if (_activePlant == null) return "Vegetatif";
    int hst = _activePlant!.hst;
    double transitionDay = _activePlant!.harvestDays * 0.6;
    return hst < transitionDay ? "Vegetatif" : "Pembesaran";
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Fetch Active Plant from API
      final activeData = await _apiService.getActivePlantCycle();
      if (activeData != null) {
        _activePlant = PlantCycle.fromJson(activeData);
      } else {
        _activePlant = null;
      }

      // 2. Fetch History from API
      final historyData = await _apiService.getPlantHistory();
      _historyCycles = historyData.map((e) => PlantCycle.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loadData in PlantProvider: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> startNewCycle({
    required String name,
    required DateTime startDate,
    required double targetPhMin,
    required double targetPhMax,
    required double targetTdsVegetatifMin,
    required double targetTdsVegetatifMax,
    required double targetTdsPembesaranMin,
    required double targetTdsPembesaranMax,
    required int harvestDays,
  }) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.startPlantCycle(
      name: name,
      startDate: startDate,
      targetPhMin: targetPhMin,
      targetPhMax: targetPhMax,
      targetTdsVegetatifMin: targetTdsVegetatifMin,
      targetTdsVegetatifMax: targetTdsVegetatifMax,
      targetTdsPembesaranMin: targetTdsPembesaranMin,
      targetTdsPembesaranMax: targetTdsPembesaranMax,
      harvestDays: harvestDays,
    );

    if (success) {
      await loadData(); // Reload to get the new active plant
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  Future<bool> endCycle({String notes = ""}) async {
    _isLoading = true;
    notifyListeners();

    final success = await _apiService.endPlantCycle(notes: notes);

    if (success) {
      _activePlant = null;
      await loadData(); // Reload history and status
    }

    _isLoading = false;
    notifyListeners();
    return success;
  }

  // --- FUZZY CONFIGURATION (Sync with Dashboard/Settings) ---
  FuzzyThresholds get currentThresholds {
    if (_activePlant == null) {
      // Default fallback if no active plant
      return FuzzyThresholds(
        phLimits: [5.5, 6.0, 7.0, 7.5],
        tdsLimits: [560, 700],
        tempLimits: [18, 30],
      );
    }

    // Dynamic thresholds derived from active plant cycle targets
    final p = _activePlant!;

    // pH: [AsamEnd, NormalStart, NormalEnd, BasaStart]
    // We use a 0.5 offset from the target range to create the trapezoid slopes
    double phMin = p.targetPhMin;
    double phMax = p.targetPhMax;
    List<double> phLimits = [phMin - 0.5, phMin, phMax, phMax + 0.5];

    // TDS: [RendahEnd, TinggiStart]
    // We use the target min and max to define the crossover region
    double tdsMin, tdsMax;
    if (selectedPhase == "Vegetatif") {
      tdsMin = p.targetTdsVegetatifMin;
      tdsMax = p.targetTdsVegetatifMax;
    } else {
      tdsMin = p.targetTdsPembesaranMin;
      tdsMax = p.targetTdsPembesaranMax;
    }

    // Adjusting to match the logic where 'Tinggi' starts at the ideal/upper bound
    // If the gap is too small, we use a default ratio
    if ((tdsMax - tdsMin) < 50) {
      tdsMin = tdsMax * 0.8;
    }
    List<double> tdsLimits = [tdsMin, tdsMax];

    // Suhu Air: Dinamis per komoditas (Sesuai Tabel 6 Skripsi)
    // Kangkung & Sawi: 18-30°C, Selada Keriting: 27-31°C
    List<double> tempLimits;
    final nameLower = p.name.toLowerCase();
    if (nameLower.contains('selada')) {
      tempLimits = [27, 31];
    } else {
      // Default untuk Kangkung, Sawi, dan komoditas lainnya
      tempLimits = [18, 30];
    }

    return FuzzyThresholds(
      phLimits: phLimits,
      tdsLimits: tdsLimits,
      tempLimits: tempLimits,
    );
  }
}
