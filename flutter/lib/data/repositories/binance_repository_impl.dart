import '../../domain/entities/candle.dart';
import '../../domain/entities/account_balance.dart';
import '../../domain/repositories/binance_repository.dart';
import '../datasources/binance_rest_client.dart';

class BinanceRepositoryImpl implements BinanceRepository {
  final BinanceRestClient _client;

  BinanceRepositoryImpl(this._client);

  @override
  Future<int> getServerTime() => _client.getServerTime();

  @override
  Future<void> syncServerTime() => _client.syncServerTime();

  @override
  Future<List<Candle>> getKlines(
    String symbol,
    String interval, {
    int limit = 200,
  }) =>
      _client.getKlines(symbol, interval, limit: limit);

  @override
  Future<AccountBalance> getAccountBalance({
    required String apiKey,
    required String secret,
  }) =>
      _client.getAccountInfo(apiKey: apiKey, secret: secret);

  @override
  Future<Map<String, dynamic>> placeOrder({
    required String symbol,
    required String side,
    required String type,
    required double quantity,
    String? price,
    String? stopPrice,
    required String apiKey,
    required String secret,
  }) =>
      _client.placeOrder(
        symbol: symbol,
        side: side,
        type: type,
        quantity: quantity,
        price: price,
        stopPrice: stopPrice,
        apiKey: apiKey,
        secret: secret,
      );

  @override
  Future<void> cancelOrder(
    String symbol,
    int orderId,
    String apiKey,
    String secret,
  ) =>
      _client.cancelOrder(symbol, orderId, apiKey, secret);

  @override
  Future<List<Map<String, dynamic>>> getOpenOrders(
    String symbol,
    String apiKey,
    String secret,
  ) =>
      _client.getOpenOrders(symbol, apiKey, secret);

  @override
  Future<String> createListenKey(String apiKey) =>
      _client.createListenKey(apiKey);

  @override
  Future<void> keepAliveListenKey(String apiKey, String listenKey) =>
      _client.keepAliveListenKey(apiKey, listenKey);

  @override
  Future<Map<String, dynamic>> getExchangeInfo(String symbol) =>
      _client.getExchangeInfo(symbol);

  @override
  Future<bool> testConnectivity() => _client.testConnectivity();
}
