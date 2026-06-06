import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import 'package:alarmy/core/network/api_client.dart';
import 'package:alarmy/core/network/dio_client.dart';
import 'package:alarmy/core/storage/token_store.dart';

/// Registers third-party / externally-constructed singletons that injectable
/// can't annotate directly (their classes live in packages we don't own).
///
/// The generated container reads this module to know how to build a
/// [FlutterSecureStorage], the configured [Dio]/[DioClient], etc.
@module
abstract class RegisterModule {
  /// Hardware-backed secure storage. On Android we opt into EncryptedSharedPrefs
  /// so values survive across reinstalls-with-backup correctly and use the
  /// Keystore; on iOS the default Keychain accessibility is first-unlock.
  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
        iOptions: IOSOptions(
          accessibility: KeychainAccessibility.first_unlock,
        ),
      );

  /// The fully-configured Dio wrapper (auth + refresh + error interceptors).
  /// Built from [ApiClientFactory] so all interceptor wiring lives in one place.
  @lazySingleton
  DioClient dioClient(TokenStore tokenStore) =>
      ApiClientFactory(tokenStore).create();

  /// Convenience: expose the raw [Dio] for the rare consumer that needs it
  /// (e.g. multipart uploads to presigned S3 URLs bypass the API base path).
  @lazySingleton
  Dio dio(DioClient client) => client.raw;
}
