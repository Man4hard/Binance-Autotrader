class AppConstants {
  static const String binanceBaseUrl = 'https://api.binance.com';
  static const String binanceFuturesBaseUrl = 'https://fapi.binance.com';
  static const String binanceWsBaseUrl = 'wss://stream.binance.com:9443/ws';
  static const String binanceFuturesWsBaseUrl = 'wss://fstream.binance.com/ws';

  static const int defaultRecvWindow = 10000;
  static const int maxRateWeightPerMinute = 1200;
  static const int rateWeightWarningThreshold = 900;

  static const String tradesBoxName = 'trades';
  static const String settingsBoxName = 'settings';
  static const String paperTradesBoxName = 'paper_trades';
  static const String dailyStatsBoxName = 'daily_stats';

  static const String apiKeyStorageKey = 'binance_api_key';
  static const String secretKeyStorageKey = 'binance_secret_key';

  static const String notificationChannelId = 'cryptobot_trading_engine';
  static const String notificationChannelName = 'Trading Engine';
  static const int engineNotificationId = 888;
  static const int tradeNotificationId = 100;
  static const int errorNotificationId = 200;

  static const List<String> defaultSymbols = [
    'BTCUSDT',
    'ETHUSDT',
    'BNBUSDT',
    'SOLUSDT',
    'ADAUSDT',
  ];

  static const List<String> availableTimeframes = ['1m', '5m', '15m', '1h', '4h'];
  static const String defaultTimeframe = '15m';

  static const double defaultPaperBalance = 1000.0;
  static const double defaultDailyProfitTarget = 10.0;
  static const double defaultMaxDailyLoss = 20.0;
  static const int defaultMaxDailyTrades = 10;
  static const double defaultRiskPercent = 0.01;
  static const double defaultMinRR = 1.5;
  static const double defaultAtrMultiplier = 1.5;
}
