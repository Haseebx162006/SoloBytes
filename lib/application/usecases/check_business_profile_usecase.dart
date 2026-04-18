import 'package:solobytes/domain/repositories/auth_repository.dart';

class CheckBusinessProfileUseCase {
  const CheckBusinessProfileUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<bool> execute(String userId) {
    if (userId.trim().isEmpty) {
      return Future.value(false);
    }

    return _authRepository.isUserFullyRegistered(userId);
  }
}
