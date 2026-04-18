import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/application/usecases/mark_paid_usecase.dart';
import 'package:solobytes/application/usecases/track_receivable_usecase.dart';
import 'package:solobytes/data/repositories/receivable_repository_impl.dart';
import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/user_entity.dart';

class LedgerItemsQuery {
  const LedgerItemsQuery({required this.entryType, this.status});

  final LedgerEntryType entryType;
  final PaymentStatus? status;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is LedgerItemsQuery &&
        other.entryType == entryType &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(entryType, status);
}

final receivablesFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final receivableRepositoryProvider = Provider<ReceivableRepositoryImpl>((ref) {
  final firestore = ref.watch(receivablesFirestoreProvider);
  return ReceivableRepositoryImpl(firestore: firestore);
});

final trackReceivableUseCaseProvider = Provider<TrackReceivableUseCase>((ref) {
  final repository = ref.watch(receivableRepositoryProvider);
  return TrackReceivableUseCase(repository);
});

final markPaidUseCaseProvider = Provider<MarkPaidUseCase>((ref) {
  final repository = ref.watch(receivableRepositoryProvider);
  return MarkPaidUseCase(repository);
});

final ledgerItemsProvider =
    StreamProvider.family<List<ReceivableEntity>, LedgerItemsQuery>((
      ref,
      query,
    ) {
      final accessState = ref.watch(authAccessStateProvider);
      if (!_isAuthenticatedAccess(accessState)) {
        return Stream.value(const []);
      }

      final authState = ref.watch(authStateChangesProvider);
      final currentUser = _userFromAuthState(authState);
      if (currentUser == null || currentUser.uid.trim().isEmpty) {
        return Stream.value(const []);
      }

      final repository = ref.watch(receivableRepositoryProvider);
      return repository.watchItems(
        userId: currentUser.uid,
        entryType: query.entryType,
        status: query.status,
      );
    });

final receivablesProvider = Provider<AsyncValue<List<ReceivableEntity>>>(
  (ref) {
    return ref.watch(
      ledgerItemsProvider(
        const LedgerItemsQuery(entryType: LedgerEntryType.receivable),
      ),
    );
  },
);

final unpaidReceivablesProvider =
    Provider<AsyncValue<List<ReceivableEntity>>>((ref) {
      return ref.watch(
        ledgerItemsProvider(
          const LedgerItemsQuery(
            entryType: LedgerEntryType.receivable,
            status: PaymentStatus.unpaid,
          ),
        ),
      );
    });

final paidReceivablesProvider = Provider<AsyncValue<List<ReceivableEntity>>>(
  (ref) {
    return ref.watch(
      ledgerItemsProvider(
        const LedgerItemsQuery(
          entryType: LedgerEntryType.receivable,
          status: PaymentStatus.paid,
        ),
      ),
    );
  },
);

final overdueReceivablesProvider =
    Provider<AsyncValue<List<ReceivableEntity>>>((ref) {
      return ref.watch(
        ledgerItemsProvider(
          const LedgerItemsQuery(
            entryType: LedgerEntryType.receivable,
            status: PaymentStatus.overdue,
          ),
        ),
      );
    });

final payablesProvider = Provider<AsyncValue<List<ReceivableEntity>>>((ref) {
  return ref.watch(
    ledgerItemsProvider(
      const LedgerItemsQuery(entryType: LedgerEntryType.payable),
    ),
  );
});

final unpaidPayablesProvider = Provider<AsyncValue<List<ReceivableEntity>>>(
  (ref) {
    return ref.watch(
      ledgerItemsProvider(
        const LedgerItemsQuery(
          entryType: LedgerEntryType.payable,
          status: PaymentStatus.unpaid,
        ),
      ),
    );
  },
);

final paidPayablesProvider = Provider<AsyncValue<List<ReceivableEntity>>>(
  (ref) {
    return ref.watch(
      ledgerItemsProvider(
        const LedgerItemsQuery(
          entryType: LedgerEntryType.payable,
          status: PaymentStatus.paid,
        ),
      ),
    );
  },
);

final overduePayablesProvider = Provider<AsyncValue<List<ReceivableEntity>>>(
  (ref) {
    return ref.watch(
      ledgerItemsProvider(
        const LedgerItemsQuery(
          entryType: LedgerEntryType.payable,
          status: PaymentStatus.overdue,
        ),
      ),
    );
  },
);

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
