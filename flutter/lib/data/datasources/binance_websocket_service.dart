import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../core/constants.dart';
import '../../domain/entities/candle.dart';

class BinanceWebSocketService {
  WebSocketChannel? _klineChannel;
  StreamController<Candle>? _klineController;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  bool _disposed = false;
  String? _currentSymbol;
  String? _currentInterval;

  Stream<Candle> subscribeKlines(String symbol, String interval) {
    _currentSymbol = symbol;
    _currentInterval = interval;
    _klineController?.close();
    _klineController = StreamController<Candle>.broadcast();
    _connectKlines(symbol, interval);
    return _klineController!.stream;
  }

  void _connectKlines(String symbol, String interval) {
    if (_disposed) return;

    _klineChannel?.sink.close();
    _pingTimer?.cancel();

    final wsUrl =
        '${AppConstants.binanceWsBaseUrl}/${symbol.toLowerCase()}@kline_$interval';

    try {
      _klineChannel = WebSocketChannel.connect(Uri.parse(wsUrl));

      _klineChannel!.stream.listen(
        (data) {
          if (_disposed) return;
          try {
            final json = jsonDecode(data.toString()) as Map<String, dynamic>;
            final k = json['k'] as Map<String, dynamic>;
            final isClosed = k['x'] as bool;
            if (isClosed) {
              final candle = Candle(
                openTime: k['t'] as int,
                open: double.parse(k['o'].toString()),
                high: double.parse(k['h'].toString()),
                low: double.parse(k['l'].toString()),
                close: double.parse(k['c'].toString()),
                volume: double.parse(k['v'].toString()),
                closeTime: k['T'] as int,
              );
              _klineController?.add(candle);
            }
          } catch (_) {}
        },
        onError: (_) {
          if (!_disposed) _scheduleReconnect();
        },
        onDone: () {
          if (!_disposed) _scheduleReconnect();
        },
      );

      _startPing();
    } catch (_) {
      if (!_disposed) _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_disposed && _currentSymbol != null && _currentInterval != null) {
        _connectKlines(_currentSymbol!, _currentInterval!);
      }
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!_disposed) {
        try {
          _klineChannel?.sink.add('{"method":"ping"}');
        } catch (_) {}
      }
    });
  }

  Stream<Map<String, dynamic>> subscribeUserData(String listenKey) {
    final controller = StreamController<Map<String, dynamic>>.broadcast();
    final wsUrl = '${AppConstants.binanceWsBaseUrl}/$listenKey';

    WebSocketChannel? channel;
    Timer? reconnectTimer;

    void connect() {
      channel?.sink.close();
      try {
        channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        channel!.stream.listen(
          (data) {
            try {
              final json =
                  jsonDecode(data.toString()) as Map<String, dynamic>;
              controller.add(json);
            } catch (_) {}
          },
          onError: (_) {
            if (!controller.isClosed) {
              reconnectTimer = Timer(const Duration(seconds: 5), connect);
            }
          },
          onDone: () {
            if (!controller.isClosed) {
              reconnectTimer = Timer(const Duration(seconds: 5), connect);
            }
          },
        );
      } catch (_) {
        if (!controller.isClosed) {
          reconnectTimer = Timer(const Duration(seconds: 5), connect);
        }
      }
    }

    connect();

    controller.onCancel = () {
      reconnectTimer?.cancel();
      channel?.sink.close();
    };

    return controller.stream;
  }

  void dispose() {
    _disposed = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _klineChannel?.sink.close();
    _klineController?.close();
  }
}
