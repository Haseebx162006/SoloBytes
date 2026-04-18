class PersonAccount {
  const PersonAccount({
    required this.id,
    required this.userId,
    required this.name,
    required this.balance,
    required this.lastTransactionDate,
    required this.transactionCount,
  });

  final String id;
  final String userId;
  final String name;
  final double balance; // Positive = they owe us, Negative = we owe them
  final DateTime lastTransactionDate;
  final int transactionCount;

  PersonAccount copyWith({
    String? id,
    String? userId,
    String? name,
    double? balance,
    DateTime? lastTransactionDate,
    int? transactionCount,
  }) {
    return PersonAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      transactionCount: transactionCount ?? this.transactionCount,
    );
  }

  bool get owesUs => balance > 0;
  bool get weOweThem => balance < 0;
  bool get isSettled => balance == 0;
}
