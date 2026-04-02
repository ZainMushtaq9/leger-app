import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  group('Phase 13 data protection', () {
    AppDataSnapshot buildSnapshot({AppSettings? settings}) {
      final shop = ShopProfile(
        id: 'shop-1',
        name: 'Rehmat Store',
        phone: '03001234567',
        userType: UserType.shopkeeper,
        createdAt: DateTime(2026, 1, 1),
      );
      return AppDataSnapshot(
        shops: <ShopProfile>[shop],
        customers: <Customer>[
          Customer(
            id: 'customer-1',
            shopId: shop.id,
            shareCode: 'share-1',
            name: 'Usman',
            phone: '03111222333',
            createdAt: DateTime(2026, 1, 1),
          ),
        ],
        transactions: <LedgerTransaction>[
          LedgerTransaction(
            id: 'credit-1',
            customerId: 'customer-1',
            shopId: shop.id,
            amount: 2500,
            type: TransactionType.credit,
            note: 'Tea cartons',
            date: DateTime(2026, 1, 3),
          ),
        ],
        settings:
            settings ??
            AppSettings(
              shopName: shop.name,
              organizationPhone: shop.phone,
              userType: shop.userType,
              hasCompletedOnboarding: true,
              isPaidUser: false,
              lowDataMode: false,
              activeShopId: shop.id,
            ),
      );
    }

    test('migrates legacy PIN hashes to salted hashes after unlock', () async {
      final legacySettings = AppSettings(
        shopName: 'Rehmat Store',
        organizationPhone: '03001234567',
        userType: UserType.shopkeeper,
        hasCompletedOnboarding: true,
        isPaidUser: false,
        lowDataMode: false,
        activeShopId: 'shop-1',
        appLockEnabled: true,
        pinHash: _legacyHashPin(
          '1234',
          activeShopId: 'shop-1',
          shopName: 'Rehmat Store',
        ),
      );
      final repository = InMemoryLedgerRepository(
        initialSnapshot: buildSnapshot(settings: legacySettings),
      );
      final controller = HisabRakhoController(repository: repository);
      await controller.load();

      expect(controller.isLocked, isTrue);
      expect(controller.settings.pinSalt, isEmpty);

      expect(controller.unlockWithPin('1234'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.settings.pinSalt, isNotEmpty);
      expect(controller.settings.pinHash, hasLength(64));

      final stored = await repository.load();
      expect(stored.settings.pinSalt, isNotEmpty);
      expect(
        stored.settings.pinHash,
        isNot(
          _legacyHashPin(
            '1234',
            activeShopId: 'shop-1',
            shopName: 'Rehmat Store',
          ),
        ),
      );
    });

    test('saves and removes partner access profiles', () async {
      final controller = HisabRakhoController(
        repository: InMemoryLedgerRepository(initialSnapshot: buildSnapshot()),
      );
      await controller.load();

      final profile = await controller.savePartnerAccess(
        name: 'Ali Manager',
        phone: '03112223344',
        email: 'ali@example.com',
        role: PartnerAccessRole.manager,
        canViewHiddenProfiles: true,
        canExportReports: true,
      );

      expect(controller.partnerAccessProfiles, hasLength(1));
      expect(controller.partnerAccessProfiles.single.inviteCode, isNotEmpty);
      expect(controller.partnerAccessRoleLabel(profile.role), 'Manager');

      await controller.removePartnerAccess(profile.id);
      expect(controller.partnerAccessProfiles, isEmpty);
    });
  });
}

String _legacyHashPin(
  String pin, {
  required String activeShopId,
  required String shopName,
}) {
  final prime = BigInt.parse('100000001b3', radix: 16);
  final mask = BigInt.parse('ffffffffffffffff', radix: 16);
  var input = '${pin.trim()}|$activeShopId|$shopName|v1';
  var hash = BigInt.parse('cbf29ce484222325', radix: 16);
  for (var round = 0; round < 6; round++) {
    for (final code in utf8.encode(input)) {
      hash = ((hash ^ BigInt.from(code)) * prime) & mask;
    }
    input = '$hash|$round|${input.length}';
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
