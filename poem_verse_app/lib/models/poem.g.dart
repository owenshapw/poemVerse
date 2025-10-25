// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'poem.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PoemAdapter extends TypeAdapter<Poem> {
  @override
  final int typeId = 0;

  @override
  Poem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Poem(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      imageUrl: fields[3] as String?,
      createdAt: fields[4] as DateTime,
      synced: fields[5] as bool,
      imageOffsetX: fields[6] as double?,
      imageOffsetY: fields[7] as double?,
      imageScale: fields[8] as double?,
      author: fields[9] as String?,
      textPositionX: fields[10] as double?,
      textPositionY: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Poem obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.synced)
      ..writeByte(6)
      ..write(obj.imageOffsetX)
      ..writeByte(7)
      ..write(obj.imageOffsetY)
      ..writeByte(8)
      ..write(obj.imageScale)
      ..writeByte(9)
      ..write(obj.author)
      ..writeByte(10)
      ..write(obj.textPositionX)
      ..writeByte(11)
      ..write(obj.textPositionY);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PoemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
