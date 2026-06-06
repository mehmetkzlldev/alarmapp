// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_mission_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlarmMissionModelImpl _$$AlarmMissionModelImplFromJson(
        Map<String, dynamic> json) =>
    _$AlarmMissionModelImpl(
      id: json['id'] as String? ?? '',
      alarmId: json['alarmId'] as String? ?? '',
      missionType: json['missionType'] as String,
      difficulty: json['difficulty'] as String? ?? 'medium',
      orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
      config:
          json['config'] as Map<String, dynamic>? ?? const <String, dynamic>{},
    );

Map<String, dynamic> _$$AlarmMissionModelImplToJson(
        _$AlarmMissionModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'alarmId': instance.alarmId,
      'missionType': instance.missionType,
      'difficulty': instance.difficulty,
      'orderIndex': instance.orderIndex,
      'config': instance.config,
    };
