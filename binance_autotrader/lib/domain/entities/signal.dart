enum SignalAction { buy, sell, none }

class Signal {
  final String symbol;
  final DateTime timestamp;
  final SignalAction action;
  final int bullScore;
  final int bearScore;
  final int emaScore;
  final int macdScore;
  final int rsiScore;
  final int bbScore;
  final double atrValue;
  final double currentPrice;
  final String timeframe;

  const Signal({
    required this.symbol,
    required this.timestamp,
    required this.action,
    required this.bullScore,
    required this.bearScore,
    required this.emaScore,
    required this.macdScore,
    required this.rsiScore,
    required this.bbScore,
    required this.atrValue,
    required this.currentPrice,
    required this.timeframe,
  });

  factory Signal.empty(String symbol) => Signal(
        symbol: symbol,
        timestamp: DateTime.now().toUtc(),
        action: SignalAction.none,
        bullScore: 0,
        bearScore: 0,
        emaScore: 0,
        macdScore: 0,
        rsiScore: 0,
        bbScore: 0,
        atrValue: 0.0,
        currentPrice: 0.0,
        timeframe: '15m',
      );

  int get totalScore => bullScore + bearScore;

  String get actionLabel {
    switch (action) {
      case SignalAction.buy:
        return 'BUY';
      case SignalAction.sell:
        return 'SELL';
      case SignalAction.none:
        return 'HOLD';
    }
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'timestamp': timestamp.toIso8601String(),
        'action': action.name,
        'bullScore': bullScore,
        'bearScore': bearScore,
        'emaScore': emaScore,
        'macdScore': macdScore,
        'rsiScore': rsiScore,
        'bbScore': bbScore,
        'atrValue': atrValue,
        'currentPrice': currentPrice,
        'timeframe': timeframe,
      };

  factory Signal.fromJson(Map<String, dynamic> json) => Signal(
        symbol: json['symbol'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        action: SignalAction.values.byName(json['action'] as String),
        bullScore: json['bullScore'] as int,
        bearScore: json['bearScore'] as int,
        emaScore: json['emaScore'] as int,
        macdScore: json['macdScore'] as int,
        rsiScore: json['rsiScore'] as int,
        bbScore: json['bbScore'] as int,
        atrValue: (json['atrValue'] as num).toDouble(),
        currentPrice: (json['currentPrice'] as num).toDouble(),
        timeframe: json['timeframe'] as String? ?? '15m',
      );
}
