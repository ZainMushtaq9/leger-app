import 'package:flutter_test/flutter_test.dart';
import 'package:hisab_rakho/src/app.dart';
import 'package:hisab_rakho/src/controller.dart';
import 'package:hisab_rakho/src/data/in_memory_ledger_repository.dart';
import 'package:hisab_rakho/src/models.dart';
import 'package:hisab_rakho/src/services/cloud_auth_service.dart';

class StartupFakeCloudAuthService implements CloudAuthService {
  StartupFakeCloudAuthService({this.account});

  CloudAccountProfile? account;

  @override
  bool get isAvailable => true;

  @override
  Future<CloudAccountProfile?> currentAccount() async => account;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<CloudAccountProfile?> reloadCurrentAccount() async => account;

  @override
  Future<CloudAccountProfile> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
    String phoneNumber = '',
  }) async {
    account = CloudAccountProfile(
      id: 'registered-user',
      email: email,
      phoneNumber: phoneNumber,
      displayName: displayName,
      provider: 'password',
      isEmailVerified: false,
      signedInAt: DateTime(2026, 4, 2, 10),
    );
    return account!;
  }

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> sendPasswordReset({required String identifier}) async {}

  @override
  Future<CloudAccountProfile> signInWithEmailOrPhone({
    required String identifier,
    required String password,
  }) async {
    account = CloudAccountProfile(
      id: 'signin-user',
      email: identifier,
      displayName: 'Signed In User',
      provider: 'password',
      isEmailVerified: true,
      signedInAt: DateTime(2026, 4, 2, 11),
    );
    return account!;
  }

  @override
  Future<CloudAccountProfile> signInWithGoogle() async {
    account = CloudAccountProfile(
      id: 'google-user',
      email: 'google@example.com',
      displayName: 'Google User',
      provider: 'google.com',
      isEmailVerified: true,
      signedInAt: DateTime(2026, 4, 2, 11),
    );
    return account!;
  }

  @override
  Future<void> signOut() async {
    account = null;
  }
}

AppDataSnapshot _snapshot() {
  final shop = ShopProfile(
    id: 'shop-default',
    name: 'Zain Autos',
    phone: '03001234567',
    userType: UserType.shopkeeper,
    createdAt: DateTime(2026, 1, 1),
  );
  return AppDataSnapshot(
    shops: <ShopProfile>[shop],
    customers: const <Customer>[],
    transactions: const <LedgerTransaction>[],
    settings: AppSettings(
      shopName: shop.name,
      organizationPhone: shop.phone,
      userType: UserType.shopkeeper,
      hasCompletedOnboarding: true,
      isPaidUser: false,
      lowDataMode: false,
      activeShopId: shop.id,
    ),
  );
}

void main() {
  testWidgets('shows startup auth gate when no cloud account is signed in', (
    tester,
  ) async {
    final controller = HisabRakhoController(
      repository: InMemoryLedgerRepository(initialSnapshot: _snapshot()),
      cloudAuthService: StartupFakeCloudAuthService(),
    );
    await controller.load();

    await tester.pumpWidget(
      HisabRakhoApp(
        controller: controller,
        splashDelay: Duration.zero,
        adsEnabled: false,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Login'), findsWidgets);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('shows email verification screen for unverified password users', (
    tester,
  ) async {
    final controller = HisabRakhoController(
      repository: InMemoryLedgerRepository(initialSnapshot: _snapshot()),
      cloudAuthService: StartupFakeCloudAuthService(
        account: CloudAccountProfile(
          id: 'password-user',
          email: 'owner@example.com',
          displayName: 'Owner',
          provider: 'password',
          isEmailVerified: false,
          signedInAt: DateTime(2026, 4, 2, 10),
        ),
      ),
    );
    await controller.load();

    await tester.pumpWidget(
      HisabRakhoApp(
        controller: controller,
        splashDelay: Duration.zero,
        adsEnabled: false,
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Verify your email'), findsOneWidget);
    expect(find.textContaining('owner@example.com'), findsOneWidget);
  });
}
