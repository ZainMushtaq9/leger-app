import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static const String apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const String authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );

  static bool get isConfigured {
    return apiKey.trim().isNotEmpty &&
        appId.trim().isNotEmpty &&
        messagingSenderId.trim().isNotEmpty &&
        projectId.trim().isNotEmpty &&
        storageBucket.trim().isNotEmpty;
  }

  static FirebaseOptions get currentPlatform {
    if (!isConfigured) {
      throw UnsupportedError(
        'Firebase is not configured. Provide FIREBASE_* values via --dart-define.',
      );
    }

    if (kIsWeb) {
      return web;
    }
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      TargetPlatform.macOS => ios,
      TargetPlatform.windows => android,
      _ => throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for this platform.',
      ),
    };
  }

  static FirebaseOptions get web => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    authDomain: authDomain.trim().isEmpty ? null : authDomain,
    storageBucket: storageBucket,
    measurementId: measurementId.trim().isEmpty ? null : measurementId,
  );

  static FirebaseOptions get android => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );

  static FirebaseOptions get ios => FirebaseOptions(
    apiKey: apiKey,
    appId: appId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket,
  );
}
