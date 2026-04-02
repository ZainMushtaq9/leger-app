import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/services/cloud_backup_service.dart';
import 'package:hisab_rakho/src/ui/settings_screen.dart';

class FakeCloudBackupService implements CloudBackupService {
  final Map<String, Map<String, String>> _payloads =
      <String, Map<String, String>>{};
  final Map<String, List<CloudBackupManifest>> _manifests =
      <String, List<CloudBackupManifest>>{};
  final Map<String, List<CloudWorkspaceDirectoryEntry>> _workspacesByAccount =
      <String, List<CloudWorkspaceDirectoryEntry>>{};
  final bool _available = true;

  @override
  bool get isAvailable => _available;

  @override
  Future<bool> initialize() async => _available;

  @override
  Future<String?> downloadBackupJson({
    required String workspaceId,
    required String backupId,
  }) async {
    return _payloads[workspaceId]?[backupId];
  }

  @override
  Future<List<CloudBackupManifest>> listBackups({
    required String workspaceId,
    int limit = 10,
  }) async {
    final backups = List<CloudBackupManifest>.from(
      _manifests[workspaceId] ?? const <CloudBackupManifest>[],
    );
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups.take(limit).toList();
  }

  @override
  Future<List<CloudWorkspaceDirectoryEntry>> listAccountWorkspaces({
    required String accountId,
    int limit = 12,
  }) async {
    final workspaces = List<CloudWorkspaceDirectoryEntry>.from(
      _workspacesByAccount[accountId] ?? const <CloudWorkspaceDirectoryEntry>[],
    );
    workspaces.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return workspaces.take(limit).toList();
  }

  @override
  Future<CloudBackupManifest> uploadBackup({
    required String workspaceId,
    required String deviceLabel,
    required ShopProfile shop,
    required BackupExportBundle bundle,
    CloudAccountProfile? account,
  }) async {
    final now = DateTime.now();
    final manifest = CloudBackupManifest(
      id: 'cloud-${now.millisecondsSinceEpoch}',
      workspaceId: workspaceId,
      deviceLabel: deviceLabel,
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
      accountId: account?.id ?? '',
      accountEmail: account?.email ?? '',
      accountDisplayName: account?.displayName ?? '',
    );
    _payloads.putIfAbsent(workspaceId, () => <String, String>{})[manifest.id] =
        bundle.rawJson;
    _manifests.putIfAbsent(workspaceId, () => <CloudBackupManifest>[]);
    _manifests[workspaceId]!.insert(0, manifest);
    if (account != null && account.id.trim().isNotEmpty) {
      _workspacesByAccount.putIfAbsent(
        account.id,
        () => <CloudWorkspaceDirectoryEntry>[],
      );
      _workspacesByAccount[account.id] = <CloudWorkspaceDirectoryEntry>[
        CloudWorkspaceDirectoryEntry(
          workspaceId: workspaceId,
          shopId: shop.id,
          shopName: shop.name,
          accountId: account.id,
          accountEmail: account.email,
          accountDisplayName: account.displayName,
          lastDeviceLabel: deviceLabel,
          updatedAt: now,
          latestBackupId: manifest.id,
          backupCount: _manifests[workspaceId]!.length,
        ),
        ..._workspacesByAccount[account.id]!.where(
          (entry) => entry.workspaceId != workspaceId,
        ),
      ];
    }
    return manifest;
  }
}

