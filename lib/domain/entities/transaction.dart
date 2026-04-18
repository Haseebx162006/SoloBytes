enum TxType { sale, expense }

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
    this.personName,
  });

  final String id;
  final String userId;
  final TxType type;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final String source;
  final String? personName;

  bool get isSale => type == TxType.sale;
  bool get isExpense => type == TxType.expense;

  TransactionEntity copyWith({
    String? id,
    String? userId,
    TxType? type,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
    String? source,
    String? personName,
    bool clearPersonName = false,
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
      personName: clearPersonName ? null : (personName ?? this.personName),
    );
  }
}