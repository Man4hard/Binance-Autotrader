import 'dart:convert';
import 'package:hive/hive.dart';

import '../../core/constants.dart';
import '../../domain/entities/strategy_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import '../models/strategy_settings_hive_model.dart';

class HiveSettingsRepository implements SettingsRepository {
  static const String _settingsKey = 'current_settings';

  Box<StrategySettingsHiveModel> get _box =>
      Hive.box<StrategySettingsHiveModel>(AppConstants.settingsBoxName);

  String _encodeActiveIndicators(Map<String, bool> map) {
    return jsonEncode(map.map((k, v) => MapEntry(k, v)));
  }

  Map<String, bool> _decodeActiveIndicators(String? json) {
    if (json == null || json.isEmpty) {
      return Map<String, bool>.from(AppConstants.defaultActiveIndicators);
    }
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final result = Map<String, bool>.from(AppConstants.defaultActiveIndicators);
      for (final e in decoded.entries) {
        result[e.key] = e.value as bool? ?? true;
      }
      return result;
    } catch (_) {
      return Map<String, bool>.from(AppConstants.defaultActiveIndicators);
    }
  }

  @override
  Future<void> saveSettings(StrategySettings settings) async {
    final model = StrategySettingsHiveModel(
      symbols: List<String>.from(settings.symbols),
      timeframe: settings.timeframe,
      emaPeriod1: settings.emaPeriod1,
      emaPeriod2: settings.emaPeriod2,
      emaPeriod3: settings.emaPeriod3,
      macdFast: settings.macdFast,
      macdSlow: settings.macdSlow,
      macdSignal: settings.macdSignal,
      rsiPeriod: settings.rsiPeriod,
      rsiNeutralLow: settings.rsiNeutralLow,
      rsiNeutralHigh: settings.rsiNeutralHigh,
      rsiOverbought: settings.rsiOverbought,
      rsiOversold: settings.rsiOversold,
      bbPeriod: settings.bbPeriod,
      bbStdDev: settings.bbStdDev,
      atrPeriod: settings.atrPeriod,
      atrMultiplier: settings.atrMultiplier,
      minRR: settings.minRR,
      dailyProfitTarget: settings.dailyProfitTarget,
      maxDailyLoss: settings.maxDailyLoss,
      maxDailyTrades: settings.maxDailyTrades,
      riskPercent: settings.riskPercent,
      isPaperMode: settings.isPaperMode,
      isEngineRunning: settings.isEngineRunning,
      autoStartOnBoot: settings.autoStartOnBoot,
      marketType: settings.marketType.name,
      minScoreToEnter: settings.minScoreToEnter,
      activeIndicatorsJson: _encodeActiveIndicators(settings.activeIndicators),
    );
    await _box.put(_settingsKey, model);
  }

  @override
  Future<StrategySettings> getSettings() async {
    final model = _box.get(_settingsKey);
    if (model == null) return const StrategySettings();

    return StrategySettings(
      symbols: List<String>.from(model.symbols),
      timeframe: model.timeframe,
      emaPeriod1: model.emaPeriod1,
      emaPeriod2: model.emaPeriod2,
      emaPeriod3: model.emaPeriod3,
      macdFast: model.macdFast,
      macdSlow: model.macdSlow,
      macdSignal: model.macdSignal,
      rsiPeriod: model.rsiPeriod,
      rsiNeutralLow: model.rsiNeutralLow,
      rsiNeutralHigh: model.rsiNeutralHigh,
      rsiOverbought: model.rsiOverbought,
      rsiOversold: model.rsiOversold,
      bbPeriod: model.bbPeriod,
      bbStdDev: model.bbStdDev,
      atrPeriod: model.atrPeriod,
      atrMultiplier: model.atrMultiplier,
      minRR: model.minRR,
      dailyProfitTarget: model.dailyProfitTarget,
      maxDailyLoss: model.maxDailyLoss,
      maxDailyTrades: model.maxDailyTrades,
      riskPercent: model.riskPercent,
      isPaperMode: model.isPaperMode,
      isEngineRunning: model.isEngineRunning,
      autoStartOnBoot: model.autoStartOnBoot,
      marketType: MarketTypeMode.values.byName(model.marketType),
      minScoreToEnter: model.minScoreToEnter,
      activeIndicators: _decodeActiveIndicators(model.activeIndicatorsJson),
    );
  }
}
