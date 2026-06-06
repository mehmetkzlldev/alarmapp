import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Central place that builds the [ProviderScope] override list applied at app
/// startup (see `bootstrap.dart`).
///
/// Some feature providers are intentionally declared as overridable *seams*
/// that throw `UnimplementedError` until the app supplies the real, already
/// initialized instance. The two known seams are:
///
///   1. `dioClientProvider` (codegen) in
///      features/alarms/presentation/providers/alarms_provider.dart
///      -> override with `getIt<DioClient>()`.
///   2. `isarProvider` (codegen) in the same file
///      -> override with the opened [Isar] from `IsarDatabase.open([...])`.
///
/// These overrides are wired in [buildProviderOverrides] below. They live
/// behind imports of the feature's GENERATED provider symbols, which only exist
/// after `dart run build_runner build`. Until then this returns an empty list so
/// the skeleton compiles; uncomment the entries once codegen has produced the
/// `.g.dart` files.
///
/// Example (post-codegen):
/// ```dart
/// import 'package:alarmy/core/di/injection.dart';
/// import 'package:alarmy/core/network/dio_client.dart';
/// import 'package:alarmy/core/storage/isar_database.dart';
/// import 'package:alarmy/features/alarms/data/datasources/alarm_local_datasource.dart';
/// import 'package:alarmy/features/alarms/presentation/providers/alarms_provider.dart';
///
/// Future<List<Override>> buildProviderOverrides() async {
///   final isar = await IsarDatabase.open([CachedAlarmSchema]);
///   return [
///     dioClientProvider.overrideWithValue(getIt<DioClient>()),
///     isarProvider.overrideWithValue(isar),
///   ];
/// }
/// ```
Future<List<Override>> buildProviderOverrides() async {
  // No overrides until feature codegen lands; see doc comment above.
  return const <Override>[];
}
