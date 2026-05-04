import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/plant_cycle.dart';
import '../models/sensor_data.dart';

class PlantProvider extends ChangeNotifier {
  static const String _activePlantKey = 'active_plant';
  static const String _plantHistoryKey = 'plant_history';

  PlantCycle? _activePlant;
  List<PlantCycle> _historyCycles = [];

  PlantCycle? get activePlant => _activePlant;
  List<PlantCycle> get historyCycles => _historyCycles;
  bool get hasActivePlant => _activePlant != null && _activePlant!.isActive;

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Active Plant
    final activeStr = prefs.getString(_activePlantKey);
    if (activeStr != null) {
      _activePlant = PlantCycle.fromJson(jsonDecode(activeStr));
    }

    // Load History
    final historyStr = prefs.getString(_plantHistoryKey);
    if (historyStr != null) {
      final List decoded = jsonDecode(historyStr);
      _historyCycles = decoded.map((e) => PlantCycle.fromJson(e)).toList();
    }
    
    notifyListeners();
  }

  Future<void> startNewCycle({required String name, required DateTime startDate}) async {
    double minPh = 5.5, maxPh = 6.5, minTds = 500, maxTds = 1000;
    
    if (name.toLowerCase().contains("kangkung")) {
      minPh = 5.5; maxPh = 6.5; minTds = 1000; maxTds = 1400;
    } else if (name.toLowerCase().contains("pakcoy")) {
      minPh = 6.0; maxPh = 7.0; minTds = 1050; maxTds = 1400;
    } else if (name.toLowerCase().contains("selada")) {
      minPh = 5.5; maxPh = 6.5; minTds = 560; maxTds = 840;
    }

    final newCycle = PlantCycle(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      startDate: startDate,
      targetPhMin: minPh,
      targetPhMax: maxPh,
      targetTdsMin: minTds,
      targetTdsMax: maxTds,
    );

    _activePlant = newCycle;
    await _saveActivePlant();
    notifyListeners();
  }

  Future<void> endCycle(List<SensorData> currentHistoryData) async {
    if (_activePlant == null) return;

    final finishedCycle = _activePlant!.copyWith(
      isActive: false,
      endDate: DateTime.now(),
      historyData: currentHistoryData,
    );

    _historyCycles.add(finishedCycle);
    _activePlant = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activePlantKey);
    
    await _saveHistoryCycles();
    notifyListeners();
  }

  Future<void> _saveActivePlant() async {
    if (_activePlant == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activePlantKey, jsonEncode(_activePlant!.toJson()));
  }

  Future<void> _saveHistoryCycles() async {
    final prefs = await SharedPreferences.getInstance();
    final list = _historyCycles.map((e) => e.toJson()).toList();
    await prefs.setString(_plantHistoryKey, jsonEncode(list));
  }
}
