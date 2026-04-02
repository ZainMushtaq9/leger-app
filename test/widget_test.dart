import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/app.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';

void main() {
  testWidgets('loads Hisab Rakho dashboard', (WidgetTester tester) async {
    final now = DateTime(2026, 3, 29, 10);
    final shop = ShopProfile(
      id: 'shop-test',
      name: 'Test General Store',
      phone: '03001234567',
      userType: UserType.shopkeeper,
      createdAt: now,
    );
    final snapshot = AppDataSnapshot(
      shops: <ShopProfile>[shop],
      customers: const <Customer>[],
      transactions: const <LedgerTransaction>[],
      settings: AppSettings(
        shopName: shop.name,
        organizationPhone: shop.phone,
        userType: shop.userType,
        hasCompletedOnboarding: true,
        isPaidUser: false,
        lowDataMode: false,
        activeShopId: shop.id,
      ),
    );
    final controller = HisabRakhoController(
      repository: InMemoryLedgerRepository(initialSnapshot: snapshot),
    );
    await controller.load();

    await tester.pumpWidget(
      HisabRakhoApp(
        controller: controller,
        splashDelay: Duration.zero,
        adsEnabled: false,
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Test General Store'), findsOneWidget);
    expect(find.text('Quick Backup'), findsOneWidget);
    expect(find.text('Customers'), findsWidgets);
    expect(find.text('Business Hub'), findsWidgets);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });
}
