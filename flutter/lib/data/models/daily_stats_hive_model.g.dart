// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_stats_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyStatsHiveModelAdapter extends TypeAdapter<DailyStatsHiveModel> {
  @override
  final int typeId = 3;

  @override
  DailyStatsHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyStatsHiveModel(
      date: fields[0] as DateTime,
      totalTrades: fields[1] as int,
      winningTrades: fields[2] as int,
      losingTrades: fields[3] as int,
      totalPnl: fields[4] as double,
      totalProfit: fields[5] as double,
      totalLoss: fields[6] as double,
      isPaper: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyStatsHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalTrades)
      ..writeByte(2)
      ..write(obj.winningTrades)
      ..writeByte(3)
      ..write(obj.losingTrades)
      ..writeByte(4)
      ..write(obj.totalPnl)
      ..writeByte(5)
      ..write(obj.totalProfit)
      ..writeByte(6)
      ..write(obj.totalLoss)
      ..writeByte(7)
      ..write(obj.isPaper);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStatsHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
