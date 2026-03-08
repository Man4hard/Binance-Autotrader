import '../entities/trade.dart';
import '../entities/candle.dart';

enum ExitReason { stopLoss, takeProfit, manual, none }

class ExitDecision {
  final bool shouldExit;
  final ExitReason reason;
  final double? exitPrice;

  const ExitDecision({
    required this.shouldExit,
    required this.reason,
    this.exitPrice,
  });

  static const ExitDecision noExit = ExitDecision(
    shouldExit: false,
    reason: ExitReason.none,
  );
}

ExitDecision checkExitConditions(Trade trade, Candle currentCandle) {
  final price = currentCandle.close;

  if (trade.side == TradeSide.buy) {
    if (currentCandle.low <= trade.stopLoss) {
      return ExitDecision(
        shouldExit: true,
        reason: ExitReason.stopLoss,
        exitPrice: trade.stopLoss,
      );
    }
    if (currentCandle.high >= trade.takeProfit) {
      return ExitDecision(
        shouldExit: true,
        reason: ExitReason.takeProfit,
        exitPrice: trade.takeProfit,
      );
    }
  } else {
    if (currentCandle.high >= trade.stopLoss) {
      return ExitDecision(
        shouldExit: true,
        reason: ExitReason.stopLoss,
        exitPrice: trade.stopLoss,
      );
    }
    if (currentCandle.low <= trade.takeProfit) {
      return ExitDecision(
        shouldExit: true,
        reason: ExitReason.takeProfit,
        exitPrice: trade.takeProfit,
      );
    }
  }

  return ExitDecision.noExit;
}

Trade closeTrade(Trade trade, double exitPrice, ExitReason reason) {
  final pnl = trade.side == TradeSide.buy
      ? (exitPrice - trade.entryPrice) * trade.quantity
      : (trade.entryPrice - exitPrice) * trade.quantity;

  return trade.copyWith(
    status: TradeStatus.closed,
    exitPrice: exitPrice,
    closedAt: DateTime.now().toUtc(),
    realizedPnl: double.parse(pnl.toStringAsFixed(4)),
  );
}
