import 'package:uuid/uuid.dart';

enum TradeSide { buy, sell }

enum TradeStatus { open, closed, cancelled }

enum MarketType { spot, futures }

class Trade {
  final String id;
  final String symbol;
  final TradeSide side;
  final double quantity;
  final double entryPrice;
  final double? exitPrice;
  final double stopLoss;
  final double takeProfit;
  final TradeStatus status;
  final DateTime openedAt;
  final DateTime? closedAt;
  final double? realizedPnl;
  final bool isPaper;
  final MarketType marketType;
  final String? exchangeOrderId;
  final String timeframe;

  Trade({
    String? id,
    required this.symbol,
    required this.side,
    required this.quantity,
    required this.entryPrice,
    this.exitPrice,
    required this.stopLoss,
    required this.takeProfit,
    this.status = TradeStatus.open,
    DateTime? openedAt,
    this.closedAt,
    this.realizedPnl,
    this.isPaper = true,
    this.marketType = MarketType.spot,
    this.exchangeOrderId,
    this.timeframe = '15m',
  })  : id = id ?? const Uuid().v4(),
        openedAt = openedAt ?? DateTime.now().toUtc();

  double get unrealizedPnl {
    if (exitPrice == null) return 0.0;
    final diff = side == TradeSide.buy
        ? exitPrice! - entryPrice
        : entryPrice - exitPrice!;
    return diff * quantity;
  }

  double get pnlPercent {
    if (exitPrice == null || entryPrice == 0) return 0.0;
    final diff = side == TradeSide.buy
        ? exitPrice! - entryPrice
        : entryPrice - exitPrice!;
    return (diff / entryPrice) * 100;
  }

  double get riskRewardRatio {
    final risk = (entryPrice - stopLoss).abs();
    final reward = (takeProfit - entryPrice).abs();
    if (risk == 0) return 0.0;
    return reward / risk;
  }

  bool get isWin => (realizedPnl ?? 0) > 0;

  Trade copyWith({
    String? id,
    String? symbol,
    TradeSide? side,
    double? quantity,
    double? entryPrice,
    double? exitPrice,
    double? stopLoss,
    double? takeProfit,
    TradeStatus? status,
    DateTime? openedAt,
    DateTime? closedAt,
    double? realizedPnl,
    bool? isPaper,
    MarketType? marketType,
    String? exchangeOrderId,
    String? timeframe,
  }) {
    return Trade(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      side: side ?? this.side,
      quantity: quantity ?? this.quantity,
      entryPrice: entryPrice ?? this.entryPrice,
      exitPrice: exitPrice ?? this.exitPrice,
      stopLoss: stopLoss ?? this.stopLoss,
      takeProfit: takeProfit ?? this.takeProfit,
      status: status ?? this.status,
      openedAt: openedAt ?? this.openedAt,
      closedAt: closedAt ?? this.closedAt,
      realizedPnl: realizedPnl ?? this.realizedPnl,
      isPaper: isPaper ?? this.isPaper,
      marketType: marketType ?? this.marketType,
      exchangeOrderId: exchangeOrderId ?? this.exchangeOrderId,
      timeframe: timeframe ?? this.timeframe,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'symbol': symbol,
        'side': side.name,
        'quantity': quantity,
        'entryPrice': entryPrice,
        'exitPrice': exitPrice,
        'stopLoss': stopLoss,
        'takeProfit': takeProfit,
        'status': status.name,
        'openedAt': openedAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
        'realizedPnl': realizedPnl,
        'isPaper': isPaper,
        'marketType': marketType.name,
        'exchangeOrderId': exchangeOrderId,
        'timeframe': timeframe,
      };

  factory Trade.fromJson(Map<String, dynamic> json) => Trade(
        id: json['id'] as String?,
        symbol: json['symbol'] as String,
        side: TradeSide.values.byName(json['side'] as String),
        quantity: (json['quantity'] as num).toDouble(),
        entryPrice: (json['entryPrice'] as num).toDouble(),
        exitPrice: json['exitPrice'] != null
            ? (json['exitPrice'] as num).toDouble()
            : null,
        stopLoss: (json['stopLoss'] as num).toDouble(),
        takeProfit: (json['takeProfit'] as num).toDouble(),
        status: TradeStatus.values.byName(json['status'] as String),
        openedAt: DateTime.parse(json['openedAt'] as String),
        closedAt: json['closedAt'] != null
            ? DateTime.parse(json['closedAt'] as String)
            : null,
        realizedPnl: json['realizedPnl'] != null
            ? (json['realizedPnl'] as num).toDouble()
            : null,
        isPaper: json['isPaper'] as bool? ?? true,
        marketType: MarketType.values.byName(
            json['marketType'] as String? ?? 'spot'),
        exchangeOrderId: json['exchangeOrderId'] as String?,
        timeframe: json['timeframe'] as String? ?? '15m',
      );
}
