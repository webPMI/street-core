// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_score.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OfflineScoreAdapter extends TypeAdapter<OfflineScore> {
  @override
  final int typeId = 1;

  @override
  OfflineScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineScore(
      id: fields[0] as String,
      competitionId: fields[1] as String,
      categoryId: fields[2] as String,
      participantId: fields[3] as String,
      judgeId: fields[4] as String,
      criteriaScores: (fields[5] as Map).cast<String, double>(),
      comments: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      syncAttempts: fields[8] as int,
      lastSyncError: fields[9] as String?,
      isUpdate: fields[10] as bool,
      existingScoreId: fields[11] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineScore obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.competitionId)
      ..writeByte(2)
      ..write(obj.categoryId)
      ..writeByte(3)
      ..write(obj.participantId)
      ..writeByte(4)
      ..write(obj.judgeId)
      ..writeByte(5)
      ..write(obj.criteriaScores)
      ..writeByte(6)
      ..write(obj.comments)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.syncAttempts)
      ..writeByte(9)
      ..write(obj.lastSyncError)
      ..writeByte(10)
      ..write(obj.isUpdate)
      ..writeByte(11)
      ..write(obj.existingScoreId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
