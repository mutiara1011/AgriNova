import 'package:agrinova/models/sensor_data.dart';

class PlantCycle {
  final String id;
  final String name; // Kangkung, Pakcoy, Selada Keriting
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final double targetPhMin;
  final double targetPhMax;
  final double targetTdsVegetatifMin;
  final double targetTdsVegetatifMax;
  final double targetTdsPembesaranMin;
  final double targetTdsPembesaranMax;
  final int harvestDays;
  final List<SensorData> historyData; // To store history when cycle ends

  PlantCycle({
    required this.id,
    required this.name,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    required this.targetPhMin,
    required this.targetPhMax,
    required this.targetTdsVegetatifMin,
    required this.targetTdsVegetatifMax,
    required this.targetTdsPembesaranMin,
    required this.targetTdsPembesaranMax,
    this.harvestDays = 30,
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
    'targetTdsVegetatifMin': targetTdsVegetatifMin,
    'targetTdsVegetatifMax': targetTdsVegetatifMax,
    'targetTdsPembesaranMin': targetTdsPembesaranMin,
    'targetTdsPembesaranMax': targetTdsPembesaranMax,
    'harvestDays': harvestDays,
    'historyData': historyData.map((e) => e.toJson()).toList(),
  };

  factory PlantCycle.fromJson(Map<String, dynamic> json) {
    return PlantCycle(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'],
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'],
      targetPhMin: json['targetPhMin']?.toDouble() ?? 5.5,
      targetPhMax: json['targetPhMax']?.toDouble() ?? 6.5,
      targetTdsVegetatifMin: json['targetTdsVegetatifMin']?.toDouble() ?? 500,
      targetTdsVegetatifMax: json['targetTdsVegetatifMax']?.toDouble() ?? 800,
      targetTdsPembesaranMin: json['targetTdsPembesaranMin']?.toDouble() ?? 800,
      targetTdsPembesaranMax:
          json['targetTdsPembesaranMax']?.toDouble() ?? 1200,
      harvestDays: json['harvestDays'] ?? 30,
      historyData: json['historyData'] != null
          ? (json['historyData'] as List)
                .map((e) => SensorData.fromJson(e))
                .toList()
          : [],
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
    double? targetTdsVegetatifMin,
    double? targetTdsVegetatifMax,
    double? targetTdsPembesaranMin,
    double? targetTdsPembesaranMax,
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
      targetTdsVegetatifMin:
          targetTdsVegetatifMin ?? this.targetTdsVegetatifMin,
      targetTdsVegetatifMax:
          targetTdsVegetatifMax ?? this.targetTdsVegetatifMax,
      targetTdsPembesaranMin:
          targetTdsPembesaranMin ?? this.targetTdsPembesaranMin,
      targetTdsPembesaranMax:
          targetTdsPembesaranMax ?? this.targetTdsPembesaranMax,
      historyData: historyData ?? this.historyData,
    );
  }

  int get hst => DateTime.now().difference(startDate).inDays + 1;
}
