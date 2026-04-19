import 'package:solobytes/data/repositories/person_account_repository_impl.dart';
import 'package:solobytes/data/repositories/receivable_repository_impl.dart';
import 'package:solobytes/data/repositories/transaction_repository_impl.dart';
import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class TrackReceivableUseCase {
  const TrackReceivableUseCase(
    this._repository,
    this._personAccountRepository,
    this._transactionRepository,
  );

  final ReceivableRepositoryImpl _repository;
  final PersonAccountRepositoryImpl _personAccountRepository;
  final TransactionRepositoryImpl _transactionRepository;

  Future<ReceivableEntity> execute({
    required LedgerEntryType entryType,
    required String userId,
    required String name,
    required double amount,
    required DateTime dueDate,
    String? invoiceRef,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw Exception('User is required');
    }

    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw Exception('Name is required');
    }

    if (amount <= 0) {
      throw Exception('Amount must be greater than 0');
    }

    final normalizedInvoiceRef = invoiceRef?.trim();
    final now = DateTime.now();

    final item = ReceivableEntity(
      id: '',
      userId: normalizedUserId,
      entryType: entryType,
      customerName: entryType == LedgerEntryType.receivable
          ? normalizedName
          : '',
      vendorName: entryType == LedgerEntryType.payable ? normalizedName : '',
      amount: amount,
      dueDate: dueDate,
      status: PaymentStatus.unpaid,
      invoiceRef: normalizedInvoiceRef == null || normalizedInvoiceRef.isEmpty
          ? null
          : normalizedInvoiceRef,
      createdAt: now,
      paidAt: null,
    );

    final savedItem = await _repository.saveItem(item);

    final transactionType = entryType == LedgerEntryType.receivable
        ? TxType.sale
        : TxType.expense;

    final transactionNature = entryType == LedgerEntryType.receivable
        ? TransactionNature.owedToUs
        : TransactionNature.weOwe;

    try {
      await _transactionRepository.addTransaction(
        TransactionEntity(
          id: '',
          userId: normalizedUserId,
          type: transactionType,
          nature: transactionNature,
          category: entryType == LedgerEntryType.receivable
              ? 'Receivable'
              : 'Payable',
          amount: amount,
          note: entryType == LedgerEntryType.receivable
              ? 'Receivable recorded for $normalizedName'
              : 'Payable recorded for $normalizedName',
          date: now,
          source: 'ledger_debt',
          personName: normalizedName,
        ),
      );
    } catch (_) {
      // Roll back the ledger record if transaction creation fails.
      try {
        await _repository.deleteItem(
          entryType: entryType,
          itemId: savedItem.id,
        );
      } catch (_) {
        // Ignore rollback failures and surface the original error.
      }
      rethrow;
    }

    try {
      // Update PersonAccount balance
      // If receivable, they owe us (+amount)
      // If payable, we owe them (-amount)
      final amountChange = entryType == LedgerEntryType.receivable
          ? amount
          : -amount;

      await _personAccountRepository.updateOrCreate(
        userId: normalizedUserId,
        name: normalizedName,
        amountChange: amountChange,
      );
    } catch (_) {
      // Continue even if person account update fails
    }

    return savedItem;
  }
}
