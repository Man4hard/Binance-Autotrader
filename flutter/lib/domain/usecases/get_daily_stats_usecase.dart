import '../entities/trade.dart';
import '../entities/daily_stats.dart';

DailyStats getDailyStats(List<Trade> closedTrades, {bool isPaper = true}) {
  final today = DateTime.now().toUtc();
  final todayTrades = closedTrades.where((t) {
    final closed = t.closedAt;
    if (closed == null) return false;
    return closed.year == today.year &&
        closed.month == today.month &&
        closed.day == today.day &&
        t.isPaper == isPaper;
  }).toList();

  double totalPnl = 0;
  double totalProfit = 0;
  double totalLoss = 0;
  int wins = 0;
  int losses = 0;

  for (final trade in todayTrades) {
    final pnl = trade.realizedPnl ?? 0;
    totalPnl += pnl;
    if (pnl > 0) {
      totalProfit += pnl;
      wins++;
    } else if (pnl < 0) {
      totalLoss += pnl.abs();
      losses++;
    }
  }

  return DailyStats(
    date: today,
    totalTrades: todayTrades.length,
    winningTrades: wins,
    losingTrades: losses,
    totalPnl: totalPnl,
    totalProfit: totalProfit,
    totalLoss: totalLoss,
    isPaper: isPaper,
  );
}

DailyStats getAllTimeStats(List<Trade> closedTrades, {bool isPaper = true}) {
  final trades = closedTrades.where((t) => t.isPaper == isPaper).toList();

  double totalPnl = 0;
  double totalProfit = 0;
  double totalLoss = 0;
  int wins = 0;
  int losses = 0;

  for (final trade in trades) {
    final pnl = trade.realizedPnl ?? 0;
    totalPnl += pnl;
    if (pnl > 0) {
      totalProfit += pnl;
      wins++;
    } else if (pnl < 0) {
      totalLoss += pnl.abs();
      losses++;
    }
  }

  return DailyStats(
    date: DateTime.now().toUtc(),
    totalTrades: trades.length,
    winningTrades: wins,
    losingTrades: losses,
    totalPnl: totalPnl,
    totalProfit: totalProfit,
    totalLoss: totalLoss,
    isPaper: isPaper,
  );
}
