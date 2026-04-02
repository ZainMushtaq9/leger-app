import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../models.dart';
import 'security_vault_service.dart';

class ProtectedSnapshotDecodeResult {
  const ProtectedSnapshotDecodeResult({
    required this.snapshot,
    required this.wasEncrypted,
    required this.shouldMigrate,
  });

  final Map<String, dynamic> snapshot;
  final bool wasEncrypted;
  final bool shouldMigrate;
}

class ProtectedSnapshotService {
  ProtectedSnapshotService({
    required SecurityVaultService vaultService,
    Cipher? cipher,
  }) : _vaultService = vaultService,
       _cipher = cipher ?? AesGcm.with256bits();

  static const String _keyStorageId = 'hisab_rakho.local.snapshot.key.v1';
  static const String _envelopeKind = 'hisab_rakho.encrypted_snapshot';

  final SecurityVaultService _vaultService;
  final Cipher _cipher;

  Future<ProtectedSnapshotDecodeResult> decode(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Snapshot payload must be a JSON object.');
    }

    final payload = Map<String, dynamic>.from(decoded);
    if (payload['kind'] != _envelopeKind) {
      return ProtectedSnapshotDecodeResult(
        snapshot: payload,
        wasEncrypted: false,
        shouldMigrate: await _vaultService.initialize(),
      );
    }

    final keyBytes = await _readKeyBytes();
    if (keyBytes == null) {
      throw const FormatException(
        'Encrypted local snapshot key is missing on this device.',
      );
    }

    final nonce = _decodeBase64(payload['nonce'] as String? ?? '');
    final cipherText = _decodeBase64(payload['cipherText'] as String? ?? '');
    final mac = _decodeBase64(payload['mac'] as String? ?? '');
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: Mac(mac));
    final clearBytes = await _cipher.decrypt(
      secretBox,
      secretKey: SecretKey(keyBytes),
    );
    final clearText = utf8.decode(clearBytes);
    final snapshot = jsonDecode(clearText);
    if (snapshot is! Map<String, dynamic>) {
      throw const FormatException(
        'Encrypted local snapshot did not contain a valid JSON object.',
      );
    }

    return ProtectedSnapshotDecodeResult(
      snapshot: snapshot,
      wasEncrypted: true,
      shouldMigrate: false,
    );
  }

  Future<String> encode(Map<String, dynamic> snapshot) async {
    final keyBytes = await _readOrCreateKeyBytes();
    if (keyBytes == null) {
      return jsonEncode(snapshot);
    }

    final rawJson = jsonEncode(snapshot);
    final secretBox = await _cipher.encrypt(
      utf8.encode(rawJson),
      secretKey: SecretKey(keyBytes),
    );

    return jsonEncode(<String, dynamic>{
      'kind': _envelopeKind,
      'version': 1,
      'algorithm': 'aes-gcm-256',
      'nonce': _encodeBase64(secretBox.nonce),
      'cipherText': _encodeBase64(secretBox.cipherText),
      'mac': _encodeBase64(secretBox.mac.bytes),
    });
  }

  Future<LocalDataProtectionStatus> status({
    required String storageLabel,
  }) async {
    final vaultReady = await _vaultService.initialize();
    final keyBytes = vaultReady ? await _readKeyBytes() : null;
    return LocalDataProtectionStatus(
      storageLabel: storageLabel,
      encryptedAtRest: keyBytes != null,
      keyStoredSecurely: keyBytes != null,
      usesDeviceVault: vaultReady && _vaultService.isAvailable,
    );
  }

  Future<Uint8List?> _readOrCreateKeyBytes() async {
    if (!await _vaultService.initialize()) {
      return null;
    }

    final existing = await _vaultService.read(_keyStorageId);
    if (existing != null && existing.trim().isNotEmpty) {
      return _decodeBase64(existing);
    }

    final keyBytes = await (await _cipher.newSecretKey()).extractBytes();
    await _vaultService.write(_keyStorageId, _encodeBase64(keyBytes));
    return Uint8List.fromList(keyBytes);
  }

  Future<Uint8List?> _readKeyBytes() async {
    if (!await _vaultService.initialize()) {
      return null;
    }
    final stored = await _vaultService.read(_keyStorageId);
    if (stored == null || stored.trim().isEmpty) {
      return null;
    }
    return _decodeBase64(stored);
  }

  Uint8List _decodeBase64(String value) {
    return Uint8List.fromList(base64Url.decode(base64Url.normalize(value)));
  }

  String _encodeBase64(List<int> bytes) {
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
