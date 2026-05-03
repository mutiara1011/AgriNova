class TdsPoint {
  final double tdsManual;
  final double tdsSensor;

  TdsPoint({required this.tdsManual, required this.tdsSensor});

  factory TdsPoint.fromJson(Map<String, dynamic> json) {
    return TdsPoint(
      tdsManual: (json['tdsManual'] ?? 0.0).toDouble(),
      tdsSensor: (json['tdsSensor'] ?? 0.0).toDouble(),
    );
  }
}

class CalibrationData {
  final double waterTempOffset;
  final List<TdsPoint> tdsPoints;
  final bool liveMode;
  final bool muteBuzzer;

  CalibrationData({
    required this.waterTempOffset,
    required this.tdsPoints,
    required this.liveMode,
    required this.muteBuzzer,
  });

  factory CalibrationData.fromJson(Map<String, dynamic> json) {
    var list = json['tdsPoints'] as List? ?? [];
    List<TdsPoint> pointsList = list.map((i) => TdsPoint.fromJson(i)).toList();

    return CalibrationData(
      waterTempOffset: (json['waterTempOffset'] ?? 0.0).toDouble(),
      tdsPoints: pointsList,
      liveMode: json['liveMode'] ?? false,
      muteBuzzer: json['muteBuzzer'] ?? false,
    );
  }
}
