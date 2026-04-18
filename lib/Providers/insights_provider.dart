import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/application/usecases/get_insights_usecase.dart';
import 'package:solobytes/data/repositories/insights_repository_impl.dart';
import 'package:solobytes/data/services/ai_service.dart';
import 'package:solobytes/domain/entities/cash_summary.dart';

import 'package:solobytes/Providers/transactions_provider.dart';
import 'package:solobytes/domain/entities/transaction.dart';

import 'package:solobytes/Providers/receivables_provider.dart';
import 'package:solobytes/domain/entities/receivable.dart';

/// -----------------------------
/// CASH SUMMARY PROVIDER (REAL IMPLEMENTATION)
/// -----------------------------
final cashSummaryProvider = FutureProvider<CashSummary>((ref) async {
  final uid = ref.watch(authUserProvider)?.uid;

  if (uid == null || uid.isEmpty) {
    throw Exception("User not logged in");
  }

  final transactionsAsync = ref.watch(transactionsProvider);
  final receivablesValues = ref.watch(receivablesProvider);
  final payablesValues = ref.watch(payablesProvider);

  if (transactionsAsync is AsyncLoading ||
      receivablesValues is AsyncLoading ||
      payablesValues is AsyncLoading) {
    return const CashSummary(
      netBalance: 0.0,
      totalSales: 0.0,
      totalExpenses: 0.0,
      unpaidReceivables: 0,
      unpaidPayables: 0,
      topExpenseCategory: 'None',
      totalOwedToUs: 0.0,
      totalWeOwe: 0.0,
      period: 'All Time',
    );
  }

  if (transactionsAsync is AsyncError ||
      receivablesValues is AsyncError ||
      payablesValues is AsyncError) {
    return const CashSummary(
      netBalance: 0.0,
      totalSales: 0.0,
      totalExpenses: 0.0,
      unpaidReceivables: 0,
      unpaidPayables: 0,
      topExpenseCategory: 'None',
      totalOwedToUs: 0.0,
      totalWeOwe: 0.0,
      period: 'All Time',
    );
  }

  final transactions = transactionsAsync.value ?? [];
  final receivables = receivablesValues.value ?? [];
  final payables = payablesValues.value ?? [];

  double totalSales = 0;
  double totalExpenses = 0;

  final Map<String, double> expenseCategoryMap = {};

  for (final tx in transactions) {
    final amount = tx.amount.abs();
    if (tx.type == TxType.expense) {
      totalExpenses += amount;
      expenseCategoryMap[tx.category] =
          (expenseCategoryMap[tx.category] ?? 0) + amount;
    } else {
      totalSales += amount;
    }
  }

  int unpaidReceivablesCount = 0;
  double totalOwedToUs = 0.0;
  for (final item in receivables) {
    if (item.status == PaymentStatus.unpaid || item.status == PaymentStatus.overdue) {
      unpaidReceivablesCount++;
      totalOwedToUs += item.amount;
    }
  }

  int unpaidPayablesCount = 0;
  double totalWeOwe = 0.0;
  for (final item in payables) {
    if (item.status == PaymentStatus.unpaid || item.status == PaymentStatus.overdue) {
      unpaidPayablesCount++;
      totalWeOwe += item.amount;
    }
  }

  // Include ledger data in Net Balance calculation: 
  // (Total Sales - Total Expenses) + Owed to Us - What We Owe
  final netBalance = (totalSales - totalExpenses) + totalOwedToUs - totalWeOwe;

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
    unpaidReceivables: unpaidReceivablesCount,
    unpaidPayables: unpaidPayablesCount,
    topExpenseCategory: topCategory.isNotEmpty ? topCategory : 'None',
    totalOwedToUs: totalOwedToUs,
    totalWeOwe: totalWeOwe,
    period: 'All Time',
  );
});

/// -----------------------------
/// AI SERVICE PROVIDER
/// -----------------------------
final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

/// -----------------------------
/// FIRESTORE PROVIDER
/// -----------------------------
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// -----------------------------
/// REPOSITORY PROVIDER
/// -----------------------------
final insightsRepositoryProvider = Provider<InsightsRepositoryImpl>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return InsightsRepositoryImpl(firestore: firestore);
});

/// -----------------------------
/// USE CASE PROVIDER
/// -----------------------------
final getInsightsUseCaseProvider = Provider<GetInsightsUseCase>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  final repository = ref.watch(insightsRepositoryProvider);

  return GetInsightsUseCase(aiService, repository);
});

class InsightsNotifier extends AsyncNotifier<String> {
  @override
  Future<String> build() async {
    return _fetchInsights();
  }

  Future<String> _fetchInsights() async {
    final user = ref.read(authUserProvider);

    if (user == null || user.uid.isEmpty) {
      return AiService.fallbackMessage;
    }

    try {
      final summary = await ref.read(cashSummaryProvider.future);

      final useCase = ref.read(getInsightsUseCaseProvider);

      final result = await useCase.execute(uid: user.uid, summary: summary);

      return result;
    } catch (e) {
      return "Unable to generate insights right now. Please try again later.";
    }
  }

  Future<void> refreshInsights() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() => _fetchInsights());
  }
}

final insightsProvider = AsyncNotifierProvider<InsightsNotifier, String>(
  InsightsNotifier.new,
);
