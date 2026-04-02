import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../models.dart';
import '../services/protected_snapshot_service.dart';
import '../services/security_vault_service.dart';
import 'ledger_repository.dart';

class LocalDatabaseLedgerRepository implements LedgerRepository {
  LocalDatabaseLedgerRepository({
    SharedPreferences? preferences,
    DatabaseFactory? databaseFactoryOverride,
    SecurityVaultService? securityVaultService,
    ProtectedSnapshotService? protectedSnapshotService,
  }) : _preferences = preferences,
       _databaseFactory = databaseFactoryOverride ?? databaseFactory,
       _protectedSnapshotService =
           protectedSnapshotService ??
           ProtectedSnapshotService(
             vaultService:
                 securityVaultService ?? InMemorySecurityVaultService(),
           );

  static const String _databaseName = 'hisab_rakho_local.db';
  static const String _snapshotTable = 'app_snapshot';
  static const String _snapshotId = 'primary';
  static const String _legacySnapshotKey = 'hisab_rakho.snapshot.v1';

  SharedPreferences? _preferences;
  Database? _database;
  final DatabaseFactory? _databaseFactory;
  final ProtectedSnapshotService _protectedSnapshotService;

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<Database> _db() async {
    if (_database != null) {
      return _database!;
    }

    final factory = _databaseFactory;
    if (factory == null) {
      throw UnsupportedError('SQLite is not available on this platform.');
    }

    final databasesPath = await factory.getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);
    _database = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE $_snapshotTable (
              id TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      ),
    );
    return _database!;
  }

  @override
  Future<AppDataSnapshot> load() async {
    final db = await _db();
    final rows = await db.query(
      _snapshotTable,
      where: 'id = ?',
      whereArgs: <Object>[_snapshotId],
      limit: 1,
    );

    if (rows.isNotEmpty) {
      final payload = rows.first['payload'] as String;
      final decoded = await _protectedSnapshotService.decode(payload);
      final snapshot = AppDataSnapshot.fromJson(decoded.snapshot);
      if (decoded.shouldMigrate) {
        await save(snapshot);
      }
      return snapshot;
    }

    final migrated = await _tryLoadLegacySnapshot();
    if (migrated != null) {
      await save(migrated);
      return migrated;
    }

    return AppDataSnapshot.empty();
  }

  @override
  Future<void> save(AppDataSnapshot snapshot) async {
    final db = await _db();
    final payload = await _protectedSnapshotService.encode(snapshot.toJson());
    await db.insert(_snapshotTable, <String, Object?>{
      'id': _snapshotId,
      'payload': payload,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<LocalDataProtectionStatus> protectionStatus() {
    return _protectedSnapshotService.status(
      storageLabel: 'Encrypted local database',
    );
  }

  Future<AppDataSnapshot?> _tryLoadLegacySnapshot() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_legacySnapshotKey);
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    await prefs.remove(_legacySnapshotKey);
    final decoded = await _protectedSnapshotService.decode(raw);
    return AppDataSnapshot.fromJson(decoded.snapshot);
  }
}
