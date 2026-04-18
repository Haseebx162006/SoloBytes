import 'package:solobytes/domain/entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;

  Future<UserEntity> signInAnonymously();

  Future<UserEntity> signInWithEmail(String email, String password);

  Future<UserEntity> signUpWithEmail(
    String email,
    String password, {
    String? name,
  });

  Future<void> signOut();
}
