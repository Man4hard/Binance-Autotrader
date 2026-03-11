enum SignalAction { buy, sell, none }

class Signal {
  final String symbol;
  final DateTime timestamp;
  final SignalAction action;
  final int bullScore;
  final int bearScore;
  final int maxScore;
  // Per-indicator scores: null = indicator disabled, -1/0/1 = bear/neutral/bull
  final int? emaScore;
  final int? macdScore;
  final int? rsiScore;
  final int? bbScore;
  final int? vsaScore;
  final String vsaPattern;
  final bool? vsaBullish;
  final double? vsaVolRatio;
  final double? vsaSpreadRatio;
  final double? vsaClosePos;
  final double atrValue;
  final double currentPrice;
  final double rsi;
  final double ema9;
  final double ema21;
  final double ema50;
  final double macdHist;
  final String timeframe;

  const Signal({
    required this.symbol,
    required this.timestamp,
    required this.action,
    required this.bullScore,
    required this.bearScore,
    required this.maxScore,
    required this.emaScore,
    required this.macdScore,
    required this.rsiScore,
    required this.bbScore,
    required this.vsaScore,
    this.vsaPattern = 'Normal',
    this.vsaBullish,
    this.vsaVolRatio,
    this.vsaSpreadRatio,
    this.vsaClosePos,
    required this.atrValue,
    required this.currentPrice,
    required this.rsi,
    required this.ema9,
    required this.ema21,
    required this.ema50,
    required this.macdHist,
    required this.timeframe,
  });

  factory Signal.empty(String symbol) => Signal(
        symbol: symbol,
        timestamp: DateTime.now().toUtc(),
        action: SignalAction.none,
        bullScore: 0,
        bearScore: 0,
        maxScore: 5,
        emaScore: 0,
        macdScore: 0,
        rsiScore: 0,
        bbScore: 0,
        vsaScore: 0,
        vsaPattern: 'Normal',
        vsaBullish: null,
        vsaVolRatio: null,
        vsaSpreadRatio: null,
        vsaClosePos: null,
        atrValue: 0.0,
        currentPrice: 0.0,
        rsi: 50.0,
        ema9: 0.0,
        ema21: 0.0,
        ema50: 0.0,
        macdHist: 0.0,
        timeframe: '1h',
      );

  int get activeScore => bullScore > bearScore ? bullScore : bearScore;

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
        'maxScore': maxScore,
        'emaScore': emaScore,
        'macdScore': macdScore,
        'rsiScore': rsiScore,
        'bbScore': bbScore,
        'vsaScore': vsaScore,
        'vsaPattern': vsaPattern,
        'vsaBullish': vsaBullish,
        'vsaVolRatio': vsaVolRatio,
        'vsaSpreadRatio': vsaSpreadRatio,
        'vsaClosePos': vsaClosePos,
        'atrValue': atrValue,
        'currentPrice': currentPrice,
        'rsi': rsi,
        'ema9': ema9,
        'ema21': ema21,
        'ema50': ema50,
        'macdHist': macdHist,
        'timeframe': timeframe,
      };

  factory Signal.fromJson(Map<String, dynamic> json) => Signal(
        symbol: json['symbol'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        action: SignalAction.values.byName(json['action'] as String),
        bullScore: json['bullScore'] as int? ?? 0,
        bearScore: json['bearScore'] as int? ?? 0,
        maxScore: json['maxScore'] as int? ?? 5,
        emaScore: json['emaScore'] as int?,
        macdScore: json['macdScore'] as int?,
        rsiScore: json['rsiScore'] as int?,
        bbScore: json['bbScore'] as int?,
        vsaScore: json['vsaScore'] as int?,
        vsaPattern: json['vsaPattern'] as String? ?? 'Normal',
        vsaBullish: json['vsaBullish'] as bool?,
        vsaVolRatio: (json['vsaVolRatio'] as num?)?.toDouble(),
        vsaSpreadRatio: (json['vsaSpreadRatio'] as num?)?.toDouble(),
        vsaClosePos: (json['vsaClosePos'] as num?)?.toDouble(),
        atrValue: (json['atrValue'] as num?)?.toDouble() ?? 0.0,
        currentPrice: (json['currentPrice'] as num?)?.toDouble() ?? 0.0,
        rsi: (json['rsi'] as num?)?.toDouble() ?? 50.0,
        ema9: (json['ema9'] as num?)?.toDouble() ?? 0.0,
        ema21: (json['ema21'] as num?)?.toDouble() ?? 0.0,
        ema50: (json['ema50'] as num?)?.toDouble() ?? 0.0,
        macdHist: (json['macdHist'] as num?)?.toDouble() ?? 0.0,
        timeframe: json['timeframe'] as String? ?? '1h',
      );
}
