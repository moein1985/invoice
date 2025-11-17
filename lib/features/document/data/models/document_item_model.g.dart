// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentItemModelAdapter extends TypeAdapter<DocumentItemModel> {
  @override
  final int typeId = 4;

  @override
  DocumentItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentItemModel(
      id: fields[0] as String,
      productName: fields[1] as String,
      quantity: fields[2] as int,
      unit: fields[3] as String,
      purchasePrice: fields[4] as double,
      sellPrice: fields[5] as double,
      totalPrice: fields[6] as double,
      profitPercentage: fields[7] as double,
      supplier: fields[8] as String,
      description: fields[9] as String?,
      isManualPrice: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentItemModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.productName)
      ..writeByte(2)
      ..write(obj.quantity)
      ..writeByte(3)
      ..write(obj.unit)
      ..writeByte(4)
      ..write(obj.purchasePrice)
      ..writeByte(5)
      ..write(obj.sellPrice)
      ..writeByte(6)
      ..write(obj.totalPrice)
      ..writeByte(7)
      ..write(obj.profitPercentage)
      ..writeByte(8)
      ..write(obj.supplier)
      ..writeByte(9)
      ..write(obj.description)
      ..writeByte(10)
      ..write(obj.isManualPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
