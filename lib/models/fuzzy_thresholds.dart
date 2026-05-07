class FuzzyThresholds {
  final List<double> phLimits; // [a, b, c, d] for Trapezoid Normal
  final List<double> tdsLimits; // [low, high] for Shoulder Cross

  FuzzyThresholds({
    required this.phLimits,
    required this.tdsLimits,
  });

  // PH: Asam (<= a), Normal (a-d, peak b-c), Basa (>= d)
  // TDS: Rendah (<= low), Tinggi (>= high)
}
