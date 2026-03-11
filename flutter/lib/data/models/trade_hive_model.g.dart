// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trade_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TradeHiveModelAdapter extends TypeAdapter<TradeHiveModel> {
  @override
  final int typeId = 1;

  @override
  TradeHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TradeHiveModel(
      id: fields[0] as String,
      symbol: fields[1] as String,
      side: fields[2] as String,
      quantity: fields[3] as double,
      entryPrice: fields[4] as double,
      exitPrice: fields[5] as double?,
      stopLoss: fields[6] as double,
      takeProfit: fields[7] as double,
      status: fields[8] as String,
      openedAt: fields[9] as DateTime,
      closedAt: fields[10] as DateTime?,
      realizedPnl: fields[11] as double?,
      isPaper: fields[12] as bool,
      marketType: fields[13] as String,
      exchangeOrderId: fields[14] as String?,
      timeframe: fields[15] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TradeHiveModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.side)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.entryPrice)
      ..writeByte(5)
      ..write(obj.exitPrice)
      ..writeByte(6)
      ..write(obj.stopLoss)
      ..writeByte(7)
      ..write(obj.takeProfit)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.openedAt)
      ..writeByte(10)
      ..write(obj.closedAt)
      ..writeByte(11)
      ..write(obj.realizedPnl)
      ..writeByte(12)
      ..write(obj.isPaper)
      ..writeByte(13)
      ..write(obj.marketType)
      ..writeByte(14)
      ..write(obj.exchangeOrderId)
      ..writeByte(15)
      ..write(obj.timeframe);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TradeHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
