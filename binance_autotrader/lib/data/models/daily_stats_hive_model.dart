import 'package:hive/hive.dart';

part 'daily_stats_hive_model.g.dart';

@HiveType(typeId: 3)
class DailyStatsHiveModel extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  int totalTrades;

  @HiveField(2)
  int winningTrades;

  @HiveField(3)
  int losingTrades;

  @HiveField(4)
  double totalPnl;

  @HiveField(5)
  double totalProfit;

  @HiveField(6)
  double totalLoss;

  @HiveField(7)
  bool isPaper;

  DailyStatsHiveModel({
    required this.date,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.totalPnl,
    required this.totalProfit,
    required this.totalLoss,
    required this.isPaper,
  });
}
