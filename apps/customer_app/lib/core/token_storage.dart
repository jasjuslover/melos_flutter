import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;
  static const _key = 'access_token';

  String? _cache;
  bool _loaded = false;

  Future<String?> read() async {
    if (!_loaded) {
      _cache = await _storage.read(key: _key);
      _loaded = true;
    }

    return _cache;
  }

  Future<void> save(String token) async {
    _cache = token;
    _loaded = true;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cache = null;
    _loaded = false;
    await _storage.delete(key: _key);
  }
}
