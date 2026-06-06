/// Offline-first cache contract for alarms.
///
/// The app must be able to *ring* without connectivity, so the canonical alarm
/// list is persisted locally (Isar) and mirrored to the backend when online.
/// This interface intentionally speaks in plain Dart maps so the core layer has
/// no compile-time dependency on a specific feature's Alarm entity — the alarms
/// feature provides the concrete model and an adapter.
///
/// The concrete implementation (Isar-backed) lives in the alarms feature's data
/// layer; keeping the interface in `core/storage` lets the scheduler and other
/// core services depend on it without a feature import cycle.
library;

/// A storage-agnostic snapshot of a single alarm row. Keys mirror the API
/// contract field names so serialization is a pass-through.
typedef AlarmRecord = Map<String, dynamic>;

abstract class LocalAlarmStore {
  /// Returns all cached alarms (active and inactive).
  Future<List<AlarmRecord>> getAll();

  /// Returns a single alarm by server id, or null if not cached.
  Future<AlarmRecord?> getById(String id);

  /// Inserts or updates a single alarm.
  Future<void> upsert(AlarmRecord alarm);

  /// Replaces the entire local cache with [alarms] (used after a full sync).
  Future<void> replaceAll(List<AlarmRecord> alarms);

  /// Removes a single alarm by server id.
  Future<void> delete(String id);

  /// Clears all cached alarms (e.g. on logout).
  Future<void> clear();
}
