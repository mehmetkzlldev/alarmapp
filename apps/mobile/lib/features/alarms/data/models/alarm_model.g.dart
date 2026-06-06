// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlarmModelImpl _$$AlarmModelImplFromJson(Map<String, dynamic> json) =>
    _$AlarmModelImpl(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Alarm',
      time: json['time'] as String,
      repeatDays: (json['repeatDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      isActive: json['isActive'] as bool? ?? true,
      sound: json['sound'] as String? ?? 'default',
      vibration: json['vibration'] as bool? ?? true,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      snoozeEnabled: json['snoozeEnabled'] as bool? ?? true,
      snoozeIntervalMin: (json['snoozeIntervalMin'] as num?)?.toInt() ?? 5,
      snoozeLimit: (json['snoozeLimit'] as num?)?.toInt() ?? 3,
      missions: (json['missions'] as List<dynamic>?)
              ?.map(
                  (e) => AlarmMissionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <AlarmMissionModel>[],
    );

Map<String, dynamic> _$$AlarmModelImplToJson(_$AlarmModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'time': instance.time,
      'repeatDays': instance.repeatDays,
      'isActive': instance.isActive,
      'sound': instance.sound,
      'vibration': instance.vibration,
      'volume': instance.volume,
      'snoozeEnabled': instance.snoozeEnabled,
      'snoozeIntervalMin': instance.snoozeIntervalMin,
      'snoozeLimit': instance.snoozeLimit,
      'missions': instance.missions,
    };
