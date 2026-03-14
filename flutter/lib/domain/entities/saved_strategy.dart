import 'dart:convert';
import 'strategy_settings.dart';

class SavedStrategy {
  final String id;
  final String name;
  final DateTime createdAt;
  final StrategySettings settings;

  const SavedStrategy({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.settings,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'settings': settings.toJson(),
      };

  factory SavedStrategy.fromJson(Map<String, dynamic> json) => SavedStrategy(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        settings: StrategySettings.fromJson(
            json['settings'] as Map<String, dynamic>),
      );

  String toJsonString() => jsonEncode(toJson());

  factory SavedStrategy.fromJsonString(String s) =>
      SavedStrategy.fromJson(jsonDecode(s) as Map<String, dynamic>);

  SavedStrategy copyWith({String? name}) => SavedStrategy(
        id: id,
        name: name ?? this.name,
        createdAt: createdAt,
        settings: settings,
      );
}
