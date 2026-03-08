import 'package:hive/hive.dart';

import '../../core/constants.dart';
import '../../domain/entities/trade.dart';
import '../../domain/repositories/trade_repository.dart';
import '../models/trade_hive_model.dart';

class HiveTradeRepository implements TradeRepository {
  Box<TradeHiveModel> get _box => Hive.box<TradeHiveModel>(AppConstants.tradesBoxName);
  Box<TradeHiveModel> get _paperBox =>
      Hive.box<TradeHiveModel>(AppConstants.paperTradesBoxName);

  Box<TradeHiveModel> _getBox(bool isPaper) =>
      isPaper ? _paperBox : _box;

  Trade _fromModel(TradeHiveModel m) => Trade(
        id: m.id,
        symbol: m.symbol,
        side: TradeSide.values.byName(m.side),
        quantity: m.quantity,
        entryPrice: m.entryPrice,
        exitPrice: m.exitPrice,
        stopLoss: m.stopLoss,
        takeProfit: m.takeProfit,
        status: TradeStatus.values.byName(m.status),
        openedAt: m.openedAt,
        closedAt: m.closedAt,
        realizedPnl: m.realizedPnl,
        isPaper: m.isPaper,
        marketType: MarketType.values.byName(m.marketType),
        exchangeOrderId: m.exchangeOrderId,
        timeframe: m.timeframe,
      );

  TradeHiveModel _toModel(Trade t) => TradeHiveModel(
        id: t.id,
        symbol: t.symbol,
        side: t.side.name,
        quantity: t.quantity,
        entryPrice: t.entryPrice,
        exitPrice: t.exitPrice,
        stopLoss: t.stopLoss,
        takeProfit: t.takeProfit,
        status: t.status.name,
        openedAt: t.openedAt,
        closedAt: t.closedAt,
        realizedPnl: t.realizedPnl,
        isPaper: t.isPaper,
        marketType: t.marketType.name,
        exchangeOrderId: t.exchangeOrderId,
        timeframe: t.timeframe,
      );

  @override
  Future<void> saveTrade(Trade trade) async {
    await _getBox(trade.isPaper).put(trade.id, _toModel(trade));
  }

  @override
  Future<List<Trade>> getAllTrades({
    bool paperOnly = false,
    bool liveOnly = false,
  }) async {
    List<TradeHiveModel> models = [];
    if (!liveOnly) {
      models.addAll(_paperBox.values);
    }
    if (!paperOnly) {
      models.addAll(_box.values);
    }
    models.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return models.map(_fromModel).toList();
  }

  @override
  Future<List<Trade>> getActiveTrades({bool? isPaper}) async {
    List<TradeHiveModel> models = [];
    if (isPaper == null || isPaper == true) {
      models.addAll(
        _paperBox.values.where((m) => m.status == TradeStatus.open.name),
      );
    }
    if (isPaper == null || isPaper == false) {
      models.addAll(
        _box.values.where((m) => m.status == TradeStatus.open.name),
      );
    }
    models.sort((a, b) => b.openedAt.compareTo(a.openedAt));
    return models.map(_fromModel).toList();
  }

  @override
  Future<List<Trade>> getClosedTrades({
    bool? isPaper,
    DateTime? from,
    DateTime? to,
  }) async {
    List<TradeHiveModel> models = [];
    if (isPaper == null || isPaper == true) {
      models.addAll(
        _paperBox.values.where((m) => m.status == TradeStatus.closed.name),
      );
    }
    if (isPaper == null || isPaper == false) {
      models.addAll(
        _box.values.where((m) => m.status == TradeStatus.closed.name),
      );
    }

    if (from != null) {
      models = models.where((m) => m.closedAt != null && m.closedAt!.isAfter(from)).toList();
    }
    if (to != null) {
      models = models.where((m) => m.closedAt != null && m.closedAt!.isBefore(to)).toList();
    }

    models.sort((a, b) {
      final aTime = a.closedAt ?? a.openedAt;
      final bTime = b.closedAt ?? b.openedAt;
      return bTime.compareTo(aTime);
    });
    return models.map(_fromModel).toList();
  }

  @override
  Future<Trade?> getTradeById(String id) async {
    final model = _paperBox.get(id) ?? _box.get(id);
    return model != null ? _fromModel(model) : null;
  }

  @override
  Future<void> updateTrade(Trade trade) async {
    await _getBox(trade.isPaper).put(trade.id, _toModel(trade));
  }

  @override
  Future<void> deleteTrade(String id) async {
    await _paperBox.delete(id);
    await _box.delete(id);
  }

  @override
  Future<void> clearAllTrades({bool? isPaper}) async {
    if (isPaper == null || isPaper == true) {
      await _paperBox.clear();
    }
    if (isPaper == null || isPaper == false) {
      await _box.clear();
    }
  }
}
