import 'package:solobytes/data/repositories/person_account_repository_impl.dart';
import 'package:solobytes/data/repositories/transaction_repository_impl.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class AddTransactionUseCase {
  const AddTransactionUseCase(
    this._transactionRepository,
    this._personAccountRepository,
  );

  final TransactionRepositoryImpl _transactionRepository;
  final PersonAccountRepositoryImpl _personAccountRepository;

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
    if (source != 'manual' && 
        source != 'excel_import' && 
        source != 'ledger_payment') {
      throw Exception('Invalid source');
    }

    // Add the transaction
    final savedTransaction = await _transactionRepository.addTransaction(transaction);

    // Update person account if personName is provided and it's an expense
    if (transaction.personName != null && 
        transaction.personName!.trim().isNotEmpty &&
        transaction.type == TxType.expense) {
      try {
        // For expenses, we owe them money (negative balance for us)
        await _personAccountRepository.updateOrCreate(
          userId: transaction.userId,
          name: transaction.personName!,
          amountChange: -transaction.amount,
        );
      } catch (_) {
        // Continue even if person account update fails
      }
    }

    return savedTransaction;
  }
}
