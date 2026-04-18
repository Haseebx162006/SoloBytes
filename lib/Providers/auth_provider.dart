import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:solobytes/application/usecases/check_business_profile_usecase.dart';
import 'package:solobytes/application/usecases/login_usecase.dart';
import 'package:solobytes/application/usecases/save_business_profile_usecase.dart';
import 'package:solobytes/data/repositories/auth_repository_impl.dart';
import 'package:solobytes/domain/entities/user_entity.dart';
import 'package:solobytes/domain/repositories/auth_repository.dart';

enum AuthAccessState { unauthenticated, needsBusinessSetup, authenticated }

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final googleSignInProvider = Provider<GoogleSignIn>((ref) {
  return GoogleSignIn.instance;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  final firestore = ref.watch(authFirestoreProvider);
  final googleSignIn = ref.watch(googleSignInProvider);

  return AuthRepositoryImpl(
    firebaseAuth: firebaseAuth,
    firestore: firestore,
    googleSignIn: googleSignIn,
  );
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return LoginUseCase(authRepository);
});

final checkBusinessProfileUseCaseProvider =
    Provider<CheckBusinessProfileUseCase>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return CheckBusinessProfileUseCase(authRepository);
    });

final saveBusinessProfileUseCaseProvider =
    Provider<SaveBusinessProfileUseCase>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return SaveBusinessProfileUseCase(authRepository);
    });

final authStateChangesProvider = StreamProvider<UserEntity?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
});

final authUserProvider = Provider<UserEntity?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, _) => null,
  );
});

final businessProfileProvider = FutureProvider<bool>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) {
    return false;
  }

  final useCase = ref.watch(checkBusinessProfileUseCaseProvider);
  return useCase.execute(user.uid);
});

final authAccessStateProvider = FutureProvider<AuthAccessState>((ref) async {
  final user = ref.watch(authUserProvider);
  if (user == null) {
    return AuthAccessState.unauthenticated;
  }

  final useCase = ref.watch(checkBusinessProfileUseCaseProvider);
  final hasProfile = await useCase.execute(user.uid);

  if (hasProfile) {
    return AuthAccessState.authenticated;
  }

  return AuthAccessState.needsBusinessSetup;
});

final authActionLoadingProvider =
    NotifierProvider<AuthActionLoadingNotifier, bool>(
      AuthActionLoadingNotifier.new,
    );

final businessSetupProvider =
    NotifierProvider<BusinessSetupNotifier, bool>(BusinessSetupNotifier.new);

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

class BusinessSetupNotifier extends Notifier<bool> {
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
