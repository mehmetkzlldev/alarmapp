import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:alarmy/core/di/injection.dart';
import 'package:alarmy/core/network/dio_client.dart';
import 'package:alarmy/core/storage/token_store.dart';

/// Shared, app-wide Riverpod providers for the networking stack.
///
/// These are thin bridges over the canonical get_it/injectable container so the
/// whole app shares ONE configured [Dio] — the instance built by
/// [ApiClientFactory] with the full interceptor chain (auth → refresh → error).
/// Features may depend on either these providers or get_it directly; both
/// resolve to the same singletons.
///
/// Provider names are kept stable so existing feature imports continue to work.

/// Encrypted key/value store (Keychain on iOS, encrypted SharedPreferences on
/// Android). Backed by the DI singleton.
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return getIt<FlutterSecureStorage>();
});

/// The app's secure token store (typed wrapper over [secureStorageProvider]).
final tokenStoreProvider = Provider<TokenStore>((ref) {
  return getIt<TokenStore>();
});

/// The single configured [DioClient] (auth + refresh + error interceptors).
final dioClientProvider = Provider<DioClient>((ref) {
  return getIt<DioClient>();
});

/// Raw [Dio] for the rare consumer that needs it (e.g. multipart uploads to a
/// presigned S3 URL, which bypass the API base path). Same instance the
/// [dioClientProvider] wraps.
final dioProvider = Provider<Dio>((ref) {
  return ref.watch(dioClientProvider).raw;
});
