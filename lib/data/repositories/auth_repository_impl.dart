import 'package:firebase_auth/firebase_auth.dart';
import 'package:solobytes/domain/entities/user_entity.dart';
import 'package:solobytes/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required FirebaseAuth firebaseAuth})
    : _firebaseAuth = firebaseAuth;

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<UserEntity?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map(_mapFirebaseUser);
  }

  @override
  Future<UserEntity> signInAnonymously() async {
    try {
      final credential = await _firebaseAuth.signInAnonymously();
      final user = _mapFirebaseUser(credential.user);

      if (user == null) {
        throw const AuthException(
          'Anonymous sign-in failed. Please try again.',
        );
      }

      return user;
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    } catch (_) {
      throw const AuthException('Anonymous sign-in failed. Please try again.');
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
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw AuthException(_mapFirebaseError(error));
    } catch (_) {
      throw const AuthException('Sign-out failed. Please try again.');
    }
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
