class CashSummary {
  const CashSummary({
    required this.totalSales,
    required this.totalExpenses,
    required this.netBalance,
    required this.unpaidReceivables,
    required this.unpaidPayables,
    required this.totalOwedToUs,
    required this.totalWeOwe,
    required this.topExpenseCategory,
    required this.period,
  });

  final double totalSales;
  final double totalExpenses;
  final double netBalance;
  final int unpaidReceivables;
  final int unpaidPayables;
  final double totalOwedToUs;
  final double totalWeOwe;
  final String topExpenseCategory;
  final String period;
}
