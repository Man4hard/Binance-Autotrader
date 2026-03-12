import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

import '../../core/constants.dart';
import '../../domain/entities/app_error.dart';
import '../../domain/entities/candle.dart';
import '../../domain/entities/account_balance.dart';

class BinanceRestClient {
  final String _baseUrl;
  int _serverTimeOffset = 0;
  int _usedWeight = 0;
  DateTime _lastWeightReset = DateTime.now().toUtc();

  BinanceRestClient({String? baseUrl})
      : _baseUrl = baseUrl ?? AppConstants.binanceBaseUrl;

  int get currentWeight => _usedWeight;

  String _sign(String queryString, String secret) {
    final key = utf8.encode(secret);
    final msg = utf8.encode(queryString);
    final hmac = Hmac(sha256, key);
    return hmac.convert(msg).toString();
  }

  int _getTimestamp() {
    return DateTime.now().toUtc().millisecondsSinceEpoch + _serverTimeOffset;
  }

  void _updateWeight(http.Response response) {
    final now = DateTime.now().toUtc();
    if (now.difference(_lastWeightReset).inMinutes >= 1) {
      _usedWeight = 0;
      _lastWeightReset = now;
    }
    final w = response.headers['x-mbx-used-weight-1m'];
    if (w != null) {
      _usedWeight = int.tryParse(w) ?? _usedWeight;
    }
  }

