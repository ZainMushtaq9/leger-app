import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/services/cloud_auth_service.dart';
import 'package:hisab_rakho/src/services/cloud_backup_service.dart';
import 'package:hisab_rakho/src/ui/settings_screen.dart';

class FakeCloudAuthService implements CloudAuthService {
  FakeCloudAuthService({
    CloudAccountProfile? initialAccount,
    CloudAccountProfile? signInAccount,
  }) : _current = initialAccount,
       _signInAccount =
           signInAccount ??
           CloudAccountProfile(
             id: 'google-user-1',
             email: 'owner@example.com',
             displayName: 'Rehmat Owner',
             provider: 'google.com',
             signedInAt: DateTime(2026, 3, 31, 9),
           );

  final CloudAccountProfile _signInAccount;
  CloudAccountProfile? _current;

  @override
  bool get isAvailable => true;

  @override
  Future<CloudAccountProfile?> currentAccount() async => _current;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<CloudAccountProfile> signInWithGoogle() async {
    _current = _signInAccount;
    return _current!;
  }

  @override
  Future<void> signOut() async {
    _current = null;
  }
}

class FakeCloudBackupService implements CloudBackupService {
  final Map<String, Map<String, String>> _payloads =
      <String, Map<String, String>>{};
  final Map<String, List<CloudBackupManifest>> _manifests =
      <String, List<CloudBackupManifest>>{};
  final Map<String, List<CloudWorkspaceDirectoryEntry>> _workspacesByAccount =
      <String, List<CloudWorkspaceDirectoryEntry>>{};

  @override
  bool get isAvailable => true;

  @override
  Future<String?> downloadBackupJson({
    required String workspaceId,
    required String backupId,
  }) async {
    return _payloads[workspaceId]?[backupId];
  }

  @override
  Future<bool> initialize() async => true;

  @override
  Future<List<CloudWorkspaceDirectoryEntry>> listAccountWorkspaces({
    required String accountId,
    int limit = 12,
  }) async {
    final entries = List<CloudWorkspaceDirectoryEntry>.from(
      _workspacesByAccount[accountId] ?? const <CloudWorkspaceDirectoryEntry>[],
    )..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries.take(limit).toList();
  }

  @override
  Future<List<CloudBackupManifest>> listBackups({
    required String workspaceId,
    int limit = 10,
  }) async {
    final manifests = List<CloudBackupManifest>.from(
      _manifests[workspaceId] ?? const <CloudBackupManifest>[],
    )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return manifests.take(limit).toList();
  }

  @override
  Future<CloudBackupManifest> uploadBackup({
    required String workspaceId,
    required String deviceLabel,
    required ShopProfile shop,
    required BackupExportBundle bundle,
    CloudAccountProfile? account,
  }) async {
    final now = DateTime(2026, 3, 31, 10, _manifests.length + 1);
    final manifest = CloudBackupManifest(
      id: 'cloud-${workspaceId.toLowerCase()}-${now.millisecondsSinceEpoch}',
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

AppDataSnapshot buildSnapshot() {
  final shop = ShopProfile(
    id: 'shop-1',
    name: 'Rehmat Store',
    phone: '03001234567',
    userType: UserType.shopkeeper,
    createdAt: DateTime(2026, 1, 1),
  );
  final customer = Customer(
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
    ),
  );
}

void main() {
  group('Phase 12 cloud account flow', () {
    test('signs in and persists the cloud account in settings', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
        cloudBackupService: FakeCloudBackupService(),
        cloudAuthService: FakeCloudAuthService(),
      );
      await controller.load();

      expect(controller.cloudAccount, isNull);

      final account = await controller.signInToCloudAccountWithGoogle();

      expect(account.email, 'owner@example.com');
      expect(controller.cloudAccount?.email, 'owner@example.com');
      expect(controller.settings.cloudAccountEmail, 'owner@example.com');
      expect(controller.settings.cloudAccountProvider, 'google.com');
    });

    test(
      'links a workspace to the signed-in account and restores it later',
      () async {
        final backupService = FakeCloudBackupService();
        final ownerAccount = CloudAccountProfile(
          id: 'google-user-1',
          email: 'owner@example.com',
          displayName: 'Rehmat Owner',
          provider: 'google.com',
          signedInAt: DateTime(2026, 3, 31, 9),
        );

        final sourceController = HisabRakhoController(
          repository: InMemoryLedgerRepository(
            initialSnapshot: buildSnapshot(),
          ),
          cloudBackupService: backupService,
          cloudAuthService: FakeCloudAuthService(signInAccount: ownerAccount),
        );
        await sourceController.load();
        await sourceController.signInToCloudAccountWithGoogle();
        await sourceController.updateSettings(
          sourceController.settings.copyWith(
            cloudSyncEnabled: true,
            cloudWorkspaceId: 'SYNC-2026',
            cloudDeviceLabel: 'Main counter',
          ),
        );
        await sourceController.syncBackupToCloud();

        expect(sourceController.accountCloudWorkspaces, hasLength(1));
        expect(
          sourceController.accountCloudWorkspaces.single.workspaceId,
          'SYNC2026',
        );

        final targetController = HisabRakhoController(
          repository: InMemoryLedgerRepository(
            initialSnapshot: buildSnapshot(),
          ),
          cloudBackupService: backupService,
          cloudAuthService: FakeCloudAuthService(initialAccount: ownerAccount),
        );
        await targetController.load();

        expect(targetController.cloudAccount?.email, 'owner@example.com');
        expect(targetController.accountCloudWorkspaces, hasLength(1));

        await targetController.connectCloudWorkspace(
          targetController.accountCloudWorkspaces.single.workspaceId,
        );
        await targetController.addUdhaar(
          customerId: 'customer-1',
          amount: 800,
          note: 'Temporary change',
        );
        expect(targetController.transactionsFor('customer-1'), hasLength(2));

        await targetController.restoreLatestCloudBackup();

        expect(targetController.transactionsFor('customer-1'), hasLength(1));
        expect(
          targetController.transactionsFor('customer-1').single.note,
          'Tea cartons',
        );
      },
    );

    testWidgets('shows cloud account controls in settings', (tester) async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
        cloudBackupService: FakeCloudBackupService(),
        cloudAuthService: FakeCloudAuthService(),
      );
      await controller.load();

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(controller: controller, adsEnabled: false),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Cloud account'),
        400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Cloud account'), findsOneWidget);
      expect(find.text('Sign In With Google'), findsOneWidget);
    });
  });
}
