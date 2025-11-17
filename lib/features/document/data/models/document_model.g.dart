// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DocumentModelAdapter extends TypeAdapter<DocumentModel> {
  @override
  final int typeId = 3;

  @override
  DocumentModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DocumentModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      documentNumber: fields[2] as String,
      documentTypeString: fields[3] as String,
      customerId: fields[4] as String,
      documentDate: fields[5] as DateTime,
      items: (fields[6] as List).cast<DocumentItemModel>(),
      totalAmount: fields[7] as double,
      discount: fields[8] as double,
      finalAmount: fields[9] as double,
      statusString: fields[10] as String,
      notes: fields[11] as String?,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
      attachment: fields[14] as String?,
      defaultProfitPercentage: fields[15] as double,
      convertedFromId: fields[16] as String?,
      approvalStatus: fields[17] as String,
      approvedBy: fields[18] as String?,
      approvedAt: fields[19] as DateTime?,
      rejectionReason: fields[20] as String?,
      requiresApproval: fields[21] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DocumentModel obj) {
    writer
      ..writeByte(22)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.documentNumber)
      ..writeByte(3)
      ..write(obj.documentTypeString)
      ..writeByte(4)
      ..write(obj.customerId)
      ..writeByte(5)
      ..write(obj.documentDate)
      ..writeByte(6)
      ..write(obj.items)
      ..writeByte(7)
      ..write(obj.totalAmount)
      ..writeByte(8)
      ..write(obj.discount)
      ..writeByte(9)
      ..write(obj.finalAmount)
      ..writeByte(10)
      ..write(obj.statusString)
      ..writeByte(11)
      ..write(obj.notes)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt)
      ..writeByte(14)
      ..write(obj.attachment)
      ..writeByte(15)
      ..write(obj.defaultProfitPercentage)
      ..writeByte(16)
      ..write(obj.convertedFromId)
      ..writeByte(17)
      ..write(obj.approvalStatus)
      ..writeByte(18)
      ..write(obj.approvedBy)
      ..writeByte(19)
      ..write(obj.approvedAt)
      ..writeByte(20)
      ..write(obj.rejectionReason)
      ..writeByte(21)
      ..write(obj.requiresApproval);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DocumentModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
