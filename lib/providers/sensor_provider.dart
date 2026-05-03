import 'dart:async';
import 'package:flutter/material.dart';
import 'package:agrinova/services/api_service.dart';
import 'package:agrinova/models/sensor_data.dart';

class SensorProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  SensorData? _latestData;
  SensorData? get latestData => _latestData;
  
  List<SensorData> _historyData = [];
  List<SensorData> get historyData => _historyData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Timer? _timer;
  bool _isLiveMode = false;

  SensorProvider() {
    startPolling();
  }

  void setLiveMode(bool isLive) {
    if (_isLiveMode != isLive) {
      _isLiveMode = isLive;
      startPolling(); // Restart timer with new interval
    }
  }

  void startPolling() {
    _timer?.cancel();
    fetchLatestData(); // Fetch immediately
    
    final interval = _isLiveMode ? const Duration(seconds: 5) : const Duration(minutes: 10);
    _timer = Timer.periodic(interval, (_) {
      fetchLatestData();
    });
  }

  Future<void> fetchLatestData() async {
    final newData = await _apiService.getLatestSensorData();
    if (newData != null) {
      _latestData = newData;
      
      // Prevent duplicate if history already has it or just append
      _historyData.add(newData);
      if (_historyData.length > 30) {
        _historyData.removeAt(0); // keep last 30
      }

      if (_latestData!.isRealtime != _isLiveMode) {
        _isLiveMode = _latestData!.isRealtime;
        _timer?.cancel();
        final interval = _isLiveMode ? const Duration(seconds: 5) : const Duration(minutes: 10);
        _timer = Timer.periodic(interval, (_) {
          fetchLatestData();
        });
      }
    }
    notifyListeners();
  }

  Future<void> fetchHistoryData({int page = 1, int limit = 20}) async {
    _isLoading = true;
    notifyListeners();
    
    final fetched = await _apiService.getSensorHistory(page: page, limit: limit);
    _historyData = fetched.reversed.toList(); // Asumsi API mengembalikan data terbaru di awal
    
    _isLoading = false;
    notifyListeners();
  }

  List<SensorData> _analysisData = [];
  List<SensorData> get analysisData => _analysisData;
  
  Map<String, dynamic> _analysisStats = {};
  Map<String, dynamic> get analysisStats => _analysisStats;

  Future<void> fetchAnalysisData({String timeRange = '1d', String? endDate}) async {
    _isLoading = true;
    notifyListeners();
    
    final res = await _apiService.getSensorAnalysis(timeRange: timeRange, endDate: endDate);
    if (res['success'] == true) {
      final data = res['data'] ?? {};
      final chartList = (data['chartData'] ?? []) as List;
      _analysisData = chartList.map((i) => SensorData.fromJson(i)).toList();
      _analysisStats = data['stats'] ?? {};
    }
    
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
