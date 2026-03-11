import '../entities/candle.dart';
import '../entities/account_balance.dart';

abstract class BinanceRepository {
  Future<int> getServerTime();
  Future<void> syncServerTime();

  Future<List<Candle>> getKlines(
    String symbol,
    String interval, {
    int limit = 200,
  });

  Future<AccountBalance> getAccountBalance({
    required String apiKey,
    required String secret,
  });

  Future<Map<String, dynamic>> placeOrder({
    required String symbol,
    required String side,
    required String type,
    required double quantity,
    String? price,
    String? stopPrice,
    required String apiKey,
    required String secret,
  });

  Future<void> cancelOrder(
    String symbol,
    int orderId,
    String apiKey,
    String secret,
  );

  Future<List<Map<String, dynamic>>> getOpenOrders(
    String symbol,
    String apiKey,
    String secret,
  );

  Future<String> createListenKey(String apiKey);

  Future<void> keepAliveListenKey(String apiKey, String listenKey);

  Future<Map<String, dynamic>> getExchangeInfo(String symbol);

  Future<bool> testConnectivity();
}
