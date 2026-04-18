import 'package:solobytes/data/repositories/receivable_repository_impl.dart';
import 'package:solobytes/domain/entities/receivable.dart';

class TrackReceivableUseCase {
  const TrackReceivableUseCase(this._repository);

  final ReceivableRepositoryImpl _repository;

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
      customerName:
          entryType == LedgerEntryType.receivable ? normalizedName : '',
      vendorName: entryType == LedgerEntryType.payable ? normalizedName : '',
      amount: amount,
      dueDate: dueDate,
      status: PaymentStatus.unpaid,
      invoiceRef:
          normalizedInvoiceRef == null || normalizedInvoiceRef.isEmpty
          ? null
          : normalizedInvoiceRef,
      createdAt: now,
      paidAt: null,
    );

    return _repository.saveItem(item);
  }
}
