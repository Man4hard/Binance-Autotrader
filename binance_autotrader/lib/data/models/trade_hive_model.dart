import 'package:hive/hive.dart';

part 'trade_hive_model.g.dart';

@HiveType(typeId: 1)
class TradeHiveModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String symbol;

  @HiveField(2)
  String side;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  double entryPrice;

  @HiveField(5)
  double? exitPrice;

  @HiveField(6)
  double stopLoss;

  @HiveField(7)
  double takeProfit;

  @HiveField(8)
  String status;

  @HiveField(9)
  DateTime openedAt;

  @HiveField(10)
  DateTime? closedAt;

  @HiveField(11)
  double? realizedPnl;

  @HiveField(12)
  bool isPaper;

  @HiveField(13)
  String marketType;

  @HiveField(14)
  String? exchangeOrderId;

  @HiveField(15)
  String timeframe;

  TradeHiveModel({
    required this.id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.entryPrice,
    this.exitPrice,
    required this.stopLoss,
    required this.takeProfit,
    required this.status,
    required this.openedAt,
    this.closedAt,
    this.realizedPnl,
    required this.isPaper,
    required this.marketType,
    this.exchangeOrderId,
    required this.timeframe,
  });
}
