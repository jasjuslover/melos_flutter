import 'package:customer_app/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus {unknown, authenticated, unauthenticated}

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(AuthController.new);

class AuthController extends Notifier<AuthStatus> {
  @override
  AuthStatus build() {
    _restoreSession();
    return AuthStatus.unknown;
  }

  Future<void> _restoreSession() async {
    final token = await ref.read(tokenStorageProvider).read();
    state = token == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
  }

  Future<void> login(String email, String password) async {
    final token = await ref.read(apiProvider).login(email, password);
    await ref.read(tokenStorageProvider).save(token);
    state = AuthStatus.authenticated;
  }

  Future<void> register(String email, String password) async {
    await ref.read(apiProvider).register(email, password);
    await login(email, password);
  }

  Future<void> logout() async {
    await ref.read(tokenStorageProvider).clear();
    state = AuthStatus.unauthenticated;
  }

  void sessionExpired() {
    if (state == AuthStatus.authenticated) logout();
  }
}