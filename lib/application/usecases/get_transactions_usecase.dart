import 'package:solobytes/data/repositories/transaction_repository_impl.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class GetTransactionsUseCase {
  const GetTransactionsUseCase(this._transactionRepository);

  final TransactionRepositoryImpl _transactionRepository;

  Future<List<TransactionEntity>> execute({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TxType? type,
    String? category,
  }) {
    if (userId.trim().isEmpty) {
      return Future.value(const []);
    }

    return _transactionRepository.getTransactions(
      userId: userId,
      startDate: startDate,
      endDate: endDate,
      type: type,
      category: category,
    );
  }
}
