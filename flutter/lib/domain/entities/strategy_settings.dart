import '../../core/constants.dart';

enum MarketTypeMode { spot, futures }

class StrategySettings {
  final List<String> symbols;
  final String timeframe;
  final int emaPeriod1;
  final int emaPeriod2;
  final int emaPeriod3;
  final int macdFast;
  final int macdSlow;
  final int macdSignal;
  final int rsiPeriod;
  final double rsiNeutralLow;
  final double rsiNeutralHigh;
  final double rsiOverbought;
  final double rsiOversold;
  final int bbPeriod;
  final double bbStdDev;
  final int atrPeriod;
  final double atrMultiplier;
  final double minRR;
  final double dailyProfitTarget;
  final double maxDailyLoss;
  final int maxDailyTrades;
  final double riskPercent;
  final bool isPaperMode;
  final bool isEngineRunning;
  final bool autoStartOnBoot;
  final MarketTypeMode marketType;
  final int minScoreToEnter;
  // Which indicators are active: keys = 'ema','macd','rsi','bb','vsa'
  final Map<String, bool> activeIndicators;

  const StrategySettings({
    this.symbols = const ['BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'ADAUSDT'],
    this.timeframe = AppConstants.defaultTimeframe,
    this.emaPeriod1 = 9,
    this.emaPeriod2 = 21,
    this.emaPeriod3 = 50,
    this.macdFast = 12,
    this.macdSlow = 26,
    this.macdSignal = 9,
    this.rsiPeriod = 14,
    this.rsiNeutralLow = 40.0,
    this.rsiNeutralHigh = 60.0,
    this.rsiOverbought = 80.0,
    this.rsiOversold = 20.0,
    this.bbPeriod = 20,
    this.bbStdDev = 2.0,
    this.atrPeriod = 14,
    this.atrMultiplier = AppConstants.defaultAtrMultiplier,
    this.minRR = AppConstants.defaultMinRR,
    this.dailyProfitTarget = AppConstants.defaultDailyProfitTarget,
    this.maxDailyLoss = AppConstants.defaultMaxDailyLoss,
    this.maxDailyTrades = AppConstants.defaultMaxDailyTrades,
    this.riskPercent = AppConstants.defaultRiskPercent,
    this.isPaperMode = true,
    this.isEngineRunning = false,
    this.autoStartOnBoot = false,
    this.marketType = MarketTypeMode.spot,
    this.minScoreToEnter = 4,
    this.activeIndicators = AppConstants.defaultActiveIndicators,
  });

  int get enabledIndicatorCount =>
      activeIndicators.values.where((v) => v).length;

  int get effectiveMinScore =>
      minScoreToEnter.clamp(1, enabledIndicatorCount > 0 ? enabledIndicatorCount : 1);

  bool get emaEnabled => activeIndicators['ema'] ?? true;
  bool get macdEnabled => activeIndicators['macd'] ?? true;
  bool get rsiEnabled => activeIndicators['rsi'] ?? true;
  bool get bbEnabled => activeIndicators['bb'] ?? true;
  bool get vsaEnabled => activeIndicators['vsa'] ?? true;

  StrategySettings copyWith({
    List<String>? symbols,
    String? timeframe,
    int? emaPeriod1,
    int? emaPeriod2,
    int? emaPeriod3,
    int? macdFast,
    int? macdSlow,
    int? macdSignal,
    int? rsiPeriod,
    double? rsiNeutralLow,
    double? rsiNeutralHigh,
    double? rsiOverbought,
    double? rsiOversold,
    int? bbPeriod,
    double? bbStdDev,
    int? atrPeriod,
    double? atrMultiplier,
    double? minRR,
    double? dailyProfitTarget,
    double? maxDailyLoss,
    int? maxDailyTrades,
    double? riskPercent,
    bool? isPaperMode,
    bool? isEngineRunning,
    bool? autoStartOnBoot,
    MarketTypeMode? marketType,
    int? minScoreToEnter,
    Map<String, bool>? activeIndicators,
  }) {
    return StrategySettings(
      symbols: symbols ?? this.symbols,
      timeframe: timeframe ?? this.timeframe,
      emaPeriod1: emaPeriod1 ?? this.emaPeriod1,
      emaPeriod2: emaPeriod2 ?? this.emaPeriod2,
      emaPeriod3: emaPeriod3 ?? this.emaPeriod3,
      macdFast: macdFast ?? this.macdFast,
      macdSlow: macdSlow ?? this.macdSlow,
      macdSignal: macdSignal ?? this.macdSignal,
      rsiPeriod: rsiPeriod ?? this.rsiPeriod,
      rsiNeutralLow: rsiNeutralLow ?? this.rsiNeutralLow,
      rsiNeutralHigh: rsiNeutralHigh ?? this.rsiNeutralHigh,
      rsiOverbought: rsiOverbought ?? this.rsiOverbought,
      rsiOversold: rsiOversold ?? this.rsiOversold,
      bbPeriod: bbPeriod ?? this.bbPeriod,
      bbStdDev: bbStdDev ?? this.bbStdDev,
      atrPeriod: atrPeriod ?? this.atrPeriod,
      atrMultiplier: atrMultiplier ?? this.atrMultiplier,
      minRR: minRR ?? this.minRR,
      dailyProfitTarget: dailyProfitTarget ?? this.dailyProfitTarget,
      maxDailyLoss: maxDailyLoss ?? this.maxDailyLoss,
      maxDailyTrades: maxDailyTrades ?? this.maxDailyTrades,
      riskPercent: riskPercent ?? this.riskPercent,
      isPaperMode: isPaperMode ?? this.isPaperMode,
      isEngineRunning: isEngineRunning ?? this.isEngineRunning,
      autoStartOnBoot: autoStartOnBoot ?? this.autoStartOnBoot,
      marketType: marketType ?? this.marketType,
      minScoreToEnter: minScoreToEnter ?? this.minScoreToEnter,
      activeIndicators: activeIndicators ?? this.activeIndicators,
    );
  }

  Map<String, dynamic> toJson() => {
        'symbols': symbols,
        'timeframe': timeframe,
        'emaPeriod1': emaPeriod1,
        'emaPeriod2': emaPeriod2,
        'emaPeriod3': emaPeriod3,
        'macdFast': macdFast,
        'macdSlow': macdSlow,
        'macdSignal': macdSignal,
        'rsiPeriod': rsiPeriod,
        'rsiNeutralLow': rsiNeutralLow,
        'rsiNeutralHigh': rsiNeutralHigh,
        'rsiOverbought': rsiOverbought,
        'rsiOversold': rsiOversold,
        'bbPeriod': bbPeriod,
        'bbStdDev': bbStdDev,
        'atrPeriod': atrPeriod,
        'atrMultiplier': atrMultiplier,
        'minRR': minRR,
        'dailyProfitTarget': dailyProfitTarget,
        'maxDailyLoss': maxDailyLoss,
        'maxDailyTrades': maxDailyTrades,
        'riskPercent': riskPercent,
        'isPaperMode': isPaperMode,
        'isEngineRunning': isEngineRunning,
        'autoStartOnBoot': autoStartOnBoot,
        'marketType': marketType.name,
        'minScoreToEnter': minScoreToEnter,
        'activeIndicators': activeIndicators,
      };
}
