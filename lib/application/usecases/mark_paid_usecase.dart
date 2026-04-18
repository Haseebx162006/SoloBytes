import 'package:solobytes/data/repositories/person_account_repository_impl.dart';
import 'package:solobytes/data/repositories/receivable_repository_impl.dart';
import 'package:solobytes/data/repositories/transaction_repository_impl.dart';
import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class MarkPaidUseCase {
  const MarkPaidUseCase(
    this._receivableRepository,
    this._transactionRepository,
    this._personAccountRepository,
  );

  final ReceivableRepositoryImpl _receivableRepository;
  final TransactionRepositoryImpl _transactionRepository;
  final PersonAccountRepositoryImpl _personAccountRepository;

  Future<void> execute({
    required LedgerEntryType entryType,
    required String itemId,
    required String userId,
    required ReceivableEntity item,
  }) async {
    final normalizedId = itemId.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Item id is required');
    }

    final paidAt = DateTime.now();

    // Mark the receivable/payable as paid
    await _receivableRepository.markPaid(
      entryType: entryType,
      itemId: normalizedId,
      paidAt: paidAt,
    );

    // Create a corresponding transaction
    final txType = entryType == LedgerEntryType.receivable
        ? TxType.sale
        : TxType.expense;

    final transaction = TransactionEntity(
      id: '',
      userId: userId,
      type: txType,
      category: entryType == LedgerEntryType.receivable
          ? 'Receivable Payment'
          : 'Payable Payment',
      amount: item.amount,
      note: entryType == LedgerEntryType.receivable
          ? 'Payment received from ${item.partyName}'
          : 'Payment made to ${item.partyName}',
      date: paidAt,
      source: 'ledger_payment',
      personName: item.partyName,
      productName: entryType == LedgerEntryType.receivable
          ? 'Ledger Payment'
          : null,
    );

    await _transactionRepository.addTransaction(transaction);

    try {
      // Offset the person's account balance
      // If payable, we owed them negative money, so paying them adds positive balance back to 0.
      // If receivable, they owed us positive money, so paying us adds negative balance back to 0.
      final amountChange = entryType == LedgerEntryType.receivable
          ? -item.amount
          : item.amount;

      await _personAccountRepository.updateOrCreate(
        userId: userId,
        name: item.partyName,
        amountChange: amountChange,
      );
    } catch (_) {
      // Continue safely
    }
  }
}
