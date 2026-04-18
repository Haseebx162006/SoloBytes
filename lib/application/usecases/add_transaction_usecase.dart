import 'package:solobytes/data/repositories/transaction_repository_impl.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class AddTransactionUseCase {
  const AddTransactionUseCase(this._transactionRepository);

  final TransactionRepositoryImpl _transactionRepository;

  Future<TransactionEntity> execute(TransactionEntity transaction) async {
    if (transaction.userId.trim().isEmpty) {
      throw Exception('User is required');
    }

    if (transaction.amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }

    if (transaction.category.trim().isEmpty) {
      throw Exception('Category is required');
    }

    final source = transaction.source.trim();
    if (source != 'manual' && source != 'excel_import') {
      throw Exception('Source must be manual or excel_import');
    }

    return _transactionRepository.addTransaction(transaction);
  }
}
