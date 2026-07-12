class FuzzyThresholds {
  final List<double> phLimits; // [a, b, c, d] for Trapezoid Normal
  final List<double> tdsLimits; // [low, high] for Shoulder Cross
  final List<double> tempLimits; // [tempMin, tempMax] for dynamic Suhu Air

  FuzzyThresholds({
    required this.phLimits,
    required this.tdsLimits,
    this.tempLimits = const [18, 30], // Default: Kangkung/Sawi
  });

  // PH: Asam (<= a), Normal (a-d, peak b-c), Basa (>= d)
  // TDS: Rendah (<= low), Tinggi (>= high)
  // Suhu: Dingin (<= tempMin-3), Normal (tempMin-tempMax), Panas (>= tempMax+3)
}
