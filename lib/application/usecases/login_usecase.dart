import 'package:solobytes/domain/entities/user_entity.dart';
import 'package:solobytes/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<UserEntity> executeAnonymous() {
    return _authRepository.signInAnonymously();
  }

  Future<UserEntity> executeEmail(String email, String password) {
    return _authRepository.signInWithEmail(email, password);
  }
}
