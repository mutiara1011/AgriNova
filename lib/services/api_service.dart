import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import '../models/calibration_data.dart';

class ApiService {
  static const String baseUrl = 'https://agrinova.devlabfortirta.cloud/api/v1';
  static const String deviceId = 'AgriNova-Node-01';

  // --- SENSORS API ---

  Future<SensorData?> getLatestSensorData({int? t}) async {
    try {
      var url = '$baseUrl/sensors/latest?deviceId=$deviceId';
      if (t != null) url += '&t=$t';
      
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return SensorData.fromJson(json['data'] ?? json);
      }
    } catch (e) {
      print('Error getLatestSensorData: $e');
    }
    return null;
  }

  Future<List<SensorData>> getSensorHistory({int page = 1, int limit = 20}) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/sensors/history?deviceId=$deviceId&page=$page&limit=$limit'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'] ?? {};
        final list = (data['readings'] ?? []) as List;
        return list.map((i) => SensorData.fromJson(i)).toList();
      }
    } catch (e) {
      print('Error getSensorHistory: $e');
    }
    return [];
  }

  Future<Map<String, dynamic>> getSensorAnalysis({String timeRange = '1d', String? endDate}) async {
    try {
      var url = '$baseUrl/sensors/analysis?deviceId=$deviceId&timeRange=$timeRange';
      if (endDate != null) url += '&endDate=$endDate';
      
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getSensorAnalysis: $e');
    }
    return {};
  }

  // --- CALIBRATION API ---

  Future<CalibrationData?> getCalibrationData() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/calibration?deviceId=$deviceId'))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return CalibrationData.fromJson(json['data'] ?? json);
      }
    } catch (e) {
      print('Error getCalibrationData: $e');
    }
    return null;
  }

  Future<bool> updateCalibration({required double waterTempManual, required double waterTempSensor, required double tdsManual, required double tdsSensor}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/calibration'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "deviceId": deviceId,
          "waterTempManual": waterTempManual,
          "waterTempSensor": waterTempSensor,
          "tdsManual": tdsManual,
          "tdsSensor": tdsSensor,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error updateCalibration: $e');
      return false;
    }
  }

  Future<bool> toggleLiveMode(bool liveModeActive) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/calibration/live-mode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "deviceId": deviceId,
          "liveModeActive": liveModeActive,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggleLiveMode: $e');
      return false;
    }
  }

  Future<bool> toggleMuteBuzzer(bool muteBuzzer) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/calibration/mute-buzzer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "deviceId": deviceId,
          "muteBuzzer": muteBuzzer,
        }),
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Error toggleMuteBuzzer: $e');
      return false;
    }
  }

  Future<bool> resetTdsPoints() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/calibration/tds-points?deviceId=$deviceId'), // Also passing deviceId just in case
      ).timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Error resetTdsPoints: $e');
      return false;
    }
  }
}
