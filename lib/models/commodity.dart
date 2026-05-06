class Commodity {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final bool isCustom;
  final double phMin;
  final double phMax;
  final String phIdeal;
  final double tdsVegetatifMin;
  final double tdsVegetatifMax;
  final String tdsVegetatifIdeal;
  final double tdsPembesaranMin;
  final double tdsPembesaranMax;
  final String tdsPembesaranIdeal;
  final double airTempMin;
  final double airTempMax;
  final String airTempIdeal;
  final double waterTempMin;
  final double waterTempMax;
  final String waterTempIdeal;
  final double humidityMin;
  final double humidityMax;
  final String humidityIdeal;
  final int harvestDays;
  final int harvestRange;

  Commodity({
    required this.id,
    required this.name,
    this.description = "",
    this.imagePath = "",
    this.isCustom = false,
    this.phMin = 5.5,
    this.phMax = 6.5,
    this.phIdeal = "6.0",
    this.tdsVegetatifMin = 500,
    this.tdsVegetatifMax = 800,
    this.tdsVegetatifIdeal = "700",
    this.tdsPembesaranMin = 800,
    this.tdsPembesaranMax = 1200,
    this.tdsPembesaranIdeal = "1000",
    this.airTempMin = 20,
    this.airTempMax = 30,
    this.airTempIdeal = "25",
    this.waterTempMin = 18,
    this.waterTempMax = 25,
    this.waterTempIdeal = "22",
    this.humidityMin = 50,
    this.humidityMax = 80,
    this.humidityIdeal = "65",
    this.harvestDays = 30,
    this.harvestRange = 5,
  });

  factory Commodity.fromJson(Map<String, dynamic> json) {
    return Commodity(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imagePath: json['imagePath'] ?? '',
      isCustom: json['isCustom'] ?? false,
      phMin: (json['phMin'] ?? 5.5).toDouble(),
      phMax: (json['phMax'] ?? 6.5).toDouble(),
      phIdeal: json['phIdeal'] ?? "6.0",
      tdsVegetatifMin: (json['tdsVegetatifMin'] ?? 500).toDouble(),
      tdsVegetatifMax: (json['tdsVegetatifMax'] ?? 800).toDouble(),
      tdsVegetatifIdeal: json['tdsVegetatifIdeal'] ?? "700",
      tdsPembesaranMin: (json['tdsPembesaranMin'] ?? 800).toDouble(),
      tdsPembesaranMax: (json['tdsPembesaranMax'] ?? 1200).toDouble(),
      tdsPembesaranIdeal: json['tdsPembesaranIdeal'] ?? "1000",
      airTempMin: (json['airTempMin'] ?? 20).toDouble(),
      airTempMax: (json['airTempMax'] ?? 30).toDouble(),
      airTempIdeal: json['airTempIdeal'] ?? "25",
      waterTempMin: (json['waterTempMin'] ?? 18).toDouble(),
      waterTempMax: (json['waterTempMax'] ?? 25).toDouble(),
      waterTempIdeal: json['waterTempIdeal'] ?? "22",
      humidityMin: (json['humidityMin'] ?? 50).toDouble(),
      humidityMax: (json['humidityMax'] ?? 80).toDouble(),
      humidityIdeal: json['humidityIdeal'] ?? "65",
      harvestDays: json['harvestDays'] ?? 30,
      harvestRange: json['harvestRange'] ?? 5,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imagePath': imagePath,
      'isCustom': isCustom,
      'phMin': phMin,
      'phMax': phMax,
      'phIdeal': phIdeal,
      'tdsVegetatifMin': tdsVegetatifMin,
      'tdsVegetatifMax': tdsVegetatifMax,
      'tdsVegetatifIdeal': tdsVegetatifIdeal,
      'tdsPembesaranMin': tdsPembesaranMin,
      'tdsPembesaranMax': tdsPembesaranMax,
      'tdsPembesaranIdeal': tdsPembesaranIdeal,
      'airTempMin': airTempMin,
      'airTempMax': airTempMax,
      'airTempIdeal': airTempIdeal,
      'waterTempMin': waterTempMin,
      'waterTempMax': waterTempMax,
      'waterTempIdeal': waterTempIdeal,
      'humidityMin': humidityMin,
      'humidityMax': humidityMax,
      'humidityIdeal': humidityIdeal,
      'harvestDays': harvestDays,
      'harvestRange': harvestRange,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Commodity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
