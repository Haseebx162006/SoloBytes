import 'package:solobytes/domain/entities/user_entity.dart';
import 'package:solobytes/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<UserEntity> executeGoogle() {
    return _authRepository.signInWithGoogle();
  }

  Future<UserEntity> executeEmail(String email, String password) {
    return _authRepository.signInWithEmail(email, password);
  }
}
