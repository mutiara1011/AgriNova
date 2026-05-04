import 'dart:convert';
import 'package:agrinova/models/sensor_data.dart';

class PlantCycle {
  final String id;
  final String name; // Kangkung, Pakcoy, Selada Keriting
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double targetPhMin;
  final double targetPhMax;
  final double targetTdsMin;
  final double targetTdsMax;
  final List<SensorData> historyData; // To store history when cycle ends

  PlantCycle({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.targetPhMin,
    required this.targetPhMax,
    required this.targetTdsMin,
    required this.targetTdsMax,
    this.historyData = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'isActive': isActive,
        'targetPhMin': targetPhMin,
        'targetPhMax': targetPhMax,
        'targetTdsMin': targetTdsMin,
        'targetTdsMax': targetTdsMax,
        'historyData': historyData.map((e) => e.toJson()).toList(),
      };

  factory PlantCycle.fromJson(Map<String, dynamic> json) {
    return PlantCycle(
      id: json['id'],
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'],
      targetPhMin: json['targetPhMin']?.toDouble() ?? 5.5,
      targetPhMax: json['targetPhMax']?.toDouble() ?? 6.5,
      targetTdsMin: json['targetTdsMin']?.toDouble() ?? 500,
      targetTdsMax: json['targetTdsMax']?.toDouble() ?? 1000,
      historyData: json['historyData'] != null ? (json['historyData'] as List).map((e) => SensorData.fromJson(e)).toList() : [],
    );
  }

  PlantCycle copyWith({
    String? id,
    String? name,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    double? targetPhMin,
    double? targetPhMax,
    double? targetTdsMin,
    double? targetTdsMax,
    List<SensorData>? historyData,
  }) {
    return PlantCycle(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      targetPhMin: targetPhMin ?? this.targetPhMin,
      targetPhMax: targetPhMax ?? this.targetPhMax,
      targetTdsMin: targetTdsMin ?? this.targetTdsMin,
      targetTdsMax: targetTdsMax ?? this.targetTdsMax,
      historyData: historyData ?? this.historyData,
    );
  }

  int get hst => DateTime.now().difference(startDate).inDays + 1;
}
