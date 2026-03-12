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

// VSA pattern enum
enum VsaPattern {
  sellingClimax,
  buyingClimax,
  stoppingVolume,
  upthrust,
  spring,
  pseudoUpthrust,
  noSupply,
  noDemand,
  normal,
}

extension VsaPatternName on VsaPattern {
  String get label {
    switch (this) {
      case VsaPattern.sellingClimax: return 'Selling Climax';
      case VsaPattern.buyingClimax: return 'Buying Climax';
      case VsaPattern.stoppingVolume: return 'Stopping Volume';
      case VsaPattern.upthrust: return 'Upthrust';
      case VsaPattern.spring: return 'Spring';
      case VsaPattern.pseudoUpthrust: return 'Pseudo Upthrust';
      case VsaPattern.noSupply: return 'No Supply';
      case VsaPattern.noDemand: return 'No Demand';
      case VsaPattern.normal: return 'Normal';
    }
  }

  String get description {
    switch (this) {
      case VsaPattern.sellingClimax:
        return 'Extreme sell-off on very high volume, close near bottom — smart money absorbing, potential reversal up.';
      case VsaPattern.buyingClimax:
        return 'Euphoric buying on very high volume, close near top — distribution by smart money, potential reversal down.';
      case VsaPattern.stoppingVolume:
        return 'High volume on a down candle closing in the upper half — supply absorbed, bullish reversal likely.';
      case VsaPattern.upthrust:
        return 'High volume on an up candle closing in the lower half — false breakout, bearish.';
      case VsaPattern.spring:
        return 'Wide-spread down candle closing in the upper half — shakeout below support, likely reversal up.';
      case VsaPattern.pseudoUpthrust:
        return 'Wide-spread up candle with weak close — buying effort failed, bearish pressure remains.';
      case VsaPattern.noSupply:
        return 'Low volume, narrow spread, down candle — sellers absent, price likely to move higher.';
      case VsaPattern.noDemand:
        return 'Low volume, narrow spread, up candle — buyers absent, price likely to move lower.';
      case VsaPattern.normal:
        return 'No distinctive VSA pattern detected on this candle.';
    }
  }
}

class VsaResult {
  final VsaPattern pattern;
  final bool? bullish; // true=bullish, false=bearish, null=neutral
  final double volRatio;
  final double spreadRatio;
  final double closePos; // 0=bottom, 1=top

  const VsaResult({
    required this.pattern,
    required this.bullish,
    required this.volRatio,
    required this.spreadRatio,
    required this.closePos,
  });
}

// ---------- EMA ----------
List<double> calculateEma(List<double> closes, int period) {
  if (closes.length < period) {
    return List.filled(closes.length, double.nan);
  }
  final result = List<double>.filled(closes.length, double.nan);
  final k = 2.0 / (period + 1);
  double sum = 0;
  for (int i = 0; i < period; i++) sum += closes[i];
  result[period - 1] = sum / period;
  for (int i = period; i < closes.length; i++) {
    result[i] = closes[i] * k + result[i - 1] * (1 - k);
  }
  return result;
}

// ---------- MACD ----------
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
  return MACDResult(macdLine: macdLine, signalLine: signalLine, histogram: histogramLine);
}

// ---------- RSI ----------
List<double> calculateRsi(List<double> closes, int period) {
  if (closes.length <= period) return List.filled(closes.length, double.nan);
  final result = List<double>.filled(closes.length, double.nan);
  double avgGain = 0;
  double avgLoss = 0;
  for (int i = 1; i <= period; i++) {
    final diff = closes[i] - closes[i - 1];
    if (diff > 0) avgGain += diff; else avgLoss += diff.abs();
  }
  avgGain /= period;
  avgLoss /= period;
  result[period] = avgLoss == 0 ? 100.0 : 100 - (100 / (1 + avgGain / avgLoss));
  for (int i = period + 1; i < closes.length; i++) {
    final diff = closes[i] - closes[i - 1];
    final gain = diff > 0 ? diff : 0.0;
    final loss = diff < 0 ? diff.abs() : 0.0;
    avgGain = (avgGain * (period - 1) + gain) / period;
    avgLoss = (avgLoss * (period - 1) + loss) / period;
    result[i] = avgLoss == 0 ? 100.0 : 100 - (100 / (1 + avgGain / avgLoss));
  }
  return result;
}

