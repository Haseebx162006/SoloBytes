import 'package:solobytes/data/repositories/dashboard_repository_impl.dart';
import 'package:solobytes/domain/entities/cash_summary.dart';

class GetSummaryUseCase {
  const GetSummaryUseCase(this._dashboardRepository);

  final DashboardRepositoryImpl _dashboardRepository;

  Future<CashSummary> execute({
    DateTime? startDate,
    DateTime? endDate,
    String period = 'all',
  }) async {
    final rawData = await _dashboardRepository.fetchDashboardRawData(
      startDate: startDate,
      endDate: endDate,
    );

    double totalSales = 0;
    double totalExpenses = 0;
    int unpaidReceivables = 0;
    int unpaidPayables = 0;
    double totalOwedToUs = 0;
    double totalWeOwe = 0;

    final Map<String, double> expenseByCategory = {};

    for (final transaction in rawData.transactions) {
      final amount = _toDouble(transaction['amount']);
      final type = (transaction['type'] ?? '').toString().toLowerCase();
      final category =
          (transaction['category'] ?? 'Uncategorized').toString().trim();

      if (type == 'income') {
        totalSales += amount;
      } else if (type == 'expense') {
        totalExpenses += amount;
        final current = expenseByCategory[category] ?? 0;
        expenseByCategory[category] = current + amount;
      }
    }

    for (final receivable in rawData.receivables) {
      final isPaid = _toBool(receivable['isPaid']);
      if (!isPaid) {
        unpaidReceivables += 1;
        totalOwedToUs += _toDouble(receivable['amount']);
      }
    }

    for (final payable in rawData.payables) {
      final isPaid = _toBool(payable['isPaid']);
      if (!isPaid) {
        unpaidPayables += 1;
        totalWeOwe += _toDouble(payable['amount']);
      }
    }

    String topExpenseCategory = 'None';
    double maxExpense = 0;

    expenseByCategory.forEach((category, total) {
      if (total > maxExpense) {
        maxExpense = total;
        topExpenseCategory = category;
      }
    });

    return CashSummary(
      totalSales: totalSales,
      totalExpenses: totalExpenses,
      netBalance: totalSales - totalExpenses,
      unpaidReceivables: unpaidReceivables,
      unpaidPayables: unpaidPayables,
      totalOwedToUs: totalOwedToUs,
      totalWeOwe: totalWeOwe,
      topExpenseCategory: topExpenseCategory,
      period: period,
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  bool _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.toLowerCase().trim();
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }

    return false;
  }
}
