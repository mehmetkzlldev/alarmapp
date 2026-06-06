import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/platform/alarm_scheduler.dart';
import '../../../../core/platform/alarm_scheduler_impl.dart';
import '../../../../core/usecase/usecase.dart';
import '../../data/datasources/alarm_local_datasource.dart';
import '../../data/datasources/alarm_remote_datasource.dart';
import '../../data/repositories/alarm_repository_impl.dart';
import '../../domain/entities/alarm_entity.dart';
import '../../domain/repositories/alarm_repository.dart';
import '../../domain/usecases/create_alarm.dart';
import '../../domain/usecases/delete_alarm.dart';
import '../../domain/usecases/get_alarms.dart';
import '../../domain/usecases/toggle_alarm.dart';
import '../../domain/usecases/update_alarm.dart';

part 'alarms_provider.g.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
//
// [dioClientProvider] is deliberately declared as an overridable "seam". The
// app bootstrap (main.dart) MUST override it with the real, already-initialized
// DioClient via ProviderScope(overrides: [...]). Throwing here makes a missing
// override fail loudly in tests/dev rather than silently using a half-configured
// client. The local cache datasource needs no seam — it uses SharedPreferences.
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
DioClient dioClient(DioClientRef ref) {
  // Resolve the single app-configured DioClient (base URL + auth/refresh/error
  // interceptor chain) from the get_it container. No ProviderScope override
  // needed — the whole app shares this one instance.
  return getIt<DioClient>();
}

/// The native alarm scheduler bridge. Defaults to the real platform-channel
/// implementation; can be overridden with a fake in widget tests.
@Riverpod(keepAlive: true)
AlarmScheduler alarmScheduler(AlarmSchedulerRef ref) => AlarmSchedulerImpl();

// ---------------------------------------------------------------------------
// Data layer providers
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
AlarmRemoteDataSource alarmRemoteDataSource(AlarmRemoteDataSourceRef ref) {
  return AlarmRemoteDataSourceImpl(ref.watch(dioClientProvider));
}

@Riverpod(keepAlive: true)
AlarmLocalDataSource alarmLocalDataSource(AlarmLocalDataSourceRef ref) {
  return AlarmLocalDataSourceImpl();
}

@Riverpod(keepAlive: true)
AlarmRepository alarmRepository(AlarmRepositoryRef ref) {
  return AlarmRepositoryImpl(
    remote: ref.watch(alarmRemoteDataSourceProvider),
    local: ref.watch(alarmLocalDataSourceProvider),
    scheduler: ref.watch(alarmSchedulerProvider),
  );
}

// ---------------------------------------------------------------------------
// Use-case providers (thin, so widgets/notifiers don't construct them)
// ---------------------------------------------------------------------------

@riverpod
GetAlarms getAlarmsUseCase(GetAlarmsUseCaseRef ref) =>
    GetAlarms(ref.watch(alarmRepositoryProvider));

@riverpod
CreateAlarm createAlarmUseCase(CreateAlarmUseCaseRef ref) =>
    CreateAlarm(ref.watch(alarmRepositoryProvider));

@riverpod
UpdateAlarm updateAlarmUseCase(UpdateAlarmUseCaseRef ref) =>
    UpdateAlarm(ref.watch(alarmRepositoryProvider));

@riverpod
DeleteAlarm deleteAlarmUseCase(DeleteAlarmUseCaseRef ref) =>
    DeleteAlarm(ref.watch(alarmRepositoryProvider));

@riverpod
ToggleAlarm toggleAlarmUseCase(ToggleAlarmUseCaseRef ref) =>
    ToggleAlarm(ref.watch(alarmRepositoryProvider));

// ---------------------------------------------------------------------------
// AlarmList notifier
//
// Holds the list of alarms as AsyncValue and exposes optimistic mutations.
// The UI watches [alarmsNotifierProvider]; actions call the methods below.
// ---------------------------------------------------------------------------

@riverpod
class AlarmsNotifier extends _$AlarmsNotifier {
  @override
  Future<List<AlarmEntity>> build() async {
    return _load();
  }

  Future<List<AlarmEntity>> _load() async {
    final result = await ref.read(getAlarmsUseCaseProvider).call(const NoParams());
    return result.fold(
      (failure) => throw failure, // surfaced as AsyncError(failure)
      (alarms) => _sorted(alarms),
    );
  }

  /// Pull-to-refresh / manual reload.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_load);
  }

  /// Toggles an alarm with an optimistic UI update; reverts on failure.
  Future<Either<Object, AlarmEntity>> toggle(String id) async {
    final previous = state.valueOrNull;
    // Optimistic flip.
    if (previous != null) {
      state = AsyncData([
        for (final a in previous)
          if (a.id == id) a.copyWith(isActive: !a.isActive) else a,
      ]);
    }

    final result = await ref.read(toggleAlarmUseCaseProvider).call(
          ToggleAlarmParams(id: id),
        );

    return result.fold(
      (failure) {
        // Revert.
        if (previous != null) state = AsyncData(previous);
        return Left(failure);
      },
      (updated) {
        _replace(updated);
        return Right(updated);
      },
    );
  }

  /// Deletes an alarm with an optimistic removal; reverts on failure.
  Future<Either<Object, Unit>> delete(String id) async {
    final previous = state.valueOrNull;
    if (previous != null) {
      state = AsyncData(previous.where((a) => a.id != id).toList());
    }

    final result = await ref.read(deleteAlarmUseCaseProvider).call(
          DeleteAlarmParams(id: id),
        );

    return result.fold(
      (failure) {
        if (previous != null) state = AsyncData(previous);
        return Left(failure);
      },
      (_) => const Right(unit),
    );
  }

  /// Inserts a newly-created alarm into the in-memory list (called by the
  /// create screen after a successful save so the list updates instantly).
  void addCreated(AlarmEntity alarm) {
    final current = state.valueOrNull ?? const <AlarmEntity>[];
    state = AsyncData(_sorted([...current, alarm]));
  }

  void _replace(AlarmEntity updated) {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncData(_sorted([
      for (final a in current)
        if (a.id == updated.id) updated else a,
    ]));
  }

  /// Sort by time-of-day so the list reads top-to-bottom like a clock.
  List<AlarmEntity> _sorted(List<AlarmEntity> alarms) {
    final copy = [...alarms];
    copy.sort((a, b) {
      final am = a.hourMinute;
      final bm = b.hourMinute;
      final aMins = am.hour * 60 + am.minute;
      final bMins = bm.hour * 60 + bm.minute;
      return aMins.compareTo(bMins);
    });
    return copy;
  }
}

/// Convenience derived provider: the next alarm that will fire (used by the
/// dashboard "next alarm" card). Returns the active alarm whose time-of-day is
/// soonest from now; `null` when there are no active alarms.
@riverpod
AlarmEntity? nextAlarm(NextAlarmRef ref) {
  final alarms = ref.watch(alarmsNotifierProvider).valueOrNull;
  if (alarms == null) return null;

  final active = alarms.where((a) => a.isActive).toList();
  if (active.isEmpty) return null;

  final now = DateTime.now();
  final nowMins = now.hour * 60 + now.minute;

  // Minutes until each alarm's next time-of-day occurrence (today or tomorrow).
  int minutesUntil(AlarmEntity a) {
    final hm = a.hourMinute;
    final mins = hm.hour * 60 + hm.minute;
    final delta = mins - nowMins;
    return delta > 0 ? delta : delta + 24 * 60;
  }

  active.sort((a, b) => minutesUntil(a).compareTo(minutesUntil(b)));
  return active.first;
}
