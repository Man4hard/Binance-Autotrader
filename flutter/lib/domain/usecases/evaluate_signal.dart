import '../entities/candle.dart';
import '../entities/signal.dart';
import '../entities/strategy_settings.dart';
import 'calculate_indicators.dart';

Signal evaluateSignal(
  List<Candle> candles,
  StrategySettings settings,
  String symbol,
) {
  if (candles.length < 50) return Signal.empty(symbol);

  final closes = candles.map((c) => c.close).toList();
  final currentPrice = closes.last;
  final ai = settings.activeIndicators;

  // ── EMA ──────────────────────────────────────────────────────────────────
  int? emaScore;
  double ema9v = 0, ema21v = 0, ema50v = 0;
  if (ai['ema'] ?? true) {
    final ema1Values = calculateEma(closes, settings.emaPeriod1);
    final ema2Values = calculateEma(closes, settings.emaPeriod2);
    final ema3Values = calculateEma(closes, settings.emaPeriod3);
    ema9v = lastValidValue(ema1Values);
    ema21v = lastValidValue(ema2Values);
    ema50v = lastValidValue(ema3Values);
    if (ema9v.isNaN || ema21v.isNaN || ema50v.isNaN) {
      emaScore = 0;
    } else if (ema9v > ema21v && currentPrice > ema21v) {
      emaScore = 1;   // Fast EMA above slow + price above slow → bullish
    } else if (ema9v < ema21v && currentPrice < ema21v) {
      emaScore = -1;  // Fast EMA below slow + price below slow → bearish
    } else {
      emaScore = 0;
    }
  }

  // ── MACD ─────────────────────────────────────────────────────────────────
  int? macdScore;
  double macdHistV = 0;
  if (ai['macd'] ?? true) {
    final macdResult = calculateMacd(
      closes,
      fast: settings.macdFast,
      slow: settings.macdSlow,
      signal: settings.macdSignal,
    );
    final lastHisto = macdResult.lastHistogram;
    final prevHisto = macdResult.prevHistogram;
    macdHistV = lastHisto.isNaN ? 0 : lastHisto;
    if (!lastHisto.isNaN && !prevHisto.isNaN) {
      if (lastHisto > 0 && lastHisto > prevHisto) macdScore = 1;
      else if (lastHisto < 0 && lastHisto < prevHisto) macdScore = -1;
      else macdScore = 0;
    } else {
      macdScore = 0;
    }
  }

  // ── RSI ──────────────────────────────────────────────────────────────────
  int? rsiScore;
  double rsiV = 50;
  if (ai['rsi'] ?? true) {
    final rsiValues = calculateRsi(closes, settings.rsiPeriod);
    rsiV = lastValidValue(rsiValues);
    if (rsiV.isNaN) {
      rsiV = 50;
      rsiScore = 0;
    } else if (rsiV > settings.rsiNeutralHigh && rsiV < settings.rsiOverbought) {
      rsiScore = 1;
    } else if (rsiV < settings.rsiNeutralLow && rsiV > settings.rsiOversold) {
      rsiScore = -1;
    } else {
      rsiScore = 0;
    }
  }

  // ── Bollinger Bands (midline trend filter — not upper-band breakout) ──────
  int? bbScore;
  if (ai['bb'] ?? true) {
    final bbResult = calculateBollingerBands(closes, settings.bbPeriod, settings.bbStdDev);
    if (bbResult.lastMiddle.isNaN) {
      bbScore = 0;
    } else if (currentPrice > bbResult.lastMiddle) {
      bbScore = 1;  // Above midline = bullish trend
    } else if (currentPrice < bbResult.lastMiddle) {
      bbScore = -1; // Below midline = bearish trend
    } else {
      bbScore = 0;
    }
  }

  // ── VSA (Volume Spread Analysis) ─────────────────────────────────────────
  int? vsaScore;
  VsaResult? vsaResult;
  if (ai['vsa'] ?? true) {
    vsaResult = calculateVsa(
      candles,
      lookback: settings.vsaLookback,
      highVolThreshold: settings.vsaHighVolThreshold,
      veryHighVolThreshold: settings.vsaVeryHighVolThreshold,
      lowVolThreshold: settings.vsaLowVolThreshold,
      wideSpreadThreshold: settings.vsaWideSpreadThreshold,
      narrowSpreadThreshold: settings.vsaNarrowSpreadThreshold,
      closeNearTopThreshold: settings.vsaCloseNearTopThreshold,
      closeNearBottomThreshold: settings.vsaCloseNearBottomThreshold,
    );
    if (vsaResult.bullish == true) vsaScore = 1;
    else if (vsaResult.bullish == false) vsaScore = -1;
    else vsaScore = 0;
  }

  // ── Scoring ───────────────────────────────────────────────────────────────
  final maxScore = (ai.values.where((v) => v).length);

  final bullTotal = [
    emaScore == 1,
    macdScore == 1,
    rsiScore == 1,
    bbScore == 1,
    vsaScore == 1,
  ].where((x) => x).length;

  final bearTotal = [
    emaScore == -1,
    macdScore == -1,
    rsiScore == -1,
    bbScore == -1,
    vsaScore == -1,
  ].where((x) => x).length;

  final effectiveMin = settings.effectiveMinScore;

  SignalAction action = SignalAction.none;
  if (maxScore > 0 && bullTotal >= effectiveMin) {
    action = SignalAction.buy;
  } else if (maxScore > 0 && bearTotal >= effectiveMin) {
    action = SignalAction.sell;
  }

  // ── ATR ───────────────────────────────────────────────────────────────────
  final atrValues = calculateAtr(candles, settings.atrPeriod);
  final atrValue = lastValidValue(atrValues);

  return Signal(
    symbol: symbol,
    timestamp: DateTime.now().toUtc(),
    action: action,
    bullScore: bullTotal,
    bearScore: bearTotal,
    maxScore: maxScore,
    emaScore: emaScore,
    macdScore: macdScore,
    rsiScore: rsiScore,
    bbScore: bbScore,
    vsaScore: vsaScore,
    vsaPattern: vsaResult?.pattern.label ?? 'Normal',
    vsaBullish: vsaResult?.bullish,
    vsaVolRatio: vsaResult?.volRatio,
    vsaSpreadRatio: vsaResult?.spreadRatio,
    vsaClosePos: vsaResult?.closePos,
    atrValue: atrValue.isNaN ? 0.0 : atrValue,
    currentPrice: currentPrice,
    rsi: rsiV,
    ema9: ema9v,
    ema21: ema21v,
    ema50: ema50v,
    macdHist: macdHistV,
    timeframe: settings.timeframe,
  );
}
