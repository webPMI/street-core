// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'draft_score.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DraftScoreAdapter extends TypeAdapter<DraftScore> {
  @override
  final int typeId = 4;

  @override
  DraftScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DraftScore(
      id: fields[0] as String,
      competitionId: fields[1] as String,
      categoryId: fields[2] as String,
      athleteId: fields[3] as String,
      heatId: fields[4] as String?,
      judgeId: fields[5] as String?,
      criteriaScores: (fields[6] as Map).cast<String, double>(),
      lastModified: fields[7] as DateTime,
      version: fields[8] as int,
    );
  }

  @override
  void write(BinaryWriter writer, DraftScore obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.competitionId)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.athleteId)
      ..writeByte(4)
      ..write(obj.heatId)
      ..writeByte(5)
      ..write(obj.judgeId)
      ..writeByte(6)
      ..write(obj.criteriaScores)
      ..writeByte(7)
      ..write(obj.lastModified)
      ..writeByte(8)
      ..write(obj.version);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DraftScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
