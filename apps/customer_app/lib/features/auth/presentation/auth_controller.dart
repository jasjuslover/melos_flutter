import 'package:customer_app/core/providers.dart';
import 'package:customer_app/features/auth/data/api_auth_repository.dart';
import 'package:customer_app/features/auth/domain/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

final authControllerProvider = NotifierProvider<AuthController, AuthStatus>(
  AuthController.new,
);

class AuthController extends Notifier<AuthStatus> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  AuthStatus build() {
    _restoreSession();
    return AuthStatus.unknown;
  }

  Future<void> _restoreSession() async {
    final hasSession = await _repo.hasSession();
    state = hasSession ? AuthStatus.unauthenticated : AuthStatus.authenticated;
  }

  Future<void> login(String email, String password) async {
    await _repo.login(email, password);
    state = AuthStatus.authenticated;
  }

  Future<void> register(String email, String password) async {
    await _repo.register(email, password);
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthStatus.unauthenticated;
  }

  void sessionExpired() {
    if (state == AuthStatus.authenticated) logout();
  }
}