void main() {
  group('Phase 6 backup flow', () {
    late ShopProfile shop;
    late Customer customer;

    AppDataSnapshot buildSnapshot({
      int autoBackupDays = 0,
      DateTime? lastBackupAt,
    }) {
      shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Store',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 1, 1),
      );
      customer = Customer(
        id: 'customer-1',
        shopId: shop.id,
        shareCode: 'share-1',
        name: 'Usman',
        phone: '03111222333',
        createdAt: DateTime(2026, 1, 1),
        category: 'Wholesale',
      );

      return AppDataSnapshot(
        shops: <ShopProfile>[shop],
        customers: <Customer>[customer],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: customer.id,
            shopId: shop.id,
            amount: 2500,
            type: TransactionType.credit,
            note: 'Tea cartons',
            date: DateTime(2026, 1, 2),
          ),
        ],
        settings: AppSettings(
          shopName: shop.name,
          organizationPhone: shop.phone,
          userType: UserType.shopkeeper,
          hasCompletedOnboarding: true,
          isPaidUser: true,
          lowDataMode: false,
          activeShopId: shop.id,
          autoBackupDays: autoBackupDays,
          lastBackupAt: lastBackupAt,
        ),
        reminderLogs: <ReminderLog>[
          ReminderLog(
            id: 'reminder-1',
            customerId: customer.id,
            message: 'Reminder sent',
            tone: ReminderTone.normal,
            sentAt: DateTime(2026, 1, 3),
            channel: 'whatsapp',
            wasSuccessful: true,
          ),
        ],
        installmentPlans: <InstallmentPlan>[
          InstallmentPlan(
            id: 'plan-1',
            customerId: customer.id,
            totalAmount: 2500,
            installmentAmount: 500,
            installmentCount: 5,
            completedInstallments: 1,
            intervalDays: 7,
            createdAt: DateTime(2026, 1, 4),
            firstDueDate: DateTime(2026, 1, 10),
            nextDueDate: DateTime(2026, 1, 10),
          ),
        ],
        customerVisits: <CustomerVisit>[
          CustomerVisit(
            id: 'visit-1',
            customerId: customer.id,
            visitedAt: DateTime(2026, 1, 5, 10),
            note: 'Shop visit logged',
          ),
        ],
      );
    }

    test('builds integrity-aware backup export and preview', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();

      final bundle = controller.buildBackupExport(source: 'file');
      final preview = controller.previewBackupJson(bundle.rawJson);

      expect(bundle.rawJson, contains('"algorithm": "sha256"'));
      expect(preview.integrityStatus, BackupIntegrityStatus.verified);
      expect(preview.expectedChecksum, isNotEmpty);
      expect(preview.expectedChecksum, preview.actualChecksum);
      expect(preview.shopCount, 1);
      expect(preview.customerCount, 1);
      expect(preview.installmentPlanCount, 1);
      expect(preview.visitCount, 1);
    });

    test(
      'rejects tampered backups and still previews legacy payloads',
      () async {
        final snapshot = buildSnapshot();
        final controller = HisabRakhoController(
          repository: InMemoryLedgerRepository(initialSnapshot: snapshot),
        );
        await controller.load();

        final bundle = controller.buildBackupExport(source: 'file');
        final tampered = Map<String, dynamic>.from(
          jsonDecode(bundle.rawJson) as Map,
        );
        final tamperedSnapshot = Map<String, dynamic>.from(
          tampered['snapshot'] as Map,
        );
        final transactions = List<dynamic>.from(
          tamperedSnapshot['transactions'] as List<dynamic>,
        );
        final firstTransaction = Map<String, dynamic>.from(
          transactions.first as Map,
        );
        firstTransaction['amount'] = 9999;
        transactions[0] = firstTransaction;
        tamperedSnapshot['transactions'] = transactions;
        tampered['snapshot'] = tamperedSnapshot;

        final tamperedRaw = jsonEncode(tampered);
        final tamperedPreview = controller.previewBackupJson(tamperedRaw);
        expect(tamperedPreview.integrityStatus, BackupIntegrityStatus.invalid);
        await expectLater(
          () => controller.restoreFromBackupJson(tamperedRaw),
          throwsFormatException,
        );

        final legacyRaw = jsonEncode(snapshot.toJson());
        final legacyPreview = controller.previewBackupJson(legacyRaw);
        expect(legacyPreview.integrityStatus, BackupIntegrityStatus.legacy);
        expect(legacyPreview.isRestorable, isTrue);
      },
    );

    test('runs due auto backup and allows history deletion', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(
          initialSnapshot: buildSnapshot(
            autoBackupDays: 1,
            lastBackupAt: DateTime(2026, 1, 1),
          ),
        ),
      );
      await controller.load();

      expect(controller.backups, hasLength(1));
      expect(controller.backups.single.source, 'auto');
      expect(controller.backups.single.status, 'scheduled');
      expect(controller.backups.single.hasPayload, isTrue);
      expect(controller.settings.lastBackupAt, isNotNull);

      await controller.deleteBackupRecord(controller.backups.single.id);

      expect(controller.backups, isEmpty);
      expect(controller.settings.lastBackupAt, isNull);
    });

    test('restores from a saved restore point in backup history', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();

      final record = await controller.createLocalBackup(
        source: 'checkpoint',
        note: 'Checkpoint before risky change',
      );

      await controller.addUdhaar(
        customerId: customer.id,
        amount: 600,
        note: 'Later credit',
      );

      expect(controller.transactionsFor(customer.id), hasLength(2));

      await controller.restoreFromBackupRecord(record.id);

      expect(controller.transactionsFor(customer.id), hasLength(1));
      expect(
        controller.transactionsFor(customer.id).single.note,
        'Tea cartons',
      );
      expect(
        controller.backups.where(
          (backup) => backup.source == 'history-restore',
        ),
        isNotEmpty,
      );
    });

    test('syncs backups to cloud and restores them later', () async {
      final cloudService = FakeCloudBackupService();
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
        cloudBackupService: cloudService,
      );
      await controller.load();

      await controller.updateSettings(
        controller.settings.copyWith(
          cloudSyncEnabled: true,
          cloudWorkspaceId: 'SYNC-1234',
          cloudDeviceLabel: 'Main counter',
        ),
      );

      await controller.syncBackupToCloud();
      expect(controller.cloudBackups, hasLength(1));
      expect(controller.backups.first.source, 'cloud-sync');
      expect(controller.lastCloudSyncAt, isNotNull);

      await controller.addUdhaar(
        customerId: customer.id,
        amount: 850,
        note: 'Temporary change',
      );
      expect(controller.transactionsFor(customer.id), hasLength(2));

      await controller.restoreCloudBackup(controller.cloudBackups.first.id);

      expect(controller.transactionsFor(customer.id), hasLength(1));
      expect(controller.lastCloudRestoreAt, isNotNull);
      expect(
        controller.backups.where((backup) => backup.source == 'cloud-restore'),
        isNotEmpty,
      );
    });

    testWidgets('renders cloud backup controls in settings', (tester) async {
      final cloudService = FakeCloudBackupService();
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
        cloudBackupService: cloudService,
      );
      await controller.load();
      await controller.updateSettings(
        controller.settings.copyWith(
          cloudSyncEnabled: true,
          cloudWorkspaceId: 'SYNC-1234',
          cloudDeviceLabel: 'Counter tablet',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(controller: controller, adsEnabled: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Cloud backup'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cloud backup'), findsOneWidget);
      expect(find.text('Sync Now'), findsOneWidget);
      expect(find.text('Restore Latest'), findsOneWidget);
    });
  });
}
