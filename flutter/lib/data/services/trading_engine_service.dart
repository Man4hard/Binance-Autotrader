import 'dart:async';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';

import '../../core/hive_init.dart';
import '../../domain/entities/strategy_settings.dart';
import '../../domain/entities/trade.dart';
import '../../domain/entities/candle.dart';
import '../../domain/usecases/calculate_indicators.dart';
import '../../domain/usecases/evaluate_signal.dart';
import '../../domain/usecases/calculate_position_size.dart';
import '../../domain/usecases/manage_exit_usecase.dart';
import '../datasources/binance_rest_client.dart';
import '../repositories/hive_trade_repository.dart';
import '../repositories/hive_settings_repository.dart';
import '../repositories/secure_storage_repository_impl.dart';
import 'notification_service.dart';

@pragma('vm:entry-point')
void onEngineStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  await initHive();

  final settingsRepo = HiveSettingsRepository();
  final tradeRepo = HiveTradeRepository();
  final secureStorage = const SecureStorageRepositoryImpl();
  final restClient = BinanceRestClient();
  final notifications = NotificationService();

  await notifications.init();

  StrategySettings settings = await settingsRepo.getSettings();
  String? apiKey = await secureStorage.getApiKey();
  String? secret = await secureStorage.getSecretKey();

  await restClient.syncServerTime();

  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'CryptoBot Engine',
      content: 'Monitoring ${settings.symbols.join(", ")}',
    );
  }

  double dailyPnl = 0;
  int dailyTradeCount = 0;
  DateTime lastDayCheck = DateTime.now().toUtc();
  bool targetReached = false;

  service.on('stop').listen((_) async {
    await service.stopSelf();
  });

  service.on('updateSettings').listen((_) async {
    settings = await settingsRepo.getSettings();
    apiKey = await secureStorage.getApiKey();
    secret = await secureStorage.getSecretKey();
  });

  service.on('emergencyStop').listen((_) async {
    final activeTrades = await tradeRepo.getActiveTrades();
    for (final trade in activeTrades) {
      final closed = trade.copyWith(
        status: TradeStatus.closed,
        exitPrice: trade.entryPrice,
        closedAt: DateTime.now().toUtc(),
        realizedPnl: 0.0,
      );
      await tradeRepo.updateTrade(closed);
    }
    await service.stopSelf();
  });

  final interval = _getCheckInterval(settings.timeframe);

  Timer.periodic(interval, (timer) async {
    if (service is AndroidServiceInstance) {
      if (!await service.isForegroundService()) {
        timer.cancel();
        return;
      }
    }

    final now = DateTime.now().toUtc();
    if (!now.isSameDay(lastDayCheck)) {
      dailyPnl = 0;
      dailyTradeCount = 0;
      lastDayCheck = now;
      targetReached = false;
    }

    if (dailyPnl >= settings.dailyProfitTarget && !targetReached) {
      targetReached = true;
      await notifications.showProfitTargetReached(dailyPnl);
      timer.cancel();
      await service.stopSelf();
      return;
    }

    if (dailyPnl <= -settings.maxDailyLoss.abs()) {
      await notifications.showMaxLossReached(dailyPnl);
      timer.cancel();
      await service.stopSelf();
      return;
    }

    if (dailyTradeCount >= settings.maxDailyTrades) return;

    final activeTrades = await tradeRepo.getActiveTrades(
      isPaper: settings.isPaperMode,
    );

    for (final trade in activeTrades) {
      try {
        final candles = await restClient.getKlines(
          trade.symbol,
          settings.timeframe,
          limit: 10,
        );
        if (candles.isNotEmpty) {
          final exit = checkExitConditions(trade, candles.last);
          if (exit.shouldExit && exit.exitPrice != null) {
            final closed = closeTrade(trade, exit.exitPrice!, exit.reason);
            await tradeRepo.updateTrade(closed);
            dailyPnl += closed.realizedPnl ?? 0;
            await notifications.showTradeExit(closed);
            service.invoke('tradeUpdate', {'action': 'closed', 'trade': closed.toJson()});
          }
        }
      } catch (_) {}
    }

    for (final symbol in settings.symbols) {
      try {
        final candles = await restClient.getKlines(
          symbol,
          settings.timeframe,
          limit: 200,
        );

        if (candles.length < 200) continue;

        final signal = evaluateSignal(candles, settings, symbol);
        service.invoke('signalUpdate', signal.toJson());

        if (signal.action.name == 'none') continue;

        final existingActive = activeTrades
            .where((t) => t.symbol == symbol)
            .toList();
        if (existingActive.isNotEmpty) continue;

        double balance = settings.isPaperMode
            ? await _getPaperBalance(tradeRepo, settings)
            : 1000.0;

        if (!settings.isPaperMode && apiKey != null && secret != null) {
          try {
            final acct = await restClient.getAccountInfo(
              apiKey: apiKey!,
              secret: secret!,
            );
            balance = acct.usdtFree;
          } catch (_) {}
        }

        final side = signal.action.name == 'buy' ? TradeSide.buy : TradeSide.sell;
        final sizing = calculatePositionSize(
          balance: balance,
          entryPrice: signal.currentPrice,
          atrValue: signal.atrValue > 0 ? signal.atrValue : signal.currentPrice * 0.01,
          settings: settings,
          side: side,
        );

        if (!sizing.isValid) continue;

        if (!settings.isPaperMode && apiKey != null && secret != null) {
          try {
            await restClient.placeOrder(
              symbol: symbol,
              side: side.name.toUpperCase(),
              type: 'MARKET',
              quantity: sizing.quantity,
              apiKey: apiKey!,
              secret: secret!,
            );
          } catch (e) {
            await notifications.showError('Order failed for $symbol: $e');
            continue;
          }
        }

        final trade = Trade(
          symbol: symbol,
          side: side,
          quantity: sizing.quantity,
          entryPrice: signal.currentPrice,
          stopLoss: sizing.stopLoss,
          takeProfit: sizing.takeProfit,
          isPaper: settings.isPaperMode,
          timeframe: settings.timeframe,
        );

        await tradeRepo.saveTrade(trade);
        dailyTradeCount++;
        await notifications.showTradeEntry(trade);
        service.invoke('tradeUpdate', {'action': 'opened', 'trade': trade.toJson()});

        if (service is AndroidServiceInstance) {
          service.setForegroundNotificationInfo(
            title: 'CryptoBot Engine',
            content: 'Active: $dailyTradeCount trades | P&L: ${dailyPnl.toStringAsFixed(2)}',
          );
        }
      } catch (_) {}
    }
  });
}

Duration _getCheckInterval(String timeframe) {
  switch (timeframe) {
    case '1m':
      return const Duration(seconds: 30);
    case '5m':
      return const Duration(minutes: 1);
    case '15m':
      return const Duration(minutes: 2);
    case '1h':
      return const Duration(minutes: 5);
    case '4h':
      return const Duration(minutes: 15);
    default:
      return const Duration(minutes: 2);
  }
}

Future<double> _getPaperBalance(
  HiveTradeRepository tradeRepo,
  StrategySettings settings,
) async {
  const startingBalance = 1000.0;
  final closedTrades = await tradeRepo.getClosedTrades(isPaper: true);
  final totalPnl = closedTrades.fold<double>(
    0.0,
    (sum, t) => sum + (t.realizedPnl ?? 0),
  );
  return startingBalance + totalPnl;
}

extension _DateTimeExt on DateTime {
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
