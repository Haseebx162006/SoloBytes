enum TxType { sale, expense }

enum TransactionNature { normal, weOwe, owedToUs }

class TransactionEntity {
  const TransactionEntity({
    required this.id,
    required this.userId,
    required this.type,
    this.nature = TransactionNature.normal,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.source,
    this.personName,
    this.productName,
  });

  final String id;
  final String userId;
  final TxType type;
  final TransactionNature nature;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final String source;
  final String? personName;
  final String? productName;

  bool get isIncome => type == TxType.sale;
  bool get isSale => type == TxType.sale;
  bool get isExpense => type == TxType.expense;
  bool get isNormalNature => nature == TransactionNature.normal;
  bool get isDebtNature => !isNormalNature;

  String get kindLabel {
    if (nature == TransactionNature.weOwe) {
      return 'We Owe';
    }

    if (nature == TransactionNature.owedToUs) {
      return 'Owed to Us';
    }

    return isExpense ? 'Expense' : 'Income';
  }

  TransactionEntity copyWith({
    String? id,
    String? userId,
    TxType? type,
    TransactionNature? nature,
    String? category,
    double? amount,
    String? note,
    DateTime? date,
    String? source,
    String? personName,
    bool clearPersonName = false,
    String? productName,
    bool clearProductName = false,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      nature: nature ?? this.nature,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      note: note ?? this.note,
      date: date ?? this.date,
      source: source ?? this.source,
      personName: clearPersonName ? null : (personName ?? this.personName),
      productName: clearProductName ? null : (productName ?? this.productName),
    );
  }
}
