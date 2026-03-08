import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../domain/entities/trade.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _tradeChannelId = 'cryptobot_trades';
  static const _tradeChannelName = 'Trade Signals';
  static const _alertChannelId = 'cryptobot_alerts';
  static const _alertChannelName = 'Alerts';

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('ic_bg_service_small');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _tradeChannelId,
            _tradeChannelName,
            description: 'Trade entry and exit notifications',
            importance: Importance.high,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _alertChannelId,
            _alertChannelName,
            description: 'Risk alerts and system notifications',
            importance: Importance.max,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> showTradeEntry(Trade trade) async {
    final side = trade.side == TradeSide.buy ? '🟢 BUY' : '🔴 SELL';
    final mode = trade.isPaper ? '[PAPER] ' : '';
    await _plugin.show(
      trade.id.hashCode,
      '$mode${trade.symbol} $side',
      'Entry: \$${trade.entryPrice.toStringAsFixed(4)} | '
          'SL: \$${trade.stopLoss.toStringAsFixed(4)} | '
          'TP: \$${trade.takeProfit.toStringAsFixed(4)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _tradeChannelId,
          _tradeChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_bg_service_small',
        ),
      ),
    );
  }

  Future<void> showTradeExit(Trade trade) async {
    final pnl = trade.realizedPnl ?? 0;
    final pnlStr = pnl >= 0 ? '+\$${pnl.toStringAsFixed(2)}' : '-\$${pnl.abs().toStringAsFixed(2)}';
    final emoji = pnl >= 0 ? '✅' : '❌';
    final mode = trade.isPaper ? '[PAPER] ' : '';
    await _plugin.show(
      (trade.id.hashCode + 1000),
      '$emoji $mode${trade.symbol} Closed',
      'P&L: $pnlStr | Exit: \$${(trade.exitPrice ?? 0).toStringAsFixed(4)}',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _tradeChannelId,
          _tradeChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_bg_service_small',
        ),
      ),
    );
  }

  Future<void> showDailySummary(double pnl, int trades, double winRate) async {
    final pnlStr =
        pnl >= 0 ? '+\$${pnl.toStringAsFixed(2)}' : '-\$${pnl.abs().toStringAsFixed(2)}';
    await _plugin.show(
      9001,
      '📊 Daily Summary',
      'P&L: $pnlStr | Trades: $trades | Win Rate: ${winRate.toStringAsFixed(1)}%',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: 'ic_bg_service_small',
        ),
      ),
    );
  }

  Future<void> showError(String message) async {
    await _plugin.show(
      9002,
      '⚠️ CryptoBot Error',
      message,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          importance: Importance.max,
          priority: Priority.max,
          icon: 'ic_bg_service_small',
        ),
      ),
    );
  }

  Future<void> showProfitTargetReached(double profit) async {
    await _plugin.show(
      9003,
      '🎯 Daily Target Reached!',
      'Profit: +\$${profit.toStringAsFixed(2)} — Engine paused.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          importance: Importance.max,
          priority: Priority.max,
          icon: 'ic_bg_service_small',
        ),
      ),
    );
  }

  Future<void> showMaxLossReached(double loss) async {
    await _plugin.show(
      9004,
      '🛑 Max Daily Loss Hit',
      'Loss: -\$${loss.abs().toStringAsFixed(2)} — Engine stopped.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _alertChannelId,
          _alertChannelName,
          importance: Importance.max,
          priority: Priority.max,
          icon: 'ic_bg_service_small',
        ),
      ),
    );
  }
}
