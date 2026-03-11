import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';

enum HistoryFilter { all, paper, live }

class TradeHistoryState {
  final List<Trade> trades;
  final bool isLoading;
  final String? error;
  final HistoryFilter filter;
  final DateTime? from;
  final DateTime? to;

  const TradeHistoryState({
    this.trades = const [],
    this.isLoading = false,
    this.error,
    this.filter = HistoryFilter.all,
    this.from,
    this.to,
  });

  TradeHistoryState copyWith({
    List<Trade>? trades,
    bool? isLoading,
    String? error,
    HistoryFilter? filter,
    DateTime? from,
    DateTime? to,
  }) =>
      TradeHistoryState(
        trades: trades ?? this.trades,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        filter: filter ?? this.filter,
        from: from ?? this.from,
        to: to ?? this.to,
      );

  double get totalPnl =>
      trades.fold(0.0, (sum, t) => sum + (t.realizedPnl ?? 0));

  double get winRate {
    if (trades.isEmpty) return 0;
    final wins = trades.where((t) => (t.realizedPnl ?? 0) > 0).length;
    return (wins / trades.length) * 100;
  }
}

class TradeHistoryNotifier extends StateNotifier<TradeHistoryState> {
  final TradeRepository _repo;

  TradeHistoryNotifier(this._repo) : super(const TradeHistoryState()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = state.copyWith(isLoading: true);
    try {
      bool? isPaper;
      if (state.filter == HistoryFilter.paper) {
        isPaper = true;
      } else if (state.filter == HistoryFilter.live) {
        isPaper = false;
      }

      final trades = await _repo.getClosedTrades(
        isPaper: isPaper,
        from: state.from,
        to: state.to,
      );
      state = state.copyWith(trades: trades, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> setFilter(HistoryFilter filter) async {
    state = state.copyWith(filter: filter);
    await loadHistory();
  }

  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    state = state.copyWith(from: from, to: to);
    await loadHistory();
  }

  Future<void> clearHistory({bool? isPaper}) async {
    await _repo.clearAllTrades(isPaper: isPaper);
    await loadHistory();
  }

  Future<void> refresh() => loadHistory();
}
