import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'src/app.dart';
import 'src/controller.dart';
import 'src/data/local_database_ledger_repository.dart';
import 'src/data/shared_preferences_ledger_repository.dart';
import 'src/platform_support.dart';
import 'src/services/cloud_backup_service.dart';
import 'src/services/cloud_auth_service.dart';
import 'src/services/local_notification_service.dart';
import 'src/services/security_vault_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (supportsMobileAds) {
    await MobileAds.instance.initialize();
  }

  if (supportsLocalNotifications) {
    await LocalNotificationService.instance.initialize();
  }

  final controller = HisabRakhoController(
    repository: supportsLocalDatabase
        ? LocalDatabaseLedgerRepository(
            securityVaultService: FlutterSecureStorageSecurityVaultService(),
          )
        : SharedPreferencesLedgerRepository(
            securityVaultService: FlutterSecureStorageSecurityVaultService(),
          ),
    cloudBackupService: FirestoreCloudBackupService(),
    cloudAuthService: FirebaseCloudAuthService(),
    localNotificationService: supportsLocalNotifications
        ? LocalNotificationService.instance
        : null,
  );
  await controller.load();

  runApp(
    HisabRakhoApp(
      controller: controller,
      adsEnabled: supportsMobileAds && !kIsWeb,
    ),
  );
}
