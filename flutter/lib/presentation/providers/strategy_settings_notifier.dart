import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/strategy_settings.dart';
import '../../domain/repositories/settings_repository.dart';
import 'repository_providers.dart';

class StrategySettingsState {
  final StrategySettings settings;
  final bool isLoading;
  final String? error;

  const StrategySettingsState({
    required this.settings,
    this.isLoading = false,
    this.error,
  });

  StrategySettingsState copyWith({
    StrategySettings? settings,
    bool? isLoading,
    String? error,
  }) =>
      StrategySettingsState(
        settings: settings ?? this.settings,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

class StrategySettingsNotifier extends Notifier<StrategySettingsState> {
  late SettingsRepository _repo;

  @override
  StrategySettingsState build() {
    _repo = ref.read(settingsRepositoryProvider);
    Future(() => loadSettings());
    return const StrategySettingsState(settings: StrategySettings());
  }

  Future<void> loadSettings() async {
    state = state.copyWith(isLoading: true);
    try {
      final settings = await _repo.getSettings();
      state = state.copyWith(settings: settings, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> updateSettings(StrategySettings settings) async {
    state = state.copyWith(settings: settings);
    await _repo.saveSettings(settings);
  }

  Future<void> togglePaperMode(bool value) async {
    final updated = state.settings.copyWith(isPaperMode: value);
    await updateSettings(updated);
  }

  Future<void> toggleEngine(bool running) async {
    final updated = state.settings.copyWith(isEngineRunning: running);
    await updateSettings(updated);
  }
}
