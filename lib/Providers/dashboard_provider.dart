import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/transactions_provider.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class CashSummary {
  final double netBalance;
  final double totalSales;
  final double totalExpenses;
  final double totalOwedToUs;
  final double totalWeOwe;
  final int unpaidReceivables;
  final int unpaidPayables;
  final String topExpenseCategory;
  final String period;

  const CashSummary({
    required this.netBalance,
    required this.totalSales,
    required this.totalExpenses,
    required this.totalOwedToUs,
    required this.totalWeOwe,
    required this.unpaidReceivables,
    required this.unpaidPayables,
    required this.topExpenseCategory,
    required this.period,
  });
}

final dashboardProvider = FutureProvider<CashSummary>((ref) async {
  final transactionsAsync = ref.watch(transactionsProvider);

  return transactionsAsync.when(
    data: (transactions) {
      double totalSales = 0;
      double totalExpenses = 0;

      final Map<String, double> expenseCategoryMap = {};

      // 🔥 CORE FIX: SAFE CALCULATION
      for (final tx in transactions) {
        final amount = tx.amount.abs(); // phandles negative + positive

        if (tx.type == TxType.expense) {
          totalExpenses += amount;

          // Track expense categories
          expenseCategoryMap[tx.category] =
              (expenseCategoryMap[tx.category] ?? 0) + amount;
        } else {
          // sale + income treated as positive inflow
          totalSales += amount;
        }
      }

      final netBalance = totalSales - totalExpenses;

      // 🔹 Find top expense category
      String topCategory = '';
      double maxExpense = 0;

      expenseCategoryMap.forEach((category, value) {
        if (value > maxExpense) {
          maxExpense = value;
          topCategory = category;
        }
      });

      return CashSummary(
        netBalance: netBalance,
        totalSales: totalSales,
        totalExpenses: totalExpenses,
        totalOwedToUs: 0, // you can extend later
        totalWeOwe: 0,
        unpaidReceivables: 0,
        unpaidPayables: 0,
        topExpenseCategory: topCategory,
        period: 'All Time',
      );
    },

    loading: () {
      throw const AsyncLoading();
    },

    error: (err, stack) {
      throw err!;
    },
  );
});
