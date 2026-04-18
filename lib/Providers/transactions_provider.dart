import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/application/usecases/add_transaction_usecase.dart';
import 'package:solobytes/application/usecases/get_transactions_usecase.dart';
import 'package:solobytes/data/repositories/person_account_repository_impl.dart';
import 'package:solobytes/data/repositories/transaction_repository_impl.dart';
import 'package:solobytes/domain/entities/transaction.dart';
import 'package:solobytes/domain/entities/user_entity.dart';

class TransactionsFilterState {
  const TransactionsFilterState({
    this.selectedType,
    this.category,
    this.startDate,
    this.endDate,
  });

  final TxType? selectedType;
  final String? category;
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionsFilterState copyWith({
    TxType? selectedType,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    bool clearType = false,
    bool clearCategory = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
  }) {
    return TransactionsFilterState(
      selectedType: clearType ? null : (selectedType ?? this.selectedType),
      category: clearCategory ? null : (category ?? this.category),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
    );
  }
}

final transactionsFilterProvider =
    NotifierProvider<TransactionsFilterNotifier, TransactionsFilterState>(
      TransactionsFilterNotifier.new,
    );

class TransactionsFilterNotifier extends Notifier<TransactionsFilterState> {
  @override
  TransactionsFilterState build() {
    return const TransactionsFilterState();
  }

  void setType(TxType? type) {
    state = state.copyWith(selectedType: type, clearType: type == null);
  }

  void setCategory(String? value) {
    final normalized = value?.trim() ?? '';
    if (normalized.isEmpty) {
      state = state.copyWith(clearCategory: true);
      return;
    }

    state = state.copyWith(category: normalized);
  }

  void setDateRange({DateTime? startDate, DateTime? endDate}) {
    state = state.copyWith(
      startDate: startDate,
      endDate: endDate,
      clearStartDate: startDate == null,
      clearEndDate: endDate == null,
    );
  }

  void clearAll() {
    state = const TransactionsFilterState();
  }
}

final transactionsFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final transactionRepositoryProvider = Provider<TransactionRepositoryImpl>((
  ref,
) {
  final firestore = ref.watch(transactionsFirestoreProvider);
  return TransactionRepositoryImpl(firestore: firestore);
});

final personAccountRepositoryProvider = Provider<PersonAccountRepositoryImpl>((
  ref,
) {
  final firestore = ref.watch(transactionsFirestoreProvider);
  return PersonAccountRepositoryImpl(firestore: firestore);
});

final addTransactionUseCaseProvider = Provider<AddTransactionUseCase>((ref) {
  final transactionRepository = ref.watch(transactionRepositoryProvider);
  final personAccountRepository = ref.watch(personAccountRepositoryProvider);
  return AddTransactionUseCase(transactionRepository, personAccountRepository);
});

final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return GetTransactionsUseCase(repository);
});

final transactionsProvider =
    AsyncNotifierProvider<TransactionsNotifier, List<TransactionEntity>>(
      TransactionsNotifier.new,
    );

class TransactionsNotifier extends AsyncNotifier<List<TransactionEntity>> {
  @override
  Future<List<TransactionEntity>> build() async {
    final accessState = ref.watch(authAccessStateProvider);
    if (!_isAuthenticatedAccess(accessState)) {
      return const [];
    }

    final authState = ref.watch(authStateChangesProvider);
    final currentUser = _userFromAuthState(authState);
    final filters = ref.watch(transactionsFilterProvider);

    return _fetchTransactions(currentUser: currentUser, filters: filters);
  }

  Future<void> refresh() async {
    final accessState = ref.read(authAccessStateProvider);
    if (!_isAuthenticatedAccess(accessState)) {
      state = const AsyncData([]);
      return;
    }

    final authState = ref.read(authStateChangesProvider);
    final currentUser = _userFromAuthState(authState);
    final filters = ref.read(transactionsFilterProvider);

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _fetchTransactions(currentUser: currentUser, filters: filters),
    );
  }

  void setType(TxType? type) {
    ref.read(transactionsFilterProvider.notifier).setType(type);
  }

  void setCategory(String? category) {
    ref.read(transactionsFilterProvider.notifier).setCategory(category);
  }

  void setDateRange({DateTime? startDate, DateTime? endDate}) {
    ref
        .read(transactionsFilterProvider.notifier)
        .setDateRange(startDate: startDate, endDate: endDate);
  }

  void clearFilters() {
    ref.read(transactionsFilterProvider.notifier).clearAll();
  }

  Future<void> add(TransactionEntity transaction) async {
    final accessState = ref.read(authAccessStateProvider);
    if (!_isAuthenticatedAccess(accessState)) {
      throw Exception('Complete business setup to access transactions.');
    }

    final useCase = ref.read(addTransactionUseCaseProvider);
    await useCase.execute(transaction);
    await refresh();
  }

  Future<List<TransactionEntity>> _fetchTransactions({
    required UserEntity? currentUser,
    required TransactionsFilterState filters,
  }) async {
    if (currentUser == null || currentUser.uid.trim().isEmpty) {
      return const [];
    }

    final useCase = ref.read(getTransactionsUseCaseProvider);
    return useCase.execute(
      userId: currentUser.uid,
      startDate: filters.startDate,
      endDate: filters.endDate,
      type: filters.selectedType,
      category: filters.category,
    );
  }

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
}
