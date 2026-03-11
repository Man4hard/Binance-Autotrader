import '../entities/strategy_settings.dart';

abstract class SettingsRepository {
  Future<void> saveSettings(StrategySettings settings);
  Future<StrategySettings> getSettings();
}
