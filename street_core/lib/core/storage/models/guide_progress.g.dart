// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'guide_progress.dart';

// **************************************************************************
// TypeAdapter
// **************************************************************************

class GuideProgressAdapter extends TypeAdapter<GuideProgress> {
  @override
  final int typeId = 6;

  @override
  GuideProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GuideProgress(
      routePath: fields[0] as String,
      isDismissed: fields[1] as bool,
      dismissedAt: fields[2] as DateTime?,
      viewCount: fields[3] as int,
      lastViewedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, GuideProgress obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.routePath)
      ..writeByte(1)
      ..write(obj.isDismissed)
      ..writeByte(2)
      ..write(obj.dismissedAt)
      ..writeByte(3)
      ..write(obj.viewCount)
      ..writeByte(4)
      ..write(obj.lastViewedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GuideProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
