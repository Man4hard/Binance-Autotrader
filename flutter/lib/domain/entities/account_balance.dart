class AssetBalance {
  final String asset;
  final double free;
  final double locked;

  const AssetBalance({
    required this.asset,
    required this.free,
    required this.locked,
  });

  double get total => free + locked;

  factory AssetBalance.fromJson(Map<String, dynamic> json) => AssetBalance(
        asset: json['asset'] as String,
        free: double.parse(json['free'].toString()),
        locked: double.parse(json['locked'].toString()),
      );

  Map<String, dynamic> toJson() => {
        'asset': asset,
        'free': free,
        'locked': locked,
      };
}

class AccountBalance {
  final List<AssetBalance> balances;
  final DateTime fetchedAt;
  final bool canTrade;

  const AccountBalance({
    required this.balances,
    required this.fetchedAt,
    this.canTrade = true,
  });

  double get usdtFree {
    final usdt = balances.where((b) => b.asset == 'USDT').toList();
    return usdt.isEmpty ? 0.0 : usdt.first.free;
  }

  double get usdtTotal {
    final usdt = balances.where((b) => b.asset == 'USDT').toList();
    return usdt.isEmpty ? 0.0 : usdt.first.total;
  }

  AssetBalance? getBalance(String asset) {
    final result = balances.where((b) => b.asset == asset).toList();
    return result.isEmpty ? null : result.first;
  }

  factory AccountBalance.fromBinanceJson(Map<String, dynamic> json) {
    final rawBalances = (json['balances'] as List<dynamic>)
        .map((b) => AssetBalance.fromJson(b as Map<String, dynamic>))
        .where((b) => b.total > 0)
        .toList();

    return AccountBalance(
      balances: rawBalances,
      fetchedAt: DateTime.now().toUtc(),
      canTrade: json['canTrade'] as bool? ?? true,
    );
  }

  factory AccountBalance.empty() => AccountBalance(
        balances: const [],
        fetchedAt: DateTime.now().toUtc(),
        canTrade: false,
      );
}
