import 'package:shared_preferences/shared_preferences.dart';

import '../models.dart';
import '../services/protected_snapshot_service.dart';
import '../services/security_vault_service.dart';
import 'ledger_repository.dart';

class SharedPreferencesLedgerRepository implements LedgerRepository {
  SharedPreferencesLedgerRepository({
    SharedPreferences? preferences,
    SecurityVaultService? securityVaultService,
    ProtectedSnapshotService? protectedSnapshotService,
  }) : _preferences = preferences,
       _protectedSnapshotService =
           protectedSnapshotService ??
           ProtectedSnapshotService(
             vaultService:
                 securityVaultService ?? InMemorySecurityVaultService(),
           );

  static const String _snapshotKey = 'hisab_rakho.snapshot.v1';

  SharedPreferences? _preferences;
  final ProtectedSnapshotService _protectedSnapshotService;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<AppDataSnapshot> load() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_snapshotKey);
    if (raw == null || raw.trim().isEmpty) {
      return AppDataSnapshot.empty();
    }

    final decoded = await _protectedSnapshotService.decode(raw);
    final snapshot = AppDataSnapshot.fromJson(decoded.snapshot);
    if (decoded.shouldMigrate) {
      await save(snapshot);
    }
    return snapshot;
  }

  @override
  Future<void> save(AppDataSnapshot snapshot) async {
    final prefs = await _prefs();
    final protected = await _protectedSnapshotService.encode(snapshot.toJson());
    await prefs.setString(_snapshotKey, protected);
  }

  @override
  Future<LocalDataProtectionStatus> protectionStatus() {
    return _protectedSnapshotService.status(
      storageLabel: 'Shared preferences snapshot',
    );
  }
}
