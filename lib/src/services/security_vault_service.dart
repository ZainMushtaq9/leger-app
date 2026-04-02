import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class SecurityVaultService {
  Future<bool> initialize();
  bool get isAvailable;

  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class FlutterSecureStorageSecurityVaultService implements SecurityVaultService {
  FlutterSecureStorageSecurityVaultService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  bool _initialized = false;
  bool _available = false;

  @override
  bool get isAvailable => _available;

  @override
  Future<bool> initialize() async {
    if (_initialized) {
      return _available;
    }
    _initialized = true;

    try {
      await _storage.containsKey(key: '__hisab_rakho_vault_probe__');
      _available = true;
    } catch (_) {
      _available = false;
    }

    return _available;
  }

  @override
  Future<String?> read(String key) async {
    if (!await initialize()) {
      return null;
    }
    return _storage.read(key: key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (!await initialize()) {
      throw StateError('Secure device vault is not available.');
    }
    await _storage.write(key: key, value: value);
  }

  @override
  Future<void> delete(String key) async {
    if (!await initialize()) {
      return;
    }
    await _storage.delete(key: key);
  }
}

class InMemorySecurityVaultService implements SecurityVaultService {
  final Map<String, String> _store = <String, String>{};

  @override
  bool get isAvailable => true;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }
}
