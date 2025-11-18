// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AlarmModelAdapter extends TypeAdapter<AlarmModel> {
  @override
  final int typeId = 0;

  @override
  AlarmModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmModel(
      id: fields[0] as String,
      scheduledTime: fields[1] as DateTime,
      label: fields[2] as String?,
      isEnabled: fields[3] as bool,
      repeatDays: (fields[4] as List).cast<int>(),
      alarmTone: fields[5] as String,
      challengeType: fields[6] as int,
      challengeDifficulty: fields[7] as int,
      vibrate: fields[8] as bool,
      snoozeMinutes: fields[9] as int,
      audioSource: fields[11] as String,
      radioStationId: fields[12] as String?,
      createdAt: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, AlarmModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.scheduledTime)
      ..writeByte(2)
      ..write(obj.label)
      ..writeByte(3)
      ..write(obj.isEnabled)
      ..writeByte(4)
      ..write(obj.repeatDays)
      ..writeByte(5)
      ..write(obj.alarmTone)
      ..writeByte(6)
      ..write(obj.challengeType)
      ..writeByte(7)
      ..write(obj.challengeDifficulty)
      ..writeByte(8)
      ..write(obj.vibrate)
      ..writeByte(9)
      ..write(obj.snoozeMinutes)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.audioSource)
      ..writeByte(12)
      ..write(obj.radioStationId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
