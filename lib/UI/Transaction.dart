// lib/domain/entities/transaction.dart

enum TxType {
  sale, // income / sale — used as TxType.sale across TransactionsTab
  expense, // outgoing expense
}

class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
    this.note = '',
    this.source = 'manual',
  });

  final String id;
  final String userId;
  final TxType type;
  final String category;
  final double amount;
  final DateTime date;
  final String description; // used in TransactionsTab: tx.description
  final String note; // used in TransactionRepositoryImpl: transaction.note
  final String source; // "manual" | "excel_import"

  /// Convenience getter — mirrors the isSale check in TransactionsTab
  bool get isSale => type == TxType.sale;

  TransactionEntity copyWith({
    String? id,
    String? userId,
    TxType? type,
    String? category,
    double? amount,
    DateTime? date,
    String? description,
    String? note,
    String? source,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      note: note ?? this.note,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TransactionEntity(id: $id, type: ${type.name}, '
      'amount: $amount, category: $category, date: $date)';
}
