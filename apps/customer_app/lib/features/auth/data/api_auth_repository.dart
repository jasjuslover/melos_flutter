import 'package:api_client/api_client.dart' as api;
import 'package:customer_app/core/api_guard.dart';
import 'package:customer_app/core/providers.dart';
import 'package:customer_app/core/token_storage.dart';
import 'package:customer_app/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider(
  (ref) => ApiAuthRepository(
    ref.watch(apiProvider),
    ref.watch(tokenStorageProvider),
  ),
);

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._api, this._tokens);

  final api.Api _api;
  final TokenStorage _tokens;

  @override
  Future<bool> hasSession() async => await _tokens.read() != null;

  @override
  Future<void> login(String email, String password) async {
    final token = await guardApi(() => _api.login(email, password));
    await _tokens.save(token);
  }

  @override
  Future<void> register(String email, String password) async {
    await guardApi(() => _api.register(email, password));
    await login(email, password);
  }

  @override
  Future<void> logout() => _tokens.clear();

  static String _normalize(String email) => email.trim().toLowerCase();
}
