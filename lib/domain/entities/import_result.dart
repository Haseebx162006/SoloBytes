import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class ImportResult {
  const ImportResult({
    this.transactions = const [],
    this.receivables = const [],
    this.errors = const [],
    this.successCount = 0,
    this.failedCount = 0,
    this.isSchemaValid = true,
  });

  final List<TransactionEntity> transactions;
  final List<ReceivableEntity> receivables;
  final List<String> errors;
  final int successCount;
  final int failedCount;
  final bool isSchemaValid;

  bool get hasData => transactions.isNotEmpty || receivables.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;

  ImportResult copyWith({
    List<TransactionEntity>? transactions,
    List<ReceivableEntity>? receivables,
    List<String>? errors,
    int? successCount,
    int? failedCount,
    bool? isSchemaValid,
  }) {
    return ImportResult(
      transactions: transactions ?? this.transactions,
      receivables: receivables ?? this.receivables,
      errors: errors ?? this.errors,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
      isSchemaValid: isSchemaValid ?? this.isSchemaValid,
    );
  }
}
