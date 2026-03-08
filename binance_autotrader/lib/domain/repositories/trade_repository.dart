import '../entities/trade.dart';

abstract class TradeRepository {
  Future<void> saveTrade(Trade trade);
  Future<List<Trade>> getAllTrades({bool paperOnly = false, bool liveOnly = false});
  Future<List<Trade>> getActiveTrades({bool? isPaper});
  Future<List<Trade>> getClosedTrades({bool? isPaper, DateTime? from, DateTime? to});
  Future<Trade?> getTradeById(String id);
  Future<void> updateTrade(Trade trade);
  Future<void> deleteTrade(String id);
  Future<void> clearAllTrades({bool? isPaper});
}
