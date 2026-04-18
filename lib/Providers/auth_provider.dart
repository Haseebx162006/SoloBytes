import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/application/usecases/login_usecase.dart';
import 'package:solobytes/data/repositories/auth_repository_impl.dart';
import 'package:solobytes/domain/entities/user_entity.dart';
import 'package:solobytes/domain/repositories/auth_repository.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthRepositoryImpl(firebaseAuth: firebaseAuth);
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginUseCase(authRepository);
});

final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final authActionLoadingProvider =
    NotifierProvider<AuthActionLoadingNotifier, bool>(
      AuthActionLoadingNotifier.new,
    );

class AuthActionLoadingNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void start() {
    state = true;
  }

  void stop() {
    state = false;
  }
}
