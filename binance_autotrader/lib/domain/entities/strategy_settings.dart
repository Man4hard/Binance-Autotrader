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

  const StrategySettings({
    this.symbols = const ['BTCUSDT', 'ETHUSDT', 'SOLUSDT'],
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
  });

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
      };

  factory StrategySettings.fromJson(Map<String, dynamic> json) =>
      StrategySettings(
        symbols: (json['symbols'] as List<dynamic>?)
                ?.map((s) => s.toString())
                .toList() ??
            const ['BTCUSDT', 'ETHUSDT', 'SOLUSDT'],
        timeframe: json['timeframe'] as String? ?? AppConstants.defaultTimeframe,
        emaPeriod1: json['emaPeriod1'] as int? ?? 9,
        emaPeriod2: json['emaPeriod2'] as int? ?? 21,
        emaPeriod3: json['emaPeriod3'] as int? ?? 50,
        macdFast: json['macdFast'] as int? ?? 12,
        macdSlow: json['macdSlow'] as int? ?? 26,
        macdSignal: json['macdSignal'] as int? ?? 9,
        rsiPeriod: json['rsiPeriod'] as int? ?? 14,
        rsiNeutralLow: (json['rsiNeutralLow'] as num?)?.toDouble() ?? 40.0,
        rsiNeutralHigh: (json['rsiNeutralHigh'] as num?)?.toDouble() ?? 60.0,
        rsiOverbought: (json['rsiOverbought'] as num?)?.toDouble() ?? 80.0,
        rsiOversold: (json['rsiOversold'] as num?)?.toDouble() ?? 20.0,
        bbPeriod: json['bbPeriod'] as int? ?? 20,
        bbStdDev: (json['bbStdDev'] as num?)?.toDouble() ?? 2.0,
        atrPeriod: json['atrPeriod'] as int? ?? 14,
        atrMultiplier:
            (json['atrMultiplier'] as num?)?.toDouble() ?? AppConstants.defaultAtrMultiplier,
        minRR: (json['minRR'] as num?)?.toDouble() ?? AppConstants.defaultMinRR,
        dailyProfitTarget: (json['dailyProfitTarget'] as num?)?.toDouble() ??
            AppConstants.defaultDailyProfitTarget,
        maxDailyLoss: (json['maxDailyLoss'] as num?)?.toDouble() ??
            AppConstants.defaultMaxDailyLoss,
        maxDailyTrades: json['maxDailyTrades'] as int? ?? AppConstants.defaultMaxDailyTrades,
        riskPercent: (json['riskPercent'] as num?)?.toDouble() ?? AppConstants.defaultRiskPercent,
        isPaperMode: json['isPaperMode'] as bool? ?? true,
        isEngineRunning: json['isEngineRunning'] as bool? ?? false,
        autoStartOnBoot: json['autoStartOnBoot'] as bool? ?? false,
        marketType: MarketTypeMode.values.byName(
            json['marketType'] as String? ?? 'spot'),
        minScoreToEnter: json['minScoreToEnter'] as int? ?? 4,
      );
}
