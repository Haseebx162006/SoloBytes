import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solobytes/domain/entities/user_entity.dart';
import 'package:solobytes/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required FirebaseAuth firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth,
       _firestore = firestore ?? FirebaseFirestore.instance,
      _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;
    bool _isGoogleSignInInitialized = false;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInInitialized();

      final googleUser = await _googleSignIn.authenticate();

      final googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw const AuthException('Google sign-in failed. Please try again.');
      }

      final credential = GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );

      final user = _mapFirebaseUser(userCredential.user);

      if (user == null) {
        throw const AuthException('Google sign-in failed. Please try again.');
      }

      return user;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled ||
          error.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthException('Google sign-in was cancelled.');
      }

      throw AuthException(error.description ?? 'Google sign-in failed.');
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    } on AuthException {
      rethrow;
    } catch (_) {
      throw const AuthException('Google sign-in failed. Please try again.');
    }
  }

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Email and password are required.');
    }

    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = _mapFirebaseUser(credential.user);
      if (user == null) {
        throw const AuthException('Email sign-in failed. Please try again.');
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    } catch (_) {
      throw const AuthException('Email sign-in failed. Please try again.');
    }
  }

  @override
  Future<UserEntity> signUpWithEmail(
    String email,
    String password, {
    String? name,
  }) async {
    if (email.trim().isEmpty || password.isEmpty) {
      throw const AuthException('Email and password are required.');
    }

    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final createdUser = credential.user;
      if (createdUser == null) {
        throw const AuthException('Sign-up failed. Please try again.');
      }

      final trimmedName = name?.trim();
      if (trimmedName != null && trimmedName.isNotEmpty) {
        await createdUser.updateDisplayName(trimmedName);
        await createdUser.reload();
      }

      final currentUser = _firebaseAuth.currentUser ?? createdUser;
      final user = _mapFirebaseUser(currentUser);
      if (user == null) {
        throw const AuthException('Sign-up failed. Please try again.');
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    } catch (_) {
      throw const AuthException('Sign-up failed. Please try again.');
    }
  }

  @override
  Future<bool> hasCompletedBusinessProfile(String userId) async {
    if (userId.trim().isEmpty) {
      return false;
    }

    try {
      final snapshot = await _businessProfileDoc(userId).get();
      if (!snapshot.exists) {
        return false;
      }

      final data = snapshot.data();
      if (data == null) {
        return false;
      }

      final businessName = (data['businessName'] ?? '').toString().trim();
      final businessType = (data['businessType'] ?? '').toString().trim();

      return businessName.isNotEmpty && businessType.isNotEmpty;
    } on FirebaseException {
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> saveBusinessProfile({
    required String userId,
    required String businessName,
    required String businessType,
    String? businessEmail,
  }) async {
    if (userId.trim().isEmpty) {
      throw const AuthException('User is required to save business profile.');
    }

    try {
      final docRef = _businessProfileDoc(userId);
      final snapshot = await docRef.get();

      final payload = <String, dynamic>{
        'businessName': businessName.trim(),
        'businessType': businessType.trim(),
        'businessEmail': (businessEmail ?? '').trim(),
      };

      if (!snapshot.exists) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      await docRef.set(payload, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      throw AuthException(
        error.message ?? 'Unable to save business profile. Please try again.',
      );
    } catch (_) {
      throw const AuthException(
        'Unable to save business profile. Please try again.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      if (_isGoogleSignInInitialized) {
        await _googleSignIn.signOut();
      }
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    } catch (_) {
      throw const AuthException('Sign-out failed. Please try again.');
    }
  }

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) {
      return;
    }

    await _googleSignIn.initialize();
    _isGoogleSignInInitialized = true;
  }

  UserEntity? _mapFirebaseUser(User? user) {
    if (user == null) {
      return null;
    }

    return UserEntity(
      uid: user.uid,
      email: user.email,
      isAnonymous: user.isAnonymous,
    );
  }

  DocumentReference<Map<String, dynamic>> _businessProfileDoc(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('businessProfile')
        .doc('profile');
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check email and password.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled in Firebase Console.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'popup-closed-by-user':
        return 'Google sign-in was cancelled.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
