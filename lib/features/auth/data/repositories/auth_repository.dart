import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kids_stories/features/auth/data/models/parent_user_model.dart';
import 'package:kids_stories/features/auth/domain/entities/parent_user.dart';

// ---------------------------------------------------------------------------
// AuthException
// ---------------------------------------------------------------------------

/// A user-friendly error thrown by [AuthRepository] operations.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  /// Human-readable message safe to show in the UI.
  final String message;

  /// Optional Firebase error code for programmatic handling.
  final String? code;

  @override
  String toString() => 'AuthException($code): $message';
}

// ---------------------------------------------------------------------------
// AuthRepository
// ---------------------------------------------------------------------------

/// All Firebase Authentication and related Firestore operations.
///
/// Throws [AuthException] with user-friendly messages on failure.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  // ---- Firestore collection ref ----
  CollectionReference<Map<String, dynamic>> get _parents =>
      _firestore.collection('parents');

  // ---------------------------------------------------------------------------
  // Auth state
  // ---------------------------------------------------------------------------

  /// Streams the currently signed-in [User], or `null` when signed out.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ---------------------------------------------------------------------------
  // Sign-up with email + password
  // ---------------------------------------------------------------------------

  /// Creates a new Firebase Auth user and writes an initial parent document.
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user!;

      // Update Firebase Auth display name.
      await user.updateDisplayName(displayName);

      // Persist parent document in Firestore.
      final now = DateTime.now();
      final model = ParentUserModel(
        id: user.uid,
        email: email,
        displayName: displayName,
        authProvider: 'email',
        consentGiven: false,
        createdAt: now,
        updatedAt: now,
      );
      await _parents.doc(user.uid).set(model.toFirestore());

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-in with email + password
  // ---------------------------------------------------------------------------

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('An unexpected error occurred. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Google Sign-In
  // ---------------------------------------------------------------------------

  /// Initiates Google sign-in flow and creates or updates the parent document.
  Future<UserCredential> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw const AuthException('Google sign-in was cancelled.');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user!;

      // Create or update parent document (merge so existing fields survive).
      final now = DateTime.now();
      final docRef = _parents.doc(user.uid);
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        final model = ParentUserModel(
          id: user.uid,
          email: user.email ?? googleUser.email,
          displayName: user.displayName ?? googleUser.displayName ?? '',
          authProvider: 'google',
          consentGiven: false,
          createdAt: now,
          updatedAt: now,
        );
        await docRef.set(model.toFirestore());
      } else {
        await docRef.update({
          'updatedAt': Timestamp.fromDate(now),
          // Keep displayName / email in sync with Google profile.
          if (user.displayName != null) 'displayName': user.displayName,
          if (user.email != null) 'email': user.email,
        });
      }

      return userCredential;
    } on AuthException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException(
        'Google sign-in failed. Please try again.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Sign-out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Sign-out failed. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      throw AuthException('Failed to send reset email. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Parental consent
  // ---------------------------------------------------------------------------

  /// Records that the parent has given consent and stores the server timestamp.
  Future<void> recordConsent(String parentId) async {
    try {
      await _parents.doc(parentId).update({
        'consentGiven': true,
        'consentTimestamp': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw AuthException('Failed to record consent. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // PIN management
  // ---------------------------------------------------------------------------

  /// Hashes [pin] with SHA-256 and stores it in the parent document.
  Future<void> setupPin(String parentId, String pin) async {
    try {
      final pinHash = _hashPin(pin);
      await _parents.doc(parentId).update({
        'pinHash': pinHash,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw AuthException('Failed to save PIN. Please try again.');
    }
  }

  /// Fetches the stored hash and compares it to the SHA-256 of [pin].
  ///
  /// Returns `false` if no PIN is set or the hashes do not match.
  Future<bool> verifyPin(String parentId, String pin) async {
    try {
      final doc = await _parents.doc(parentId).get();
      if (!doc.exists) return false;

      final stored = doc.data()?['pinHash'] as String?;
      if (stored == null) return false;

      return stored == _hashPin(pin);
    } catch (e) {
      throw AuthException('PIN verification failed. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Fetch parent document
  // ---------------------------------------------------------------------------

  /// Returns the [ParentUser] for [uid], or `null` if the document does not
  /// exist.
  Future<ParentUser?> getParentUser(String uid) async {
    try {
      final doc = await _parents
          .doc(uid)
          .withConverter<Map<String, dynamic>>(
            fromFirestore: (snap, _) => snap.data()!,
            toFirestore: (data, _) => data,
          )
          .get();

      if (!doc.exists) return null;

      // Re-fetch without converter to pass a typed DocumentSnapshot.
      final rawDoc = await _parents.doc(uid).get();
      return ParentUserModel.fromFirestore(rawDoc);
    } catch (e) {
      throw AuthException('Failed to load user profile. Please try again.');
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns the hex-encoded SHA-256 digest of [pin].
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Maps a [FirebaseAuthException] to a user-friendly [AuthException].
  AuthException _mapFirebaseAuthException(FirebaseAuthException e) {
    final message = switch (e.code) {
      'email-already-in-use' =>
        'An account with this email already exists.',
      'invalid-email' => 'Please enter a valid email address.',
      'weak-password' =>
        'Password is too weak. Please choose a stronger password.',
      'user-not-found' =>
        'No account found with this email. Please sign up.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'user-disabled' =>
        'This account has been disabled. Please contact support.',
      'too-many-requests' =>
        'Too many failed attempts. Please wait a moment and try again.',
      'network-request-failed' =>
        'Network error. Please check your connection and try again.',
      'invalid-credential' =>
        'Invalid email or password. Please check your details.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled. Please contact support.',
      'account-exists-with-different-credential' =>
        'An account already exists with the same email but a different '
            'sign-in method.',
      'requires-recent-login' =>
        'Please sign in again to complete this action.',
      _ => 'Authentication failed. Please try again.',
    };
    return AuthException(message, code: e.code);
  }
}
