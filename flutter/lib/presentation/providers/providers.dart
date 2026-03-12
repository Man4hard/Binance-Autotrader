import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import 'strategy_settings_notifier.dart';
import 'account_balance_notifier.dart';
import 'active_trades_notifier.dart';
import 'trade_history_notifier.dart';
import 'signal_notifier.dart';
import 'daily_stats_notifier.dart';

export 'repository_providers.dart';

final strategySettingsProvider =
    NotifierProvider<StrategySettingsNotifier, StrategySettingsState>(
        StrategySettingsNotifier.new);

final accountBalanceProvider =
    NotifierProvider<AccountBalanceNotifier, AccountBalanceState>(
        AccountBalanceNotifier.new);

final activeTradesProvider =
    NotifierProvider<ActiveTradesNotifier, ActiveTradesState>(
        ActiveTradesNotifier.new);

final tradeHistoryProvider =
    NotifierProvider<TradeHistoryNotifier, TradeHistoryState>(
        TradeHistoryNotifier.new);

final signalProvider =
    NotifierProvider<SignalNotifier, SignalState>(SignalNotifier.new);

final dailyStatsProvider =
    NotifierProvider<DailyStatsNotifier, DailyStatsState>(
        DailyStatsNotifier.new);

class _EngineRunning extends Notifier<bool> {
  @override
  bool build() => false;
}

final engineRunningProvider =
    NotifierProvider<_EngineRunning, bool>(_EngineRunning.new);

final apiCredentialsProvider =
    FutureProvider<({String? apiKey, String? secret})>((ref) async {
  final secure = ref.watch(secureStorageProvider);
  final apiKey = await secure.getApiKey();
  final secret = await secure.getSecretKey();
  return (apiKey: apiKey, secret: secret);
});

final paperBalanceProvider = FutureProvider<double>((ref) async {
  final tradeRepo = ref.watch(tradeRepositoryProvider);
  const startingBalance = 1000.0;
  final closedTrades = await tradeRepo.getClosedTrades(isPaper: true);
  final totalPnl = closedTrades.fold<double>(
    0.0,
    (sum, t) => sum + (t.realizedPnl ?? 0),
  );
  return startingBalance + totalPnl;
});
