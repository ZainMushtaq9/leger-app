import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models.dart';

abstract class CloudAuthService {
  Future<bool> initialize();
  bool get isAvailable;

  Future<CloudAccountProfile?> currentAccount();
  Future<CloudAccountProfile> signInWithGoogle();
  Future<void> signOut();
}

class FirebaseCloudAuthService implements CloudAuthService {
  FirebaseCloudAuthService({FirebaseAuth? auth}) : _authOverride = auth;

  final FirebaseAuth? _authOverride;
  bool _initialized = false;
  bool _available = false;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

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
  Future<CloudAccountProfile?> currentAccount() async {
    final ready = await initialize();
    if (!ready) {
      return null;
    }
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }
    return _mapUser(user);
  }

  @override
  Future<CloudAccountProfile> signInWithGoogle() async {
    await _ensureReady();

    final provider = GoogleAuthProvider()
      ..addScope('email')
      ..addScope('profile');

    final UserCredential credential = kIsWeb
        ? await _auth.signInWithPopup(provider)
        : await _auth.signInWithProvider(provider);
    final user = credential.user;
    if (user == null) {
      throw StateError('Google sign-in did not return a user.');
    }
    return _mapUser(user);
  }

  @override
  Future<void> signOut() async {
    if (!await initialize()) {
      return;
    }
    await _auth.signOut();
  }

  Future<void> _ensureReady() async {
    final ready = await initialize();
    if (!ready) {
      throw StateError('Cloud sign-in is not available on this device.');
    }
  }

  CloudAccountProfile _mapUser(User user) {
    String provider = '';
    for (final item in user.providerData) {
      if (item.providerId.trim().isNotEmpty) {
        provider = item.providerId.trim();
        break;
      }
    }
    return CloudAccountProfile(
      id: user.uid,
      email: user.email?.trim() ?? '',
      displayName: user.displayName?.trim() ?? '',
      provider: provider,
      signedInAt: DateTime.now(),
    );
  }
}
