// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strategy_settings_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StrategySettingsHiveModelAdapter
    extends TypeAdapter<StrategySettingsHiveModel> {
  @override
  final int typeId = 2;

  @override
  StrategySettingsHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StrategySettingsHiveModel(
      symbols: (fields[0] as List).cast<String>(),
      timeframe: fields[1] as String,
      emaPeriod1: fields[2] as int,
      emaPeriod2: fields[3] as int,
      emaPeriod3: fields[4] as int,
      macdFast: fields[5] as int,
      macdSlow: fields[6] as int,
      macdSignal: fields[7] as int,
      rsiPeriod: fields[8] as int,
      rsiNeutralLow: fields[9] as double,
      rsiNeutralHigh: fields[10] as double,
      rsiOverbought: fields[11] as double,
      rsiOversold: fields[12] as double,
      bbPeriod: fields[13] as int,
      bbStdDev: fields[14] as double,
      atrPeriod: fields[15] as int,
      atrMultiplier: fields[16] as double,
      minRR: fields[17] as double,
      dailyProfitTarget: fields[18] as double,
      maxDailyLoss: fields[19] as double,
      maxDailyTrades: fields[20] as int,
      riskPercent: fields[21] as double,
      isPaperMode: fields[22] as bool,
      isEngineRunning: fields[23] as bool,
      autoStartOnBoot: fields[24] as bool,
      marketType: fields[25] as String,
      minScoreToEnter: fields[26] as int,
      activeIndicatorsJson: fields[27] as String? ?? '{}',
    );
  }

  @override
  void write(BinaryWriter writer, StrategySettingsHiveModel obj) {
    writer
      ..writeByte(28)
      ..writeByte(0)
      ..write(obj.symbols)
      ..writeByte(1)
      ..write(obj.timeframe)
      ..writeByte(2)
      ..write(obj.emaPeriod1)
      ..writeByte(3)
      ..write(obj.emaPeriod2)
      ..writeByte(4)
      ..write(obj.emaPeriod3)
      ..writeByte(5)
      ..write(obj.macdFast)
      ..writeByte(6)
      ..write(obj.macdSlow)
      ..writeByte(7)
      ..write(obj.macdSignal)
      ..writeByte(8)
      ..write(obj.rsiPeriod)
      ..writeByte(9)
      ..write(obj.rsiNeutralLow)
      ..writeByte(10)
      ..write(obj.rsiNeutralHigh)
      ..writeByte(11)
      ..write(obj.rsiOverbought)
      ..writeByte(12)
      ..write(obj.rsiOversold)
      ..writeByte(13)
      ..write(obj.bbPeriod)
      ..writeByte(14)
      ..write(obj.bbStdDev)
      ..writeByte(15)
      ..write(obj.atrPeriod)
      ..writeByte(16)
      ..write(obj.atrMultiplier)
      ..writeByte(17)
      ..write(obj.minRR)
      ..writeByte(18)
      ..write(obj.dailyProfitTarget)
      ..writeByte(19)
      ..write(obj.maxDailyLoss)
      ..writeByte(20)
      ..write(obj.maxDailyTrades)
      ..writeByte(21)
      ..write(obj.riskPercent)
      ..writeByte(22)
      ..write(obj.isPaperMode)
      ..writeByte(23)
      ..write(obj.isEngineRunning)
      ..writeByte(24)
      ..write(obj.autoStartOnBoot)
      ..writeByte(25)
      ..write(obj.marketType)
      ..writeByte(26)
      ..write(obj.minScoreToEnter)
      ..writeByte(27)
      ..write(obj.activeIndicatorsJson);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StrategySettingsHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
