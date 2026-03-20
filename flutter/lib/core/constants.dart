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

  static const List<String> allTradingPairs = [
    'BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'ADAUSDT',
    'XRPUSDT', 'DOGEUSDT', 'DOTUSDT', 'MATICUSDT', 'LTCUSDT',
    'AVAXUSDT', 'LINKUSDT', 'UNIUSDT', 'ATOMUSDT', 'ETCUSDT',
    'XLMUSDT', 'ALGOUSDT', 'VETUSDT', 'FILUSDT', 'TRXUSDT',
    'FTMUSDT', 'SANDUSDT', 'MANAUSDT', 'AXSUSDT', 'GALAUSDT',
    'NEARUSDT', 'FLOWUSDT', 'ICPUSDT', 'THETAUSDT', 'XTZUSDT',
    'HBARUSDT', 'EGLDUSDT', 'AAVEUSDT', 'MKRUSDT', 'COMPUSDT',
    'SUSHIUSDT', 'CRVUSDT', 'YFIUSDT', '1INCHUSDT', 'SNXUSDT',
    'ENJUSDT', 'BATUSDT', 'ZILUSDT', 'ZECUSDT', 'DASHUSDT',
    'NEOUSDT', 'IOSTUSDT', 'ONTUSDT', 'WAVESUSDT', 'QTUMUSDT',
    'KSMUSDT', 'SHIBUSDT', 'RUNEUSDT', 'LUNAUSDT', 'STXUSDT',
    'CAKEUSDT', 'CHZUSDT', 'HOTUSDT', 'RVNUSDT', 'SCUSDT',
    'XMRUSDT', 'BCHUSDT', 'EOSUSDT', 'OPUSDT', 'ARBUSDT',
    'APTUSDT', 'SUIUSDT', 'PEPEUSDT', 'FLOKIUSDT', 'BONKUSDT',
    'WLDUSDT', 'INJUSDT', 'SEIUSDT', 'TIAUSDT', 'JUPUSDT',
    'PYTHUSDT', 'STRKUSDT', 'DYMUSDT', 'ALTUSDT', 'RONINUSDT',
    'FETUSDT', 'RNDRUSDT', 'GRTUSDT', 'IMXUSDT', 'LPTUSDT',
    'ANKRUSDT', 'STORJUSDT', 'COTIUSDT', 'REQUSDT', 'POWRUSDT',
    'GMTUSDT', 'SPELLUSDT', 'JASMYUSDT', 'XECUSDT', 'CFXUSDT',
    'MANTAUSDT', 'ZROUSDT', 'EIGENUSDT', 'SCRUSDT', 'REZUSDT',
    'BBUSDT', 'NOTUSDT', 'IOUSDT', 'ZKUSDT', 'LISTAUSDT',
  ];

  static const List<String> availableTimeframes = ['1m', '5m', '15m', '1h', '4h'];

  // Changed from '15m' to '1h' — 1h timeframe showed 100% win rate in backtests
  static const String defaultTimeframe = '1h';

  static const double defaultPaperBalance = 1000.0;
  static const double defaultDailyProfitTarget = 10.0;
  static const double defaultMaxDailyLoss = 20.0;
  static const int defaultMaxDailyTrades = 10;
  static const double defaultRiskPercent = 0.01;
  static const double defaultMinRR = 1.5;
  static const double defaultAtrMultiplier = 1.5;
  static const int defaultMinScoreToEnter = 2;

  static const Map<String, bool> defaultActiveIndicators = {
    'ema': true,
    'macd': true,
    'rsi': true,
    'bb': true,
    'vsa': true,
  };
}
