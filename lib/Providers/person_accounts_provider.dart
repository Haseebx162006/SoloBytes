import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/data/repositories/person_account_repository_impl.dart';
import 'package:solobytes/domain/entities/person_account.dart';
import 'package:solobytes/domain/entities/user_entity.dart';

final personAccountsFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final personAccountsRepositoryProvider =
    Provider<PersonAccountRepositoryImpl>((ref) {
  final firestore = ref.watch(personAccountsFirestoreProvider);
  return PersonAccountRepositoryImpl(firestore: firestore);
});

final personAccountsProvider =
    StreamProvider<List<PersonAccount>>((ref) {
  final accessState = ref.watch(authAccessStateProvider);
  if (!_isAuthenticatedAccess(accessState)) {
    return Stream.value(const []);
  }

  final authState = ref.watch(authStateChangesProvider);
  final currentUser = _userFromAuthState(authState);
  if (currentUser == null || currentUser.uid.trim().isEmpty) {
    return Stream.value(const []);
  }

  final repository = ref.watch(personAccountsRepositoryProvider);
  return repository.watchAccounts(userId: currentUser.uid);
});

UserEntity? _userFromAuthState(AsyncValue<UserEntity?> authState) {
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (_, _) => null,
  );
}

bool _isAuthenticatedAccess(AsyncValue<AuthAccessState> accessState) {
  return accessState.when(
    data: (state) => state == AuthAccessState.authenticated,
    loading: () => false,
    error: (_, _) => false,
  );
}