  void _checkRateLimit() {
    if (_usedWeight >= AppConstants.rateWeightWarningThreshold) {
      throw const RateLimitError(
        'Approaching rate limit',
        retryAfterMs: 60000,
      );
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    _updateWeight(response);
    if (response.statusCode == 429) {
      final retryAfter = response.headers['retry-after'];
      throw RateLimitError(
        'Rate limit exceeded',
        retryAfterMs:
            retryAfter != null ? int.parse(retryAfter) * 1000 : 60000,
      );
    }
    if (response.statusCode == 418) {
      throw const BinanceApiError('IP banned', code: 418);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        throw BinanceApiError(
          body['msg']?.toString() ?? 'Unknown error',
          code: body['code'] as int? ?? response.statusCode,
        );
      } catch (e) {
        if (e is BinanceApiError) rethrow;
        throw NetworkError(
          'HTTP ${response.statusCode}: ${response.body}',
          statusCode: response.statusCode,
        );
      }
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> syncServerTime() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v3/time'),
      );
      final body = _handleResponse(response);
      final serverTime = body['serverTime'] as int;
      _serverTimeOffset =
          serverTime - DateTime.now().toUtc().millisecondsSinceEpoch;
    } catch (e) {
      _serverTimeOffset = 0;
    }
  }

  Future<int> getServerTime() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v3/time'),
    );
    final body = _handleResponse(response);
    return body['serverTime'] as int;
  }

  Future<bool> testConnectivity() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/v3/ping'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<List<Candle>> getKlines(
    String symbol,
    String interval, {
    int limit = 200,
  }) async {
    _checkRateLimit();
    final uri = Uri.parse('$_baseUrl/api/v3/klines').replace(
      queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'limit': limit.toString(),
      },
    );

    final response = await http.get(uri);
    _updateWeight(response);

    if (response.statusCode != 200) {
      throw NetworkError(
        'Failed to fetch klines: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }

    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => Candle.fromBinanceList(item as List<dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> getExchangeInfo(String symbol) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v3/exchangeInfo')
          .replace(queryParameters: {'symbol': symbol}),
    );
    return _handleResponse(response);
  }

  /// Returns all active USDT spot symbols from Binance, sorted alphabetically.
  /// Uses /api/v3/ticker/price (weight 4) — lightweight ~30 KB response.
  Future<List<String>> getAllUsdtSymbols() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v3/ticker/price'),
    );
    _updateWeight(response);
    if (response.statusCode != 200) {
      throw NetworkError(
        'Failed to fetch symbol list',
        statusCode: response.statusCode,
      );
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    final symbols = data
        .map((e) => e['symbol'] as String)
        .where((s) => s.endsWith('USDT'))
        .toList()
      ..sort();
    return symbols;
  }

  /// Returns the latest price for a single symbol. Very lightweight (weight 2).
  Future<double> getLatestPrice(String symbol) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/v3/ticker/price').replace(
        queryParameters: {'symbol': symbol},
      ),
    );
    _updateWeight(response);
    if (response.statusCode != 200) {
      throw NetworkError(
        'Failed to fetch price for $symbol',
        statusCode: response.statusCode,
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return double.parse(data['price'] as String);
  }

  Future<AccountBalance> getAccountInfo({
    required String apiKey,
    required String secret,
  }) async {
    _checkRateLimit();
    final timestamp = _getTimestamp();
    final queryString =
        'recvWindow=${AppConstants.defaultRecvWindow}&timestamp=$timestamp';
    final signature = _sign(queryString, secret);

    final uri = Uri.parse('$_baseUrl/api/v3/account').replace(
      queryParameters: {
        'recvWindow': AppConstants.defaultRecvWindow.toString(),
        'timestamp': timestamp.toString(),
        'signature': signature,
      },
    );

    final response = await http.get(
      uri,
      headers: {'X-MBX-APIKEY': apiKey},
    );
    final body = _handleResponse(response);
    return AccountBalance.fromBinanceJson(body);
  }

  Future<String> createListenKey(String apiKey) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/v3/userDataStream'),
      headers: {'X-MBX-APIKEY': apiKey},
    );
    final body = _handleResponse(response);
    return body['listenKey'] as String;
  }

  Future<void> keepAliveListenKey(String apiKey, String listenKey) async {
    await http.put(
      Uri.parse('$_baseUrl/api/v3/userDataStream')
          .replace(queryParameters: {'listenKey': listenKey}),
      headers: {'X-MBX-APIKEY': apiKey},
    );
  }

  Future<Map<String, dynamic>> placeOrder({
    required String symbol,
    required String side,
    required String type,
    required double quantity,
    String? price,
    String? stopPrice,
    required String apiKey,
    required String secret,
  }) async {
    _checkRateLimit();
    final timestamp = _getTimestamp();

    final params = <String, String>{
      'symbol': symbol,
      'side': side.toUpperCase(),
      'type': type.toUpperCase(),
      'quantity': quantity.toStringAsFixed(8),
      'recvWindow': AppConstants.defaultRecvWindow.toString(),
      'timestamp': timestamp.toString(),
    };

    if (price != null) params['price'] = price;
    if (stopPrice != null) params['stopPrice'] = stopPrice;
    if (type.toUpperCase() == 'LIMIT') {
      params['timeInForce'] = 'GTC';
    }

    final queryString = params.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    params['signature'] = _sign(queryString, secret);

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v3/order'),
      headers: {
        'X-MBX-APIKEY': apiKey,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: params,
    );
    return _handleResponse(response);
  }

  Future<void> cancelOrder(
    String symbol,
    int orderId,
    String apiKey,
    String secret,
  ) async {
    final timestamp = _getTimestamp();
    final queryString =
        'symbol=$symbol&orderId=$orderId&recvWindow=${AppConstants.defaultRecvWindow}&timestamp=$timestamp';
    final signature = _sign(queryString, secret);

    await http.delete(
      Uri.parse('$_baseUrl/api/v3/order').replace(
        queryParameters: {
          'symbol': symbol,
          'orderId': orderId.toString(),
          'recvWindow': AppConstants.defaultRecvWindow.toString(),
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      ),
      headers: {'X-MBX-APIKEY': apiKey},
    );
  }

  Future<List<Map<String, dynamic>>> getOpenOrders(
    String symbol,
    String apiKey,
    String secret,
  ) async {
    final timestamp = _getTimestamp();
    final queryString =
        'symbol=$symbol&recvWindow=${AppConstants.defaultRecvWindow}&timestamp=$timestamp';
    final signature = _sign(queryString, secret);

    final response = await http.get(
      Uri.parse('$_baseUrl/api/v3/openOrders').replace(
        queryParameters: {
          'symbol': symbol,
          'recvWindow': AppConstants.defaultRecvWindow.toString(),
          'timestamp': timestamp.toString(),
          'signature': signature,
        },
      ),
      headers: {'X-MBX-APIKEY': apiKey},
    );

    _updateWeight(response);
    if (response.statusCode != 200) {
      throw NetworkError('Failed to get open orders',
          statusCode: response.statusCode);
    }
    final data = jsonDecode(response.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
