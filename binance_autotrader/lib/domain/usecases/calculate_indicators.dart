import 'dart:math' as math;
import '../entities/candle.dart';

class MACDResult {
  final List<double> macdLine;
  final List<double> signalLine;
  final List<double> histogram;

  const MACDResult({
    required this.macdLine,
    required this.signalLine,
    required this.histogram,
  });

  double get lastMacd => macdLine.isNotEmpty ? macdLine.last : 0.0;
  double get lastSignal => signalLine.isNotEmpty ? signalLine.last : 0.0;
  double get lastHistogram => histogram.isNotEmpty ? histogram.last : 0.0;

  double get prevHistogram =>
      histogram.length >= 2 ? histogram[histogram.length - 2] : 0.0;
}

class BBResult {
  final List<double> upper;
  final List<double> middle;
  final List<double> lower;

  const BBResult({
    required this.upper,
    required this.middle,
    required this.lower,
  });

  double get lastUpper => upper.isNotEmpty ? upper.last : 0.0;
  double get lastMiddle => middle.isNotEmpty ? middle.last : 0.0;
  double get lastLower => lower.isNotEmpty ? lower.last : 0.0;
}

List<double> calculateEma(List<double> closes, int period) {
  if (closes.length < period) {
    return List.filled(closes.length, double.nan);
  }

  final result = List<double>.filled(closes.length, double.nan);
  final k = 2.0 / (period + 1);

  double sum = 0;
  for (int i = 0; i < period; i++) {
    sum += closes[i];
  }
  result[period - 1] = sum / period;

  for (int i = period; i < closes.length; i++) {
    result[i] = closes[i] * k + result[i - 1] * (1 - k);
  }

  return result;
}

MACDResult calculateMacd(
  List<double> closes, {
  int fast = 12,
  int slow = 26,
  int signal = 9,
}) {
  final fastEma = calculateEma(closes, fast);
  final slowEma = calculateEma(closes, slow);

  final macdLine = List<double>.filled(closes.length, double.nan);
  for (int i = slow - 1; i < closes.length; i++) {
    if (!fastEma[i].isNaN && !slowEma[i].isNaN) {
      macdLine[i] = fastEma[i] - slowEma[i];
    }
  }

  final validMacd = macdLine.where((v) => !v.isNaN).toList();
  List<double> signalEma = [];
  if (validMacd.length >= signal) {
    signalEma = calculateEma(validMacd, signal);
  }

  final signalLine = List<double>.filled(closes.length, double.nan);
  final histogramLine = List<double>.filled(closes.length, double.nan);

  int validIdx = 0;
  for (int i = 0; i < closes.length; i++) {
    if (!macdLine[i].isNaN) {
      if (validIdx < signalEma.length && !signalEma[validIdx].isNaN) {
        signalLine[i] = signalEma[validIdx];
        histogramLine[i] = macdLine[i] - signalEma[validIdx];
      }
      validIdx++;
    }
  }

  return MACDResult(
    macdLine: macdLine,
    signalLine: signalLine,
    histogram: histogramLine,
  );
}

List<double> calculateRsi(List<double> closes, int period) {
  if (closes.length <= period) {
    return List.filled(closes.length, double.nan);
  }

  final result = List<double>.filled(closes.length, double.nan);
  double avgGain = 0;
  double avgLoss = 0;

  for (int i = 1; i <= period; i++) {
    final diff = closes[i] - closes[i - 1];
    if (diff > 0) {
      avgGain += diff;
    } else {
      avgLoss += diff.abs();
    }
  }
  avgGain /= period;
  avgLoss /= period;

  if (avgLoss == 0) {
    result[period] = 100.0;
  } else {
    final rs = avgGain / avgLoss;
    result[period] = 100 - (100 / (1 + rs));
  }

  for (int i = period + 1; i < closes.length; i++) {
    final diff = closes[i] - closes[i - 1];
    final gain = diff > 0 ? diff : 0.0;
    final loss = diff < 0 ? diff.abs() : 0.0;

    avgGain = (avgGain * (period - 1) + gain) / period;
    avgLoss = (avgLoss * (period - 1) + loss) / period;

    if (avgLoss == 0) {
      result[i] = 100.0;
    } else {
      final rs = avgGain / avgLoss;
      result[i] = 100 - (100 / (1 + rs));
    }
  }

  return result;
}

BBResult calculateBollingerBands(
  List<double> closes,
  int period,
  double stdDevMult,
) {
  if (closes.length < period) {
    return BBResult(
      upper: List.filled(closes.length, double.nan),
      middle: List.filled(closes.length, double.nan),
      lower: List.filled(closes.length, double.nan),
    );
  }

  final upper = List<double>.filled(closes.length, double.nan);
  final middle = List<double>.filled(closes.length, double.nan);
  final lower = List<double>.filled(closes.length, double.nan);

  for (int i = period - 1; i < closes.length; i++) {
    final slice = closes.sublist(i - period + 1, i + 1);
    final sma = slice.reduce((a, b) => a + b) / period;
    final variance =
        slice.map((v) => math.pow(v - sma, 2)).reduce((a, b) => a + b) / period;
    final stdDev = math.sqrt(variance);

    middle[i] = sma;
    upper[i] = sma + stdDevMult * stdDev;
    lower[i] = sma - stdDevMult * stdDev;
  }

  return BBResult(upper: upper, middle: middle, lower: lower);
}

List<double> calculateAtr(List<Candle> candles, int period) {
  if (candles.length < period + 1) {
    return List.filled(candles.length, double.nan);
  }

  final trueRanges = List<double>.filled(candles.length, 0.0);
  for (int i = 1; i < candles.length; i++) {
    final hl = candles[i].high - candles[i].low;
    final hpc = (candles[i].high - candles[i - 1].close).abs();
    final lpc = (candles[i].low - candles[i - 1].close).abs();
    trueRanges[i] = math.max(hl, math.max(hpc, lpc));
  }

  final result = List<double>.filled(candles.length, double.nan);
  double atrSum = 0;
  for (int i = 1; i <= period; i++) {
    atrSum += trueRanges[i];
  }
  result[period] = atrSum / period;

  for (int i = period + 1; i < candles.length; i++) {
    result[i] = (result[i - 1] * (period - 1) + trueRanges[i]) / period;
  }

  return result;
}

double lastValidValue(List<double> values) {
  for (int i = values.length - 1; i >= 0; i--) {
    if (!values[i].isNaN) return values[i];
  }
  return double.nan;
}
