import '../entities/candle.dart';
import '../entities/signal.dart';
import '../entities/strategy_settings.dart';
import 'calculate_indicators.dart';

Signal evaluateSignal(
  List<Candle> candles,
  StrategySettings settings,
  String symbol,
) {
  if (candles.length < 200) {
    return Signal.empty(symbol);
  }

  final closes = candles.map((c) => c.close).toList();
  final currentPrice = closes.last;

  final ema1Values = calculateEma(closes, settings.emaPeriod1);
  final ema2Values = calculateEma(closes, settings.emaPeriod2);
  final ema3Values = calculateEma(closes, settings.emaPeriod3);

  final ema1 = lastValidValue(ema1Values);
  final ema2 = lastValidValue(ema2Values);
  final ema3 = lastValidValue(ema3Values);

  if (ema1.isNaN || ema2.isNaN || ema3.isNaN) {
    return Signal.empty(symbol);
  }

  int emaScore;
  if (currentPrice > ema1 && ema1 > ema2 && ema2 > ema3) {
    emaScore = 1;
  } else if (currentPrice < ema1 && ema1 < ema2 && ema2 < ema3) {
    emaScore = -1;
  } else {
    emaScore = 0;
  }

  final macdResult = calculateMacd(
    closes,
    fast: settings.macdFast,
    slow: settings.macdSlow,
    signal: settings.macdSignal,
  );

  final lastHisto = macdResult.lastHistogram;
  final prevHisto = macdResult.prevHistogram;

  int macdScore;
  if (!lastHisto.isNaN && !prevHisto.isNaN) {
    if (lastHisto > 0 && lastHisto > prevHisto) {
      macdScore = 1;
    } else if (lastHisto < 0 && lastHisto < prevHisto) {
      macdScore = -1;
    } else {
      macdScore = 0;
    }
  } else {
    macdScore = 0;
  }

  final rsiValues = calculateRsi(closes, settings.rsiPeriod);
  final rsi = lastValidValue(rsiValues);

  int rsiScore;
  if (rsi.isNaN) {
    rsiScore = 0;
  } else if (rsi > settings.rsiNeutralHigh && rsi < settings.rsiOverbought) {
    rsiScore = 1;
  } else if (rsi < settings.rsiNeutralLow && rsi > settings.rsiOversold) {
    rsiScore = -1;
  } else {
    rsiScore = 0;
  }

  final bbResult = calculateBollingerBands(
    closes,
    settings.bbPeriod,
    settings.bbStdDev,
  );

  int bbScore;
  if (bbResult.lastUpper.isNaN || bbResult.lastLower.isNaN) {
    bbScore = 0;
  } else if (currentPrice > bbResult.lastUpper) {
    bbScore = 1;
  } else if (currentPrice < bbResult.lastLower) {
    bbScore = -1;
  } else {
    bbScore = 0;
  }

  final bullTotal = [
    emaScore == 1,
    macdScore == 1,
    rsiScore == 1,
    bbScore == 1,
  ].where((x) => x).length;

  final bearTotal = [
    emaScore == -1,
    macdScore == -1,
    rsiScore == -1,
    bbScore == -1,
  ].where((x) => x).length;

  SignalAction action = SignalAction.none;
  if (bullTotal >= settings.minScoreToEnter) {
    action = SignalAction.buy;
  } else if (bearTotal >= settings.minScoreToEnter) {
    action = SignalAction.sell;
  }

  final atrValues = calculateAtr(candles, settings.atrPeriod);
  final atrValue = lastValidValue(atrValues);

  return Signal(
    symbol: symbol,
    timestamp: DateTime.now().toUtc(),
    action: action,
    bullScore: bullTotal,
    bearScore: bearTotal,
    emaScore: emaScore,
    macdScore: macdScore,
    rsiScore: rsiScore,
    bbScore: bbScore,
    atrValue: atrValue.isNaN ? 0.0 : atrValue,
    currentPrice: currentPrice,
    timeframe: settings.timeframe,
  );
}
