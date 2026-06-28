import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  User? get currentUser {
    return _auth.currentUser;
  }

  Future<void> ensureAnonymousLogin() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  Future<UserCredential> signInAnonymously() async {
    return _auth.signInAnonymously();
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createAccountWithEmail({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();

    if (kIsWeb) {
      return _auth.signInWithPopup(provider);
    }

    final googleUser = await GoogleSignIn().signIn();

    if (googleUser == null) {
      throw Exception('Google sign-in cancelled.');
    }

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await GoogleSignIn().signOut();
    }

    await _auth.signOut();
  }

  String friendlyAuthError(Object error) {
    if (error is! FirebaseAuthException) {
      return 'Something went wrong. Please try again.';
    }

    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is incorrect.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Use a stronger password with at least 6 characters.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}
