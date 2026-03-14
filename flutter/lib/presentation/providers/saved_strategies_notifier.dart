import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/saved_strategies_repository.dart';
import '../../domain/entities/saved_strategy.dart';
import '../../domain/entities/strategy_settings.dart';

class SavedStrategiesNotifier extends Notifier<List<SavedStrategy>> {
  late SavedStrategiesRepository _repo;

  @override
  List<SavedStrategy> build() {
    _repo = SavedStrategiesRepository();
    return _repo.getAll();
  }

  Future<void> saveStrategy(String name, StrategySettings settings) async {
    final strategy = SavedStrategy(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      settings: settings,
    );
    await _repo.save(strategy);
    state = _repo.getAll();
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }

  Future<void> rename(String id, String newName) async {
    await _repo.rename(id, newName);
    state = _repo.getAll();
  }
}

final savedStrategiesProvider =
    NotifierProvider<SavedStrategiesNotifier, List<SavedStrategy>>(
        SavedStrategiesNotifier.new);
