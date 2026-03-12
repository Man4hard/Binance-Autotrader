import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

import '../../data/datasources/binance_rest_client.dart';
import '../../data/repositories/binance_repository_impl.dart';
import '../../data/repositories/hive_trade_repository.dart';
import '../../data/repositories/hive_settings_repository.dart';
import '../../data/repositories/secure_storage_repository_impl.dart';
import '../../domain/repositories/binance_repository.dart';
import '../../domain/repositories/trade_repository.dart';
import '../../domain/repositories/settings_repository.dart';
import '../../domain/repositories/secure_storage_repository.dart';

final restClientProvider = Provider<BinanceRestClient>(
  (ref) => BinanceRestClient(),
);

final binanceRepositoryProvider = Provider<BinanceRepository>((ref) {
  return BinanceRepositoryImpl(ref.watch(restClientProvider));
});

final tradeRepositoryProvider = Provider<TradeRepository>(
  (ref) => HiveTradeRepository(),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => HiveSettingsRepository(),
);

final secureStorageProvider = Provider<SecureStorageRepository>(
  (ref) => const SecureStorageRepositoryImpl(),
);

final backgroundServiceProvider = Provider<FlutterBackgroundService>(
  (ref) => FlutterBackgroundService(),
);
