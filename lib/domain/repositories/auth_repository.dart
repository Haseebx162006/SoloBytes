import 'package:solobytes/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  Future<UserEntity> signInWithGoogle();

  Future<UserEntity> signInWithEmail(String email, String password);

  Future<UserEntity> signUpWithEmail(
    String email,
    String password, {
    String? name,
  });

  Future<bool> isUserFullyRegistered(String userId);

  Future<bool> hasCompletedBusinessProfile(String userId);

  Future<void> saveBusinessProfile({
    required String userId,
    required String businessName,
    required String businessType,
    String? businessEmail,
  });

  Future<void> signOut();
}
