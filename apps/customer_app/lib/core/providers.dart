import 'package:api_client/api_client.dart';
import 'package:customer_app/core/config.dart';
import 'package:customer_app/core/token_storage.dart';
import 'package:customer_app/features/auth/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);

final apiProvider = Provider<Api>((ref) {
  final tokens = ref.watch(tokenStorageProvider);
  return Api(
    baseUrl: apiBaseUrl,
    readToken: tokens.read,
    onUnauthorized: () =>
        ref.read(authControllerProvider.notifier).sessionExpired(),
  );
});
