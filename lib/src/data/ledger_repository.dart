import '../models.dart';

abstract class LedgerRepository {
  Future<AppDataSnapshot> load();

  Future<void> save(AppDataSnapshot snapshot);

  Future<LocalDataProtectionStatus> protectionStatus() async {
    return const LocalDataProtectionStatus(
      storageLabel: 'In-memory test storage',
      encryptedAtRest: false,
      keyStoredSecurely: false,
      usesDeviceVault: false,
    );
  }
}
