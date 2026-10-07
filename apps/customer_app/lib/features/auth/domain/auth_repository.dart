abstract interface class AuthRepository {
  Future<bool> hasSession();

  Future<void> login(String email, String password);

  Future<void> register(String email, String password);

  Future<void> logout();
}
