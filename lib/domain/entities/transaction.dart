enum TxType { income, expense }

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
}
