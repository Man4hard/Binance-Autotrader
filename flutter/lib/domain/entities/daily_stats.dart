class DailyStats {
  final DateTime date;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final double totalPnl;
  final double totalProfit;
  final double totalLoss;
  final bool isPaper;

  const DailyStats({
    required this.date,
    this.totalTrades = 0,
    this.winningTrades = 0,
    this.losingTrades = 0,
    this.totalPnl = 0.0,
    this.totalProfit = 0.0,
    this.totalLoss = 0.0,
    this.isPaper = true,
  });

  double get winRate =>
      totalTrades == 0 ? 0.0 : (winningTrades / totalTrades) * 100;

  double get profitFactor =>
      totalLoss == 0 ? (totalProfit > 0 ? double.infinity : 1.0) : totalProfit / totalLoss.abs();

  DailyStats copyWith({
    DateTime? date,
    int? totalTrades,
    int? winningTrades,
    int? losingTrades,
    double? totalPnl,
    double? totalProfit,
    double? totalLoss,
    bool? isPaper,
  }) {
    return DailyStats(
      date: date ?? this.date,
      totalTrades: totalTrades ?? this.totalTrades,
      winningTrades: winningTrades ?? this.winningTrades,
      losingTrades: losingTrades ?? this.losingTrades,
      totalPnl: totalPnl ?? this.totalPnl,
      totalProfit: totalProfit ?? this.totalProfit,
      totalLoss: totalLoss ?? this.totalLoss,
      isPaper: isPaper ?? this.isPaper,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'totalTrades': totalTrades,
        'winningTrades': winningTrades,
        'losingTrades': losingTrades,
        'totalPnl': totalPnl,
        'totalProfit': totalProfit,
        'totalLoss': totalLoss,
        'isPaper': isPaper,
      };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
        date: DateTime.parse(json['date'] as String),
        totalTrades: json['totalTrades'] as int? ?? 0,
        winningTrades: json['winningTrades'] as int? ?? 0,
        losingTrades: json['losingTrades'] as int? ?? 0,
        totalPnl: (json['totalPnl'] as num?)?.toDouble() ?? 0.0,
        totalProfit: (json['totalProfit'] as num?)?.toDouble() ?? 0.0,
        totalLoss: (json['totalLoss'] as num?)?.toDouble() ?? 0.0,
        isPaper: json['isPaper'] as bool? ?? true,
      );

  factory DailyStats.empty({bool isPaper = true}) => DailyStats(
        date: DateTime.now().toUtc(),
        isPaper: isPaper,
      );
}
