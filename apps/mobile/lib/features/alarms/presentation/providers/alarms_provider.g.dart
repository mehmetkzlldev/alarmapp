// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarms_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$dioClientHash() => r'9c30c06b476f03cff1fa1c8e40a1fe513e0cedcb';

/// See also [dioClient].
@ProviderFor(dioClient)
final dioClientProvider = Provider<DioClient>.internal(
  dioClient,
  name: r'dioClientProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$dioClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DioClientRef = ProviderRef<DioClient>;
String _$alarmSchedulerHash() => r'd6e9bd3791b942c0fb618bfcca60d1919d2c76f0';

/// The native alarm scheduler bridge. Defaults to the real platform-channel
/// implementation; can be overridden with a fake in widget tests.
///
/// Copied from [alarmScheduler].
@ProviderFor(alarmScheduler)
final alarmSchedulerProvider = Provider<AlarmScheduler>.internal(
  alarmScheduler,
  name: r'alarmSchedulerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alarmSchedulerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlarmSchedulerRef = ProviderRef<AlarmScheduler>;
String _$alarmRemoteDataSourceHash() =>
    r'64aafefa90730c21db52947e968b09cd79ae5c82';

/// See also [alarmRemoteDataSource].
@ProviderFor(alarmRemoteDataSource)
final alarmRemoteDataSourceProvider = Provider<AlarmRemoteDataSource>.internal(
  alarmRemoteDataSource,
  name: r'alarmRemoteDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alarmRemoteDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlarmRemoteDataSourceRef = ProviderRef<AlarmRemoteDataSource>;
String _$alarmLocalDataSourceHash() =>
    r'da92e14e60549e93cbcb59d7b4d882160c426a68';

/// See also [alarmLocalDataSource].
@ProviderFor(alarmLocalDataSource)
final alarmLocalDataSourceProvider = Provider<AlarmLocalDataSource>.internal(
  alarmLocalDataSource,
  name: r'alarmLocalDataSourceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alarmLocalDataSourceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlarmLocalDataSourceRef = ProviderRef<AlarmLocalDataSource>;
String _$alarmRepositoryHash() => r'a85e4d8a63835d834eeb0ea495cee47ad18d606b';

/// See also [alarmRepository].
@ProviderFor(alarmRepository)
final alarmRepositoryProvider = Provider<AlarmRepository>.internal(
  alarmRepository,
  name: r'alarmRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alarmRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AlarmRepositoryRef = ProviderRef<AlarmRepository>;
String _$getAlarmsUseCaseHash() => r'981508948389d55bab3469f439cc172d3ac18ce5';

/// See also [getAlarmsUseCase].
@ProviderFor(getAlarmsUseCase)
final getAlarmsUseCaseProvider = AutoDisposeProvider<GetAlarms>.internal(
  getAlarmsUseCase,
  name: r'getAlarmsUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getAlarmsUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetAlarmsUseCaseRef = AutoDisposeProviderRef<GetAlarms>;
String _$createAlarmUseCaseHash() =>
    r'41211a13ca0b898549a2e87eeb7000ed554fd1a3';

/// See also [createAlarmUseCase].
@ProviderFor(createAlarmUseCase)
final createAlarmUseCaseProvider = AutoDisposeProvider<CreateAlarm>.internal(
  createAlarmUseCase,
  name: r'createAlarmUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$createAlarmUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CreateAlarmUseCaseRef = AutoDisposeProviderRef<CreateAlarm>;
String _$updateAlarmUseCaseHash() =>
    r'646df98e35867328089821dfb1d8812c329fd5d5';

/// See also [updateAlarmUseCase].
@ProviderFor(updateAlarmUseCase)
final updateAlarmUseCaseProvider = AutoDisposeProvider<UpdateAlarm>.internal(
  updateAlarmUseCase,
  name: r'updateAlarmUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$updateAlarmUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UpdateAlarmUseCaseRef = AutoDisposeProviderRef<UpdateAlarm>;
String _$deleteAlarmUseCaseHash() =>
    r'8e11d2c1f5524d4cda1e845f296c95c58c20463f';

/// See also [deleteAlarmUseCase].
@ProviderFor(deleteAlarmUseCase)
final deleteAlarmUseCaseProvider = AutoDisposeProvider<DeleteAlarm>.internal(
  deleteAlarmUseCase,
  name: r'deleteAlarmUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$deleteAlarmUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DeleteAlarmUseCaseRef = AutoDisposeProviderRef<DeleteAlarm>;
String _$toggleAlarmUseCaseHash() =>
    r'1a1f3fd3a55dd2f723ba504f5336cd4326f842e7';

/// See also [toggleAlarmUseCase].
@ProviderFor(toggleAlarmUseCase)
final toggleAlarmUseCaseProvider = AutoDisposeProvider<ToggleAlarm>.internal(
  toggleAlarmUseCase,
  name: r'toggleAlarmUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$toggleAlarmUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ToggleAlarmUseCaseRef = AutoDisposeProviderRef<ToggleAlarm>;
String _$nextAlarmHash() => r'a82aacfea1afb9ea2b498fd206696006b6a14547';

/// Convenience derived provider: the next alarm that will fire (used by the
/// dashboard "next alarm" card). Returns the active alarm whose time-of-day is
/// soonest from now; `null` when there are no active alarms.
///
/// Copied from [nextAlarm].
@ProviderFor(nextAlarm)
final nextAlarmProvider = AutoDisposeProvider<AlarmEntity?>.internal(
  nextAlarm,
  name: r'nextAlarmProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$nextAlarmHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NextAlarmRef = AutoDisposeProviderRef<AlarmEntity?>;
String _$alarmsNotifierHash() => r'42862aea79c6cc09d15218352fafdb7acabb607c';

/// See also [AlarmsNotifier].
@ProviderFor(AlarmsNotifier)
final alarmsNotifierProvider = AutoDisposeAsyncNotifierProvider<AlarmsNotifier,
    List<AlarmEntity>>.internal(
  AlarmsNotifier.new,
  name: r'alarmsNotifierProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$alarmsNotifierHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AlarmsNotifier = AutoDisposeAsyncNotifier<List<AlarmEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