// ---------- Bollinger Bands ----------
BBResult calculateBollingerBands(
  List<double> closes,
  int period,
  double stdDevMult,
) {
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

// ---------- ATR ----------
List<double> calculateAtr(List<Candle> candles, int period) {
  if (candles.length < period + 1) return List.filled(candles.length, double.nan);
  final trueRanges = List<double>.filled(candles.length, 0.0);
  for (int i = 1; i < candles.length; i++) {
    final hl = candles[i].high - candles[i].low;
    final hpc = (candles[i].high - candles[i - 1].close).abs();
    final lpc = (candles[i].low - candles[i - 1].close).abs();
    trueRanges[i] = math.max(hl, math.max(hpc, lpc));
  }
  final result = List<double>.filled(candles.length, double.nan);
  double atrSum = 0;
  for (int i = 1; i <= period; i++) atrSum += trueRanges[i];
  result[period] = atrSum / period;
  for (int i = period + 1; i < candles.length; i++) {
    result[i] = (result[i - 1] * (period - 1) + trueRanges[i]) / period;
  }
  return result;
}

// ---------- VSA (Volume Spread Analysis) ----------
/// Analyses the last candle in [candles] using the 20-candle average volume
/// and average spread as reference levels.
VsaResult calculateVsa(
  List<Candle> candles, {
  int lookback = 20,
  double highVolThreshold = 1.5,
  double veryHighVolThreshold = 2.0,
  double lowVolThreshold = 0.7,
  double wideSpreadThreshold = 1.3,
  double narrowSpreadThreshold = 0.7,
  double closeNearTopThreshold = 0.6,
  double closeNearBottomThreshold = 0.4,
}) {
  if (candles.length < lookback) {
    return const VsaResult(
      pattern: VsaPattern.normal,
      bullish: null,
      volRatio: 1.0,
      spreadRatio: 1.0,
      closePos: 0.5,
    );
  }

  final recent = candles.sublist(candles.length - lookback);
  final last = candles.last;

  // Average volume (exclude last candle from the avg window)
  final prevCandles = recent.sublist(0, lookback - 1);
  final prevLen = prevCandles.length.toDouble();
  final avgVol = prevCandles.map((c) => c.volume).reduce((a, b) => a + b) / prevLen;
  final avgSpread = prevCandles
          .map((c) => c.high - c.low)
          .reduce((a, b) => a + b) /
      prevLen;

  final spread = last.high - last.low;
  final volRatio = avgVol > 0 ? last.volume / avgVol : 1.0;
  final spreadRatio = avgSpread > 0 ? spread / avgSpread : 1.0;

  // Close position within the candle (0 = at low, 1 = at high)
  final closePos = spread > 0 ? (last.close - last.low) / spread : 0.5;

  final highVol = volRatio > highVolThreshold;
  final veryHighVol = volRatio > veryHighVolThreshold;
  final lowVol = volRatio < lowVolThreshold;
  final wideSpread = spreadRatio > wideSpreadThreshold;
  final narrowSpread = spreadRatio < narrowSpreadThreshold;
  final isUp = last.close > last.open;
  final isDown = last.close < last.open;
  final closeNearTop = closePos > closeNearTopThreshold;
  final closeNearBottom = closePos < closeNearBottomThreshold;

  VsaPattern pattern;
  bool? bullish;

  if (veryHighVol && isDown && closeNearBottom) {
    pattern = VsaPattern.sellingClimax;
    bullish = true; // Reversal up expected
  } else if (veryHighVol && isUp && closeNearTop) {
    pattern = VsaPattern.buyingClimax;
    bullish = false; // Distribution, reversal down
  } else if (highVol && isDown && closeNearTop) {
    pattern = VsaPattern.stoppingVolume;
    bullish = true;
  } else if (highVol && isUp && closeNearBottom) {
    pattern = VsaPattern.upthrust;
    bullish = false;
  } else if (wideSpread && isDown && closeNearTop) {
    pattern = VsaPattern.spring;
    bullish = true;
  } else if (wideSpread && isUp && closeNearBottom) {
    pattern = VsaPattern.pseudoUpthrust;
    bullish = false;
  } else if (lowVol && narrowSpread && isDown) {
    pattern = VsaPattern.noSupply;
    bullish = true;
  } else if (lowVol && narrowSpread && isUp) {
    pattern = VsaPattern.noDemand;
    bullish = false;
  } else {
    pattern = VsaPattern.normal;
    bullish = null;
  }

  return VsaResult(
    pattern: pattern,
    bullish: bullish,
    volRatio: volRatio,
    spreadRatio: spreadRatio,
    closePos: closePos,
  );
}

// ---------- Helper ----------
double lastValidValue(List<double> values) {
  for (int i = values.length - 1; i >= 0; i--) {
    if (!values[i].isNaN) return values[i];
  }
  return double.nan;
}
