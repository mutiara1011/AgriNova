import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/calibration_data.dart';

class CalibrationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  CalibrationData? _calibrationData;
  CalibrationData? get calibrationData => _calibrationData;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchCalibrationData() async {
    _isLoading = true;
    notifyListeners();
    
    _calibrationData = await _apiService.getCalibrationData();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateCalibration(double waterTempManual, double waterTempSensor, double tdsManual, double tdsSensor) async {
    final success = await _apiService.updateCalibration(
      waterTempManual: waterTempManual,
      waterTempSensor: waterTempSensor,
      tdsManual: tdsManual,
      tdsSensor: tdsSensor,
    );
    if (success) {
      await fetchCalibrationData();
    }
    return success;
  }

  Future<bool> toggleLiveMode() async {
    final success = await _apiService.toggleLiveMode();
    if (success) {
      await fetchCalibrationData();
    }
    return success;
  }

  Future<bool> toggleMuteBuzzer() async {
    final success = await _apiService.toggleMuteBuzzer();
    if (success) {
      await fetchCalibrationData();
    }
    return success;
  }

  Future<bool> resetTdsPoints() async {
    final success = await _apiService.resetTdsPoints();
    if (success) {
      await fetchCalibrationData();
    }
    return success;
  }
}
