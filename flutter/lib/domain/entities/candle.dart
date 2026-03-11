class Candle {
  final int openTime;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;
  final int closeTime;

  const Candle({
    required this.openTime,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
    required this.closeTime,
  });

  factory Candle.fromBinanceList(List<dynamic> data) {
    return Candle(
      openTime: data[0] as int,
      open: double.parse(data[1].toString()),
      high: double.parse(data[2].toString()),
      low: double.parse(data[3].toString()),
      close: double.parse(data[4].toString()),
      volume: double.parse(data[5].toString()),
      closeTime: data[6] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'openTime': openTime,
        'open': open,
        'high': high,
        'low': low,
        'close': close,
        'volume': volume,
        'closeTime': closeTime,
      };

  factory Candle.fromJson(Map<String, dynamic> json) => Candle(
        openTime: json['openTime'] as int,
        open: (json['open'] as num).toDouble(),
        high: (json['high'] as num).toDouble(),
        low: (json['low'] as num).toDouble(),
        close: (json['close'] as num).toDouble(),
        volume: (json['volume'] as num).toDouble(),
        closeTime: json['closeTime'] as int,
      );

  DateTime get openDateTime =>
      DateTime.fromMillisecondsSinceEpoch(openTime, isUtc: true);

  bool get isBullish => close >= open;

  @override
  String toString() =>
      'Candle(t=${openDateTime.toIso8601String()}, O=$open H=$high L=$low C=$close)';
}
