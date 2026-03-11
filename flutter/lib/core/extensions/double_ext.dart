extension DoubleExt on double {
  String toSignedString({int decimals = 2}) {
    if (isNaN || isInfinite) return '0.00';
    final formatted = abs().toStringAsFixed(decimals);
    return this >= 0 ? '+$formatted' : '-$formatted';
  }

  String toCurrencyString({int decimals = 2}) {
    if (isNaN || isInfinite) return '0.00';
    return toStringAsFixed(decimals);
  }

  String toPercentString({int decimals = 2}) {
    if (isNaN || isInfinite) return '0.00%';
    return '${toStringAsFixed(decimals)}%';
  }

  double clampToRange(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  bool get isValidPrice => !isNaN && !isInfinite && this > 0;
}

extension NullableDoubleExt on double? {
  double get orZero => this ?? 0.0;
}
