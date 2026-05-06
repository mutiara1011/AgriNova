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
  bool get isLiveMode => _isLiveMode;

  // Waktu lokal terakhir data berhasil diambil
  DateTime? _lastFetchedAt;
  DateTime? get lastFetchedAt => _lastFetchedAt;

  SensorProvider() {
    _init();
  }

  Future<void> _init() async {
    // Fetch initial data immediately
    await fetchLatestData();
    
    // Then check calibration status to determine polling interval
    try {
      final calib = await _apiService.getCalibrationData();
      if (calib != null) {
        _isLiveMode = calib.liveModeActive;
      }
    } catch (e) {
      // ignore - default to normal mode
    }
    
    // Start polling with the correct interval
    _startPollingTimer();
  }

  void setLiveMode(bool isLive) {
    if (_isLiveMode != isLive) {
      _isLiveMode = isLive;
      _startPollingTimer();
    }
  }

  void _startPollingTimer() {
    _timer?.cancel();
    final interval = _isLiveMode ? const Duration(seconds: 5) : const Duration(minutes: 10);
    _timer = Timer.periodic(interval, (_) {
      fetchLatestData();
    });
  }

  // Public method to force restart polling (e.g. after toggling live mode)
  void startPolling() {
    _startPollingTimer();
    fetchLatestData();
  }

  Future<void> fetchLatestData() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Add timestamp to bypass HTTP cache
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final newData = await _apiService.getLatestSensorData(t: timestamp);
      
      if (newData != null) {
        _latestData = newData;
        _lastFetchedAt = DateTime.now();
        
        // Simpan ke history agar grafik terupdate
        bool shouldStore = false;
        if (_historyData.isEmpty) {
          shouldStore = true;
        } else {
          final lastTime = _historyData.last.createdAt;
          final newTime = newData.createdAt;
          if (lastTime != null && newTime != null) {
            // Jika Live Mode: simpan setiap data baru (5 detik)
            // Jika Normal: simpan setiap 10 menit
            if (_isLiveMode) {
              if (newTime.isAfter(lastTime)) {
                shouldStore = true;
              }
            } else {
              if (newTime.difference(lastTime).inMinutes >= 10) {
                shouldStore = true;
              }
            }
          }
        }

        if (shouldStore) {
          _historyData.add(newData);
          // Simpan maksimal 100 data point agar grafik tetap lancar
          if (_historyData.length > 100) {
            _historyData.removeAt(0);
          }
        }

      }
    } finally {
      _isLoading = false;
      // Always notify so UI rebuilds (even if data unchanged, lastFetchedAt changed)
      notifyListeners();
    }
  }

  Future<void> fetchHistoryData({int page = 1, int limit = 50, DateTime? startDate, DateTime? endDate}) async {
    _isLoading = true;
    notifyListeners();

    
    final fetched = await _apiService.getSensorHistory(page: page, limit: limit);
    var list = fetched.reversed.toList();
    
    // Filter history based on active plant start date
    if (startDate != null) {
      list = list.where((data) => data.createdAt != null && !data.createdAt!.isBefore(startDate)).toList();
    }
    if (endDate != null) {
      list = list.where((data) => data.createdAt != null && !data.createdAt!.isAfter(endDate)).toList();
    }

    
    _historyData = list;
    
    _isLoading = false;
    notifyListeners();
  }


  List<SensorData> _analysisData = [];
  List<SensorData> get analysisData => _analysisData;
  
  Map<String, dynamic> _analysisStats = {};
  Map<String, dynamic> get analysisStats => _analysisStats;

  Future<void> fetchAnalysisData({String timeRange = '1d', String? endDate, DateTime? startDate}) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final res = await _apiService.getSensorAnalysis(timeRange: timeRange, endDate: endDate);
      if (res['success'] == true) {
        final data = res['data'] ?? {};
        final chartList = (data['chartData'] ?? []) as List;
        var list = chartList.map((i) => SensorData.fromJson(i)).toList();
        
        // Filter based on active plant start date
        if (startDate != null) {
          list = list.where((d) => d.createdAt != null && !d.createdAt!.isBefore(startDate)).toList();
        }
        
        _analysisData = list;
        _analysisStats = data['stats'] ?? {};
      }
    } finally {

      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
