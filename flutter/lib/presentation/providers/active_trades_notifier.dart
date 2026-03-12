import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import 'repository_providers.dart';

class ActiveTradesState {
  final List<Trade> trades;
  final bool isLoading;
  final String? error;

  const ActiveTradesState({
    this.trades = const [],
    this.isLoading = false,
    this.error,
  });

  ActiveTradesState copyWith({
    List<Trade>? trades,
    bool? isLoading,
    String? error,
  }) =>
      ActiveTradesState(
        trades: trades ?? this.trades,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class ActiveTradesNotifier extends Notifier<ActiveTradesState> {
  late TradeRepository _repo;

  @override
  ActiveTradesState build() {
    _repo = ref.read(tradeRepositoryProvider);
    Future(() => loadTrades());
    return const ActiveTradesState();
  }

  Future<void> loadTrades({bool? isPaper}) async {
    state = state.copyWith(isLoading: true);
    try {
      final trades = await _repo.getActiveTrades(isPaper: isPaper);
      state = state.copyWith(trades: trades, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> closeTrade(Trade trade, double exitPrice) async {
    final pnl = trade.side == TradeSide.buy
        ? (exitPrice - trade.entryPrice) * trade.quantity
        : (trade.entryPrice - exitPrice) * trade.quantity;

    final closed = trade.copyWith(
      status: TradeStatus.closed,
      exitPrice: exitPrice,
      closedAt: DateTime.now().toUtc(),
      realizedPnl: pnl,
    );
    await _repo.updateTrade(closed);
    await loadTrades();
  }

  Future<void> refresh({bool? isPaper}) => loadTrades(isPaper: isPaper);

  void addTrade(Trade trade) {
    state = state.copyWith(trades: [trade, ...state.trades]);
  }

  void removeTrade(String id) {
    state = state.copyWith(
      trades: state.trades.where((t) => t.id != id).toList(),
    );
  }
}
