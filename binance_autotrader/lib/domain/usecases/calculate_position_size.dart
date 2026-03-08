import '../entities/strategy_settings.dart';
import '../entities/trade.dart';

class PositionSizing {
  final double quantity;
  final double stopLoss;
  final double takeProfit;
  final double riskAmount;
  final double riskRewardRatio;

  const PositionSizing({
    required this.quantity,
    required this.stopLoss,
    required this.takeProfit,
    required this.riskAmount,
    required this.riskRewardRatio,
  });

  bool get isValid =>
      quantity > 0 &&
      stopLoss > 0 &&
      takeProfit > 0 &&
      riskRewardRatio >= 1.0;
}

PositionSizing calculatePositionSize({
  required double balance,
  required double entryPrice,
  required double atrValue,
  required StrategySettings settings,
  required TradeSide side,
}) {
  if (balance <= 0 || entryPrice <= 0 || atrValue <= 0) {
    return const PositionSizing(
      quantity: 0,
      stopLoss: 0,
      takeProfit: 0,
      riskAmount: 0,
      riskRewardRatio: 0,
    );
  }

  final slDistance = atrValue * settings.atrMultiplier;
  final tpDistance = slDistance * settings.minRR;

  double stopLoss;
  double takeProfit;

  if (side == TradeSide.buy) {
    stopLoss = entryPrice - slDistance;
    takeProfit = entryPrice + tpDistance;
  } else {
    stopLoss = entryPrice + slDistance;
    takeProfit = entryPrice - tpDistance;
  }

  if (stopLoss <= 0) {
    stopLoss = entryPrice * 0.98;
  }
  if (takeProfit <= 0) {
    takeProfit = entryPrice * 0.95;
  }

  final riskAmount = balance * settings.riskPercent;
  final riskPerUnit = (entryPrice - stopLoss).abs();

  if (riskPerUnit <= 0) {
    return const PositionSizing(
      quantity: 0,
      stopLoss: 0,
      takeProfit: 0,
      riskAmount: 0,
      riskRewardRatio: 0,
    );
  }

  var quantity = riskAmount / riskPerUnit;

  final maxPositionValue = balance * 0.05;
  final maxQuantity = maxPositionValue / entryPrice;
  if (quantity > maxQuantity) {
    quantity = maxQuantity;
  }

  final minPositionValue = 10.0;
  if (quantity * entryPrice < minPositionValue) {
    quantity = minPositionValue / entryPrice;
  }

  final riskRewardRatio =
      (takeProfit - entryPrice).abs() / (entryPrice - stopLoss).abs();

  return PositionSizing(
    quantity: double.parse(quantity.toStringAsFixed(6)),
    stopLoss: double.parse(stopLoss.toStringAsFixed(8)),
    takeProfit: double.parse(takeProfit.toStringAsFixed(8)),
    riskAmount: riskAmount,
    riskRewardRatio: riskRewardRatio,
  );
}
