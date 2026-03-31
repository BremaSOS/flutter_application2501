// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roster.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RosterAdapter extends TypeAdapter<Roster> {
  @override
  final int typeId = 0;

  @override
  Roster read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Roster(
      id: fields[0] as String,
      mataPelajaran: fields[1] as String,
      hari: fields[2] as String,
      jamMulai: fields[3] as String,
      jamSelesai: fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Roster obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.mataPelajaran)
      ..writeByte(2)
      ..write(obj.hari)
      ..writeByte(3)
      ..write(obj.jamMulai)
      ..writeByte(4)
      ..write(obj.jamSelesai);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RosterAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}