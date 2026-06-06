import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/exceptions.dart';
import '../models/alarm_model.dart';

/// Offline cache + scheduler-feed for alarms, backed by [SharedPreferences].
///
/// The whole alarm list is persisted as a single JSON array under one key. This
/// keeps the storage schema trivial and works on every platform (mobile + web).
/// The cache is the source of truth the native scheduler relies on when there is
/// no connectivity: the repository writes here on every successful network call
/// and reads here on failure / at boot.
abstract class AlarmLocalDataSource {
  /// All cached alarms (used as the offline fallback and to reschedule on boot).
  Future<List<AlarmModel>> getCachedAlarms();

  /// A single cached alarm, or `null` if not present.
  Future<AlarmModel?> getCachedAlarm(String id);

  /// Replaces the entire cache with [alarms] (so deletions made server-side are
  /// reflected locally after a successful list fetch).
  Future<void> cacheAlarms(List<AlarmModel> alarms);

  /// Inserts or updates a single alarm.
  Future<void> upsertAlarm(AlarmModel alarm);

  /// Removes a single alarm from the cache.
  Future<void> removeAlarm(String id);

  /// Clears the cache (e.g. on logout).
  Future<void> clear();
}

class AlarmLocalDataSourceImpl implements AlarmLocalDataSource {
  /// [prefs] is injectable for tests; defaults to the shared singleton.
  AlarmLocalDataSourceImpl([Future<SharedPreferences>? prefs])
      : _prefs = prefs ?? SharedPreferences.getInstance();

  static const String _key = 'cached_alarms';

  final Future<SharedPreferences> _prefs;

  Future<List<AlarmModel>> _readAll() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <AlarmModel>[];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => AlarmModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _writeAll(List<AlarmModel> alarms) async {
    final prefs = await _prefs;
    final raw = jsonEncode(alarms.map((a) => a.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  @override
  Future<List<AlarmModel>> getCachedAlarms() async {
    try {
      return await _readAll();
    } catch (_) {
      throw CacheException('Failed to read cached alarms');
    }
  }

  @override
  Future<AlarmModel?> getCachedAlarm(String id) async {
    try {
      final all = await _readAll();
      for (final a in all) {
        if (a.id == id) return a;
      }
      return null;
    } catch (_) {
      throw CacheException('Failed to read cached alarm');
    }
  }

  @override
  Future<void> cacheAlarms(List<AlarmModel> alarms) async {
    try {
      await _writeAll(alarms);
    } catch (_) {
      throw CacheException('Failed to cache alarms');
    }
  }

  @override
  Future<void> upsertAlarm(AlarmModel alarm) async {
    try {
      final all = await _readAll();
      final idx = all.indexWhere((a) => a.id == alarm.id);
      if (idx >= 0) {
        all[idx] = alarm;
      } else {
        all.add(alarm);
      }
      await _writeAll(all);
    } catch (_) {
      throw CacheException('Failed to cache alarm');
    }
  }

  @override
  Future<void> removeAlarm(String id) async {
    try {
      final all = await _readAll();
      all.removeWhere((a) => a.id == id);
      await _writeAll(all);
    } catch (_) {
      throw CacheException('Failed to remove cached alarm');
    }
  }

  @override
  Future<void> clear() async {
    try {
      final prefs = await _prefs;
      await prefs.remove(_key);
    } catch (_) {
      throw CacheException('Failed to clear cache');
    }
  }
}
