import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../data/datasources/binance_rest_client.dart';
import '../../data/repositories/binance_repository_impl.dart';
import '../../data/repositories/hive_trade_repository.dart';
import '../../data/repositories/hive_settings_repository.dart';
import '../../data/repositories/secure_storage_repository_impl.dart';
import '../../domain/repositories/binance_repository.dart';
import '../../domain/repositories/trade_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/secure_storage_repository.dart';
import 'strategy_settings_notifier.dart';
import 'account_balance_notifier.dart';
import 'active_trades_notifier.dart';
import 'trade_history_notifier.dart';
import 'signal_notifier.dart';
import 'daily_stats_notifier.dart';

final restClientProvider = Provider<BinanceRestClient>((ref) {
  return BinanceRestClient();
});

final binanceRepositoryProvider = Provider<BinanceRepository>((ref) {
  final client = ref.watch(restClientProvider);
  return BinanceRepositoryImpl(client);
});

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return HiveTradeRepository();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return HiveSettingsRepository();
});

final secureStorageProvider = Provider<SecureStorageRepository>((ref) {
  return const SecureStorageRepositoryImpl();
});

final backgroundServiceProvider = Provider<FlutterBackgroundService>((ref) {
  return FlutterBackgroundService();
});

final strategySettingsProvider =
    StateNotifierProvider<StrategySettingsNotifier, StrategySettingsState>((ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return StrategySettingsNotifier(repo);
});

final accountBalanceProvider =
    StateNotifierProvider<AccountBalanceNotifier, AccountBalanceState>((ref) {
  final repo = ref.watch(binanceRepositoryProvider);
  final secure = ref.watch(secureStorageProvider);
  return AccountBalanceNotifier(repo, secure);
});

final activeTradesProvider =
    StateNotifierProvider<ActiveTradesNotifier, ActiveTradesState>((ref) {
  final repo = ref.watch(tradeRepositoryProvider);
  return ActiveTradesNotifier(repo);
});

final tradeHistoryProvider =
    StateNotifierProvider<TradeHistoryNotifier, TradeHistoryState>((ref) {
  final repo = ref.watch(tradeRepositoryProvider);
  return TradeHistoryNotifier(repo);
});

final signalProvider =
    StateNotifierProvider<SignalNotifier, SignalState>((ref) {
  return SignalNotifier();
});

final dailyStatsProvider =
    StateNotifierProvider<DailyStatsNotifier, DailyStatsState>((ref) {
  final repo = ref.watch(tradeRepositoryProvider);
  return DailyStatsNotifier(repo);
});

final engineRunningProvider = StateProvider<bool>((ref) => false);

final apiCredentialsProvider = FutureProvider<({String? apiKey, String? secret})>((ref) async {
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
