import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../data/models/trade_hive_model.dart';
import '../data/models/strategy_settings_hive_model.dart';
import '../data/models/daily_stats_hive_model.dart';

Future<void> initHive() async {
  final appDir = await getApplicationDocumentsDirectory();
  Hive.init(appDir.path);

  if (!Hive.isAdapterRegistered(TradeHiveModelAdapter().typeId)) {
    Hive.registerAdapter(TradeHiveModelAdapter());
  }
  if (!Hive.isAdapterRegistered(StrategySettingsHiveModelAdapter().typeId)) {
    Hive.registerAdapter(StrategySettingsHiveModelAdapter());
  }
  if (!Hive.isAdapterRegistered(DailyStatsHiveModelAdapter().typeId)) {
    Hive.registerAdapter(DailyStatsHiveModelAdapter());
  }

  await Hive.openBox<TradeHiveModel>('trades');
  await Hive.openBox<TradeHiveModel>('paper_trades');
  await Hive.openBox<StrategySettingsHiveModel>('settings');
  await Hive.openBox<DailyStatsHiveModel>('daily_stats');
}
