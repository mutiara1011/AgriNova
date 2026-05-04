import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/calibration_data.dart';

class CalibrationProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  CalibrationData? _calibrationData;
  CalibrationData? get calibrationData => _calibrationData;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchCalibrationData({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }
    
    _calibrationData = await _apiService.getCalibrationData();
    
    if (showLoading) {
      _isLoading = false;
    }
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

  Future<bool> toggleLiveMode(bool newVal) async {
    _isLoading = true;
    notifyListeners();
    final success = await _apiService.toggleLiveMode(newVal);
    if (success) {
      await fetchCalibrationData();
    } else {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  Future<bool> toggleMuteBuzzer(bool newVal) async {
    _isLoading = true;
    notifyListeners();
    final success = await _apiService.toggleMuteBuzzer(newVal);
    if (success) {
      await fetchCalibrationData();
    } else {
      _isLoading = false;
      notifyListeners();
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
