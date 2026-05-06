import 'package:flutter/material.dart';
import '../models/plant_cycle.dart';
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
      print('Error loadData in PlantProvider: $e');
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
}
