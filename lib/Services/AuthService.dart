import 'package:firebase_auth/firebase_auth.dart';
import 'package:solobytes/data/repositories/auth_repository_impl.dart';
import 'package:solobytes/domain/repositories/auth_repository.dart';

class AuthService {
  AuthService({AuthRepository? authRepository})
    : _authRepository =
          authRepository ??
          AuthRepositoryImpl(firebaseAuth: FirebaseAuth.instance);

  final AuthRepository _authRepository;

  Future<String?> signIn(String email, String password) async {
    try {
      await _authRepository.signInWithEmail(email, password);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> signInAnonymously() async {
    try {
      await _authRepository.signInAnonymously();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logOut() async {
    return _authRepository.signOut();
  }

  @Deprecated('Use logOut instead.')
  Future<void> LogOut() async {
    return logOut();
  }

  Future<String?> signUp(String name, String email, String password) async {
    try {
      await _authRepository.signUpWithEmail(email, password, name: name);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
