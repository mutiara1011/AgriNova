class SensorData {
  final String deviceId;
  final double airTemp;
  final double airHumidity;
  final double waterTemp;
  final double lightLux;
  final double tdsPPM;
  final double phValue;
  final bool isRealtime;
  final int systemState;
  final DateTime? createdAt;

  SensorData({
    required this.deviceId,
    required this.airTemp,
    required this.airHumidity,
    required this.waterTemp,
    required this.lightLux,
    required this.tdsPPM,
    required this.phValue,
    required this.isRealtime,
    required this.systemState,
    this.createdAt,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      deviceId: json['deviceId'] ?? '',
      airTemp: (json['airTemp'] ?? 0.0).toDouble(),
      airHumidity: (json['airHumidity'] ?? 0.0).toDouble(),
      waterTemp: (json['waterTemp'] ?? 0.0).toDouble(),
      lightLux: (json['lightLux'] ?? 0.0).toDouble(),
      tdsPPM: (json['tdsPPM'] ?? 0.0).toDouble(),
      phValue: (json['phValue'] ?? 0.0).toDouble(),
      isRealtime: json['isRealtime'] ?? false,
      systemState: json['systemState'] ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'])?.toLocal() 
          : (json['time'] != null 
              ? DateTime.tryParse(json['time'])?.toLocal() 
              : (json['timestamp'] != null 
                  ? DateTime.tryParse(json['timestamp'])?.toLocal() 
                  : null)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'airTemp': airTemp,
      'airHumidity': airHumidity,
      'waterTemp': waterTemp,
      'lightLux': lightLux,
      'tdsPPM': tdsPPM,
      'phValue': phValue,
      'isRealtime': isRealtime,
      'systemState': systemState,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

