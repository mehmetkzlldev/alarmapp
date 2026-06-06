import '../../../../core/error/exceptions.dart';
import '../../../../core/network/dio_client.dart';
import '../models/alarm_mission_model.dart';
import '../models/alarm_model.dart';

/// Talks to the alarms REST API. All methods throw the app's domain
/// [Exception]s (translated from Dio by [DioClient]); the repository converts
/// those into [Failure]s.
abstract class AlarmRemoteDataSource {
  Future<List<AlarmModel>> getAlarms();
  Future<AlarmModel> getAlarm(String id);
  Future<AlarmModel> createAlarm(AlarmModel alarm);
  Future<AlarmModel> updateAlarm(String id, AlarmModel alarm);
  Future<void> deleteAlarm(String id);
  Future<AlarmModel> toggleAlarm(String id);

  Future<List<AlarmMissionModel>> getMissions(String alarmId);
  Future<AlarmMissionModel> addMission(
    String alarmId,
    AlarmMissionModel mission,
  );
  Future<void> deleteMission(String alarmId, String missionId);
}

class AlarmRemoteDataSourceImpl implements AlarmRemoteDataSource {
  AlarmRemoteDataSourceImpl(this._client);

  final DioClient _client;

  // Endpoint paths are relative to the base path '/api/v1' configured on Dio.
  static const String _alarms = '/alarms';

  @override
  Future<List<AlarmModel>> getAlarms() async {
    final res = await _client.get<List<dynamic>>(_alarms);
    final data = res.data ?? const [];
    return data
        .map((e) => AlarmModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AlarmModel> getAlarm(String id) async {
    final res = await _client.get<Map<String, dynamic>>('$_alarms/$id');
    return AlarmModel.fromJson(_requireBody(res.data));
  }

  @override
  Future<AlarmModel> createAlarm(AlarmModel alarm) async {
    final res = await _client.post<Map<String, dynamic>>(
      _alarms,
      data: alarm.toCreateJson(),
    );
    return AlarmModel.fromJson(_requireBody(res.data));
  }

  @override
  Future<AlarmModel> updateAlarm(String id, AlarmModel alarm) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '$_alarms/$id',
      data: alarm.toUpdateJson(),
    );
    return AlarmModel.fromJson(_requireBody(res.data));
  }

  @override
  Future<void> deleteAlarm(String id) async {
    await _client.delete<void>('$_alarms/$id');
  }

  @override
  Future<AlarmModel> toggleAlarm(String id) async {
    final res = await _client.patch<Map<String, dynamic>>('$_alarms/$id/toggle');
    return AlarmModel.fromJson(_requireBody(res.data));
  }

  @override
  Future<List<AlarmMissionModel>> getMissions(String alarmId) async {
    final res = await _client.get<List<dynamic>>('$_alarms/$alarmId/missions');
    final data = res.data ?? const [];
    return data
        .map((e) => AlarmMissionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AlarmMissionModel> addMission(
    String alarmId,
    AlarmMissionModel mission,
  ) async {
    final res = await _client.post<Map<String, dynamic>>(
      '$_alarms/$alarmId/missions',
      data: mission.toCreateJson(),
    );
    return AlarmMissionModel.fromJson(_requireBody(res.data));
  }

  @override
  Future<void> deleteMission(String alarmId, String missionId) async {
    await _client.delete<void>('$_alarms/$alarmId/missions/$missionId');
  }

  /// Guards against an empty/204 body where an object was expected.
  Map<String, dynamic> _requireBody(Map<String, dynamic>? body) {
    if (body == null) {
      throw ServerException(message: 'Empty response body');
    }
    return body;
  }
}
