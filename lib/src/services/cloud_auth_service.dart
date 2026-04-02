import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../models.dart';

abstract class CloudAuthService {
  Future<bool> initialize();
  bool get isAvailable;

  Future<CloudAccountProfile?> currentAccount();
  Future<CloudAccountProfile> signInWithGoogle();
  Future<CloudAccountProfile> signInWithEmailOrPhone({
    required String identifier,
    required String password,
  });
  Future<CloudAccountProfile> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
    String phoneNumber = '',
  });
  Future<void> sendPasswordReset({required String identifier});
  Future<void> sendEmailVerification();
  Future<CloudAccountProfile?> reloadCurrentAccount();
  Future<void> signOut();
}

class FirebaseCloudAuthService implements CloudAuthService {
  FirebaseCloudAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _authOverride = auth,
      _firestoreOverride = firestore;

  final FirebaseAuth? _authOverride;
  final FirebaseFirestore? _firestoreOverride;
  bool _initialized = false;
  bool _available = false;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore =>
      _firestoreOverride ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _firestore.collection('hisabRakhoAccounts');

  CollectionReference<Map<String, dynamic>> get _phoneLogins =>
      _firestore.collection('hisabRakhoPhoneLogins');

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
    return _buildAccountProfile(user);
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
    await _upsertAccountProfile(user);
    return _buildAccountProfile(user);
  }

  @override
  Future<CloudAccountProfile> signInWithEmailOrPhone({
    required String identifier,
    required String password,
  }) async {
    await _ensureReady();

    final trimmedIdentifier = identifier.trim();
    if (trimmedIdentifier.isEmpty) {
      throw StateError('Enter your email or phone number.');
    }
    if (password.trim().isEmpty) {
      throw StateError('Enter your password.');
    }

    final email = await _resolveEmailFromIdentifier(trimmedIdentifier);
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('Sign-in did not return an account.');
      }
      return _buildAccountProfile(user);
    } on FirebaseAuthException catch (error) {
      throw StateError(_friendlyAuthMessage(error));
    }
  }

  @override
  Future<CloudAccountProfile> registerWithEmail({
    required String displayName,
    required String email,
    required String password,
    String phoneNumber = '',
  }) async {
    await _ensureReady();

    final trimmedName = displayName.trim();
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedPhone = _normalizePakPhone(phoneNumber);
    if (trimmedName.isEmpty) {
      throw StateError('Enter your full name.');
    }
    if (normalizedEmail.isEmpty) {
      throw StateError('Enter your email address.');
    }
    if (password.trim().length < 6) {
      throw StateError('Password must be at least 6 characters.');
    }

    if (normalizedPhone.isNotEmpty) {
      final existingPhoneAccount = await _phoneLogins
          .doc(_phoneHash(normalizedPhone))
          .get();
      if (existingPhoneAccount.exists) {
        throw StateError(
          'This phone number is already linked to another account.',
        );
      }
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      User? user = credential.user;
      if (user == null) {
        throw StateError('Account creation did not return a user.');
      }
      if (trimmedName.isNotEmpty) {
        await user.updateDisplayName(trimmedName);
      }
      if (!user.emailVerified && user.email != null) {
        await user.sendEmailVerification();
      }
      await user.reload();
      user = _auth.currentUser ?? user;
      await _upsertAccountProfile(user, phoneNumber: normalizedPhone);
      return _buildAccountProfile(user, phoneNumberOverride: normalizedPhone);
    } on FirebaseAuthException catch (error) {
      throw StateError(_friendlyAuthMessage(error));
    }
  }

  @override
  Future<void> sendPasswordReset({required String identifier}) async {
    await _ensureReady();

    final trimmedIdentifier = identifier.trim();
    if (trimmedIdentifier.isEmpty) {
      throw StateError('Enter your email or phone number.');
    }

    final email = await _resolveEmailFromIdentifier(trimmedIdentifier);
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (error) {
      throw StateError(_friendlyAuthMessage(error));
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    await _ensureReady();
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in account found.');
    }
    if (user.emailVerified) {
      return;
    }
    await user.sendEmailVerification();
  }

  @override
  Future<CloudAccountProfile?> reloadCurrentAccount() async {
    await _ensureReady();
    final current = _auth.currentUser;
    if (current == null) {
      return null;
    }
    await current.reload();
    final refreshed = _auth.currentUser;
    if (refreshed == null) {
      return null;
    }
    return _buildAccountProfile(refreshed);
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

  Future<String> _resolveEmailFromIdentifier(String identifier) async {
    if (identifier.contains('@')) {
      return identifier.trim().toLowerCase();
    }
    final normalizedPhone = _normalizePakPhone(identifier);
    if (normalizedPhone.isEmpty) {
      throw StateError('Enter a valid email or phone number.');
    }
    final lookup = await _phoneLogins.doc(_phoneHash(normalizedPhone)).get();
    final data = lookup.data();
    final email = data == null ? '' : (data['email'] as String? ?? '').trim();
    if (email.isEmpty) {
      throw StateError('No account was found for this phone number.');
    }
    return email.toLowerCase();
  }

  Future<void> _upsertAccountProfile(User user, {String? phoneNumber}) async {
    final normalizedPhone = phoneNumber ?? _normalizePakPhone(user.phoneNumber);
    await _profiles.doc(user.uid).set(<String, dynamic>{
      'uid': user.uid,
      'email': user.email?.trim().toLowerCase() ?? '',
      'phoneNumber': normalizedPhone,
      'displayName': user.displayName?.trim() ?? '',
      'emailVerified': user.emailVerified,
      'updatedAt': DateTime.now().toIso8601String(),
    }, SetOptions(merge: true));

    if (normalizedPhone.isNotEmpty) {
      await _phoneLogins.doc(_phoneHash(normalizedPhone)).set(<String, dynamic>{
        'uid': user.uid,
        'email': user.email?.trim().toLowerCase() ?? '',
        'phoneNumber': normalizedPhone,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
    }
  }

  Future<CloudAccountProfile> _buildAccountProfile(
    User user, {
    String phoneNumberOverride = '',
  }) async {
    String phoneNumber = phoneNumberOverride.trim();
    String displayName = user.displayName?.trim() ?? '';
    try {
      final profile = await _profiles.doc(user.uid).get();
      final data = profile.data();
      if (data != null) {
        if (phoneNumber.isEmpty) {
          phoneNumber = (data['phoneNumber'] as String? ?? '').trim();
        }
        if (displayName.isEmpty) {
          displayName = (data['displayName'] as String? ?? '').trim();
        }
      }
    } catch (_) {
      // Keep auth available even if profile lookup fails.
    }

    if (phoneNumber.isEmpty) {
      phoneNumber = _normalizePakPhone(user.phoneNumber);
    }

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
      phoneNumber: phoneNumber,
      displayName: displayName,
      provider: provider,
      isEmailVerified: user.emailVerified,
      signedInAt: DateTime.now(),
    );
  }

  String _friendlyAuthMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Enter a valid email address.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email, phone number, or password.';
      case 'email-already-in-use':
        return 'This email is already linked to another account.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Authentication failed. Please try again.';
    }
  }

  String _normalizePakPhone(String? input) {
    final raw = (input ?? '').trim();
    if (raw.isEmpty) {
      return '';
    }
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('92') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.startsWith('0') && digits.length == 11) {
      return '+92${digits.substring(1)}';
    }
    if (digits.length == 10) {
      return '+92$digits';
    }
    return digits.isEmpty ? '' : '+$digits';
  }

  String _phoneHash(String normalizedPhone) {
    final digest = sha256.convert(normalizedPhone.toLowerCase().codeUnits);
    return digest.bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
