// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:alarmy/core/di/register_module.dart' as _i348;
import 'package:alarmy/core/network/dio_client.dart' as _i234;
import 'package:alarmy/core/storage/token_store.dart' as _i162;
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt init(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  final registerModule = _$RegisterModule();
  gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage);
  gh.lazySingleton<_i162.TokenStore>(
      () => _i162.SecureTokenStore(gh<_i558.FlutterSecureStorage>()));
  gh.lazySingleton<_i234.DioClient>(
      () => registerModule.dioClient(gh<_i162.TokenStore>()));
  gh.lazySingleton<_i361.Dio>(() => registerModule.dio(gh<_i234.DioClient>()));
  return getIt;
}

class _$RegisterModule extends _i348.RegisterModule {}
