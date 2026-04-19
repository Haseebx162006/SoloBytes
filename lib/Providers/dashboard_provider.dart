import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Providers/transactions_provider.dart';
import 'package:solobytes/domain/entities/transaction.dart';
import 'package:solobytes/Providers/receivables_provider.dart';
import 'package:solobytes/domain/entities/receivable.dart';

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
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.when(
    data: (u) => u,
    loading: () => null,
    error: (_, __) => null,
  );

  if (user == null || user.uid.isEmpty) {
    throw Exception('User not authenticated');
  }

  final transactionsAsync = ref.watch(transactionsProvider);
  final receivablesAsync = ref.watch(
    ledgerItemsProvider(
      const LedgerItemsQuery(entryType: LedgerEntryType.receivable),
    ),
  );
  final payablesAsync = ref.watch(
    ledgerItemsProvider(
      const LedgerItemsQuery(entryType: LedgerEntryType.payable),
    ),
  );

  final transactions = await _resolveTransactions(
    ref: ref,
    asyncValue: transactionsAsync,
  );
  final receivables = await _resolveLedgerItems(
    ref: ref,
    asyncValue: receivablesAsync,
    query: const LedgerItemsQuery(entryType: LedgerEntryType.receivable),
  );
  final payables = await _resolveLedgerItems(
    ref: ref,
    asyncValue: payablesAsync,
    query: const LedgerItemsQuery(entryType: LedgerEntryType.payable),
  );

  double totalSales = 0;
  double totalExpenses = 0;

  final Map<String, double> expenseCategoryMap = {};

  // 🔥 CORE FIX: SAFE CALCULATION
  for (final tx in transactions) {
    if (!tx.isNormalNature) {
      continue;
    }

    final amount = tx.amount.abs(); // handles negative + positive

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

  int unpaidReceivablesCount = 0;
  double totalOwedToUs = 0.0;
  for (final item in receivables) {
    if (item.status == PaymentStatus.unpaid ||
        item.status == PaymentStatus.overdue) {
      unpaidReceivablesCount++;
      totalOwedToUs += item.amount;
    }
  }

  int unpaidPayablesCount = 0;
  double totalWeOwe = 0.0;
  for (final item in payables) {
    if (item.status == PaymentStatus.unpaid ||
        item.status == PaymentStatus.overdue) {
      unpaidPayablesCount++;
      totalWeOwe += item.amount;
    }
  }

  final netBalance = (totalSales - totalExpenses) + totalOwedToUs - totalWeOwe;

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
    totalOwedToUs: totalOwedToUs,
    totalWeOwe: totalWeOwe,
    unpaidReceivables: unpaidReceivablesCount,
    unpaidPayables: unpaidPayablesCount,
    topExpenseCategory: topCategory,
    period: 'All Time',
  );
});

Future<List<TransactionEntity>> _resolveTransactions({
  required Ref ref,
  required AsyncValue<List<TransactionEntity>> asyncValue,
}) async {
  return asyncValue.when(
    data: (items) => items,
    loading: () async {
      try {
        return await ref.watch(transactionsProvider.future);
      } catch (_) {
        return const [];
      }
    },
    error: (_, __) => const [],
  );
}

Future<List<ReceivableEntity>> _resolveLedgerItems({
  required Ref ref,
  required AsyncValue<List<ReceivableEntity>> asyncValue,
  required LedgerItemsQuery query,
}) async {
  return asyncValue.when(
    data: (items) => items,
    loading: () async {
      try {
        return await ref.watch(ledgerItemsProvider(query).future);
      } catch (_) {
        return const [];
      }
    },
    error: (_, __) => const [],
  );
}
