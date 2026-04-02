import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../firebase_options.dart';
import '../models.dart';

abstract class CloudBackupService {
  Future<bool> initialize();
  bool get isAvailable;

  Future<CloudBackupManifest> uploadBackup({
    required String workspaceId,
    required String deviceLabel,
    required ShopProfile shop,
    required BackupExportBundle bundle,
    CloudAccountProfile? account,
  });

  Future<List<CloudBackupManifest>> listBackups({
    required String workspaceId,
    int limit = 10,
  });

  Future<String?> downloadBackupJson({
    required String workspaceId,
    required String backupId,
  });

  Future<List<CloudWorkspaceDirectoryEntry>> listAccountWorkspaces({
    required String accountId,
    int limit = 12,
  });
}

class FirestoreCloudBackupService implements CloudBackupService {
  FirestoreCloudBackupService({FirebaseFirestore? firestore})
    : _firestoreOverride = firestore;

  final FirebaseFirestore? _firestoreOverride;
  bool _initialized = false;
  bool _available = false;

  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  @override
  bool get isAvailable => _available;

  @override
  Future<bool> initialize() async {
    if (_initialized) {
      return _available;
    }
    _initialized = true;

    if (!DefaultFirebaseOptions.isConfigured) {
      _available = false;
      return false;
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
      _available = true;
    } catch (_) {
      _available = false;
    }

    return _available;
  }

  @override
  Future<CloudBackupManifest> uploadBackup({
    required String workspaceId,
    required String deviceLabel,
    required ShopProfile shop,
    required BackupExportBundle bundle,
    CloudAccountProfile? account,
  }) async {
    await _ensureReady();

    final normalizedWorkspaceId = _normalizeWorkspaceId(workspaceId);
    final now = DateTime.now();
    final backupId = 'cloud-${now.millisecondsSinceEpoch}';
    final manifest = CloudBackupManifest(
      id: backupId,
      workspaceId: normalizedWorkspaceId,
      deviceLabel: deviceLabel.trim(),
      shopId: shop.id,
      shopName: shop.name,
      createdAt: now,
      source: bundle.preview.source,
      customerCount: bundle.preview.customerCount,
      transactionCount: bundle.preview.transactionCount,
      reminderCount: bundle.preview.reminderCount,
      checksum: bundle.preview.actualChecksum,
      sizeBytes: bundle.preview.sizeBytes,
      integrityStatus: bundle.preview.integrityStatus.name,
      accountId: account?.id.trim() ?? '',
      accountEmail: account?.email.trim() ?? '',
      accountDisplayName: account?.displayName.trim() ?? '',
    );

    final workspaceRef = _workspaceCollection.doc(normalizedWorkspaceId);
    await workspaceRef.set(<String, dynamic>{
      'workspaceId': normalizedWorkspaceId,
      'shopId': shop.id,
      'shopName': shop.name,
      'updatedAt': now.toIso8601String(),
      'updatedAtMillis': now.millisecondsSinceEpoch,
      'lastDeviceLabel': deviceLabel.trim(),
      'latestBackupId': backupId,
      'backupCount': FieldValue.increment(1),
      'accountId': account?.id.trim() ?? '',
      'accountEmail': account?.email.trim() ?? '',
      'accountDisplayName': account?.displayName.trim() ?? '',
    }, SetOptions(merge: true));

    await workspaceRef
        .collection('backups')
        .doc(backupId)
        .set(<String, dynamic>{
          ...manifest.toJson(),
          'rawJson': bundle.rawJson,
          'createdAtMillis': now.millisecondsSinceEpoch,
        });

    return manifest;
  }

  @override
  Future<List<CloudBackupManifest>> listBackups({
    required String workspaceId,
    int limit = 10,
  }) async {
    await _ensureReady();

    final normalizedWorkspaceId = _normalizeWorkspaceId(workspaceId);
    final query = await _workspaceCollection
        .doc(normalizedWorkspaceId)
        .collection('backups')
        .orderBy('createdAtMillis', descending: true)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => CloudBackupManifest.fromJson(doc.data()))
        .toList();
  }

  @override
  Future<String?> downloadBackupJson({
    required String workspaceId,
    required String backupId,
  }) async {
    await _ensureReady();

    final normalizedWorkspaceId = _normalizeWorkspaceId(workspaceId);
    final doc = await _workspaceCollection
        .doc(normalizedWorkspaceId)
        .collection('backups')
        .doc(backupId)
        .get();
    final data = doc.data();
    if (data == null) {
      return null;
    }
    return data['rawJson'] as String?;
  }

  @override
  Future<List<CloudWorkspaceDirectoryEntry>> listAccountWorkspaces({
    required String accountId,
    int limit = 12,
  }) async {
    await _ensureReady();

    final normalizedAccountId = accountId.trim();
    if (normalizedAccountId.isEmpty) {
      return const <CloudWorkspaceDirectoryEntry>[];
    }

    final query = await _workspaceCollection
        .where('accountId', isEqualTo: normalizedAccountId)
        .get();
    final entries = query.docs.map((doc) {
      final data = doc.data();
      return CloudWorkspaceDirectoryEntry(
        workspaceId: data['workspaceId'] as String? ?? doc.id,
        shopId: data['shopId'] as String? ?? '',
        shopName: data['shopName'] as String? ?? '',
        accountId: data['accountId'] as String? ?? '',
        accountEmail: data['accountEmail'] as String? ?? '',
        accountDisplayName: data['accountDisplayName'] as String? ?? '',
        lastDeviceLabel: data['lastDeviceLabel'] as String? ?? '',
        updatedAt: data['updatedAt'] == null
            ? DateTime.now()
            : DateTime.parse(data['updatedAt'] as String),
        latestBackupId: data['latestBackupId'] as String? ?? '',
        backupCount: (data['backupCount'] as num?)?.toInt() ?? 0,
      );
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (entries.length <= limit) {
      return entries;
    }
    return entries.take(limit).toList();
  }

  CollectionReference<Map<String, dynamic>> get _workspaceCollection =>
      _firestore.collection('hisabRakhoCloudBackups');

  Future<void> _ensureReady() async {
    final ready = await initialize();
    if (!ready) {
      throw StateError('Cloud backup is not available on this device.');
    }
  }

  String _normalizeWorkspaceId(String value) {
    final cleaned = value.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    if (cleaned.isEmpty) {
      throw ArgumentError('A cloud workspace code is required.');
    }
    return cleaned;
  }
}
