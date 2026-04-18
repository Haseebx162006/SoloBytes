import 'package:solobytes/data/repositories/receivable_repository_impl.dart';
import 'package:solobytes/domain/entities/receivable.dart';

class MarkPaidUseCase {
  const MarkPaidUseCase(this._repository);

  final ReceivableRepositoryImpl _repository;

  Future<void> execute({
    required LedgerEntryType entryType,
    required String itemId,
  }) async {
    final normalizedId = itemId.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Item id is required');
    }

    await _repository.markPaid(
      entryType: entryType,
      itemId: normalizedId,
      paidAt: DateTime.now(),
    );
  }
}
