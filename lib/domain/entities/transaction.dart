enum TxType { income, expense, sale }

class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.source,
  });

  final String id;
  final String userId;
  final TxType type;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final String source;

  TransactionEntity copyWith({
    String? id,
    String? userId,
    TxType? type,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
    String? source,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      source: source ?? this.source,
    );
  }
}