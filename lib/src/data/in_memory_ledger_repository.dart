import '../models.dart';
import 'ledger_repository.dart';

class InMemoryLedgerRepository implements LedgerRepository {
  InMemoryLedgerRepository({AppDataSnapshot? initialSnapshot})
    : _snapshot = initialSnapshot ?? AppDataSnapshot.empty();

  AppDataSnapshot _snapshot;

  @override
  Future<AppDataSnapshot> load() async {
    return _snapshot;
  }

  @override
  Future<void> save(AppDataSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<LocalDataProtectionStatus> protectionStatus() async {
    return const LocalDataProtectionStatus(
      storageLabel: 'In-memory test storage',
      encryptedAtRest: false,
      keyStoredSecurely: false,
      usesDeviceVault: false,
    );
  }
}
