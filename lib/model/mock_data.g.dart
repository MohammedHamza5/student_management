// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mock_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MockResearchAdapter extends TypeAdapter<MockResearch> {
  @override
  final int typeId = 0;

  @override
  MockResearch read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MockResearch(
      fields[0] as String,
    );
  }

  @override
  void write(BinaryWriter writer, MockResearch obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.title);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MockResearchAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
