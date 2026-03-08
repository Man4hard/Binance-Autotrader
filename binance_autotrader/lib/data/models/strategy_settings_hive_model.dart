import 'package:hive/hive.dart';

part 'strategy_settings_hive_model.g.dart';

@HiveType(typeId: 2)
class StrategySettingsHiveModel extends HiveObject {
  @HiveField(0)
  List<String> symbols;

  @HiveField(1)
  String timeframe;

  @HiveField(2)
  int emaPeriod1;

  @HiveField(3)
  int emaPeriod2;

  @HiveField(4)
  int emaPeriod3;

  @HiveField(5)
  int macdFast;

  @HiveField(6)
  int macdSlow;

  @HiveField(7)
  int macdSignal;

  @HiveField(8)
  int rsiPeriod;

  @HiveField(9)
  double rsiNeutralLow;

  @HiveField(10)
  double rsiNeutralHigh;

  @HiveField(11)
  double rsiOverbought;

  @HiveField(12)
  double rsiOversold;

  @HiveField(13)
  int bbPeriod;

  @HiveField(14)
  double bbStdDev;

  @HiveField(15)
  int atrPeriod;

  @HiveField(16)
  double atrMultiplier;

  @HiveField(17)
  double minRR;

  @HiveField(18)
  double dailyProfitTarget;

  @HiveField(19)
  double maxDailyLoss;

  @HiveField(20)
  int maxDailyTrades;

  @HiveField(21)
  double riskPercent;

  @HiveField(22)
  bool isPaperMode;

  @HiveField(23)
  bool isEngineRunning;

  @HiveField(24)
  bool autoStartOnBoot;

  @HiveField(25)
  String marketType;

  @HiveField(26)
  int minScoreToEnter;

  StrategySettingsHiveModel({
    required this.symbols,
    required this.timeframe,
    required this.emaPeriod1,
    required this.emaPeriod2,
    required this.emaPeriod3,
    required this.macdFast,
    required this.macdSlow,
    required this.macdSignal,
    required this.rsiPeriod,
    required this.rsiNeutralLow,
    required this.rsiNeutralHigh,
    required this.rsiOverbought,
    required this.rsiOversold,
    required this.bbPeriod,
    required this.bbStdDev,
    required this.atrPeriod,
    required this.atrMultiplier,
    required this.minRR,
    required this.dailyProfitTarget,
    required this.maxDailyLoss,
    required this.maxDailyTrades,
    required this.riskPercent,
    required this.isPaperMode,
    required this.isEngineRunning,
    required this.autoStartOnBoot,
    required this.marketType,
    required this.minScoreToEnter,
  });
}
