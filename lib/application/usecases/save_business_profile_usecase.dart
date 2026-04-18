import 'package:solobytes/domain/repositories/auth_repository.dart';

class SaveBusinessProfileUseCase {
  const SaveBusinessProfileUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<void> execute({
    required String userId,
    required String businessName,
    required String businessType,
    String? businessEmail,
  }) async {
    final trimmedName = businessName.trim();
    final trimmedType = businessType.trim();

    if (trimmedName.isEmpty) {
      throw Exception('Business name is required.');
    }

    if (trimmedType.isEmpty) {
      throw Exception('Business type is required.');
    }

    await _authRepository.saveBusinessProfile(
      userId: userId,
      businessName: trimmedName,
      businessType: trimmedType,
      businessEmail: businessEmail,
    );
  }
}
