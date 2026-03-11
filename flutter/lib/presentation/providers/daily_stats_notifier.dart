import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/daily_stats.dart';
import '../../domain/repositories/trade_repository.dart';
import '../../domain/usecases/get_daily_stats_usecase.dart';

class DailyStatsState {
  final DailyStats todayStats;
  final DailyStats allTimeStats;
  final bool isLoading;

  const DailyStatsState({
    required this.todayStats,
    required this.allTimeStats,
    this.isLoading = false,
  });

  DailyStatsState copyWith({
    DailyStats? todayStats,
    DailyStats? allTimeStats,
    bool? isLoading,
  }) =>
      DailyStatsState(
        todayStats: todayStats ?? this.todayStats,
        allTimeStats: allTimeStats ?? this.allTimeStats,
        isLoading: isLoading ?? this.isLoading,
      );
}

class DailyStatsNotifier extends StateNotifier<DailyStatsState> {
  final TradeRepository _repo;

  DailyStatsNotifier(this._repo)
      : super(DailyStatsState(
          todayStats: DailyStats.empty(),
          allTimeStats: DailyStats.empty(),
        )) {
    refresh();
  }

  Future<void> refresh({bool isPaper = true}) async {
    state = state.copyWith(isLoading: true);
    try {
      final closedTrades = await _repo.getClosedTrades();
      final today = getDailyStats(closedTrades, isPaper: isPaper);
      final allTime = getAllTimeStats(closedTrades, isPaper: isPaper);
      state = state.copyWith(
        todayStats: today,
        allTimeStats: allTime,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }
}
