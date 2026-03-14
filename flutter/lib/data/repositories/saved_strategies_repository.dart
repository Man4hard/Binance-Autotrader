import 'package:hive/hive.dart';
import '../../domain/entities/saved_strategy.dart';

class SavedStrategiesRepository {
  static const _boxName = 'saved_strategies';

  Box<String> get _box => Hive.box<String>(_boxName);

  List<SavedStrategy> getAll() {
    final list = <SavedStrategy>[];
    for (final key in _box.keys) {
      try {
        final json = _box.get(key as String);
        if (json != null) list.add(SavedStrategy.fromJsonString(json));
      } catch (_) {}
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> save(SavedStrategy strategy) async {
    await _box.put(strategy.id, strategy.toJsonString());
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> rename(String id, String newName) async {
    final json = _box.get(id);
    if (json == null) return;
    final strategy = SavedStrategy.fromJsonString(json);
    await _box.put(id, strategy.copyWith(name: newName).toJsonString());
  }
}
