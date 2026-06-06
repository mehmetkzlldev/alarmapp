import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:alarmy/core/di/injection.config.dart';

/// The single global service locator. Feature classes annotated with
/// `@injectable` / `@LazySingleton` are wired into this container by the
/// generated [init] (run `dart run build_runner build`).
final GetIt getIt = GetIt.instance;

/// Initializes dependency injection. Call once at startup, before `runApp`.
///
/// [environment] lets us register environment-specific implementations (e.g.
/// `Environment.dev` vs `Environment.prod`) — see [Env].
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: false,
  asExtension: false,
)
Future<void> configureDependencies({String? environment}) async {
  await init(getIt, environment: environment);
}

/// Named environments for `@Environment(...)`-scoped registrations.
abstract class Env {
  static const String dev = 'dev';
  static const String prod = 'prod';
}
