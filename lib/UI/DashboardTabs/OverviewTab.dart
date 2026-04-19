import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:solobytes/Providers/dashboard_provider.dart';
import 'package:solobytes/Providers/receivables_provider.dart';
import 'package:solobytes/Providers/transactions_provider.dart';
import 'package:solobytes/Widgets/custom_card.dart';
import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/transaction.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({Key? key}) : super(key: key);

  String _formatAmount(double? value) {
    final v = value ?? 0.0;
    return '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardSummary = ref.watch(dashboardProvider);
    final transactionsAsync = ref.watch(transactionsProvider);

    return dashboardSummary.when(
      data: (summary) {
        final transactions = transactionsAsync.when(
          data: (data) => data,
          loading: () => <TransactionEntity>[],
          error: (_, __) => <TransactionEntity>[],
        );

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(transactionsProvider);
            ref.invalidate(
              ledgerItemsProvider(
                const LedgerItemsQuery(entryType: LedgerEntryType.receivable),
              ),
            );
            ref.invalidate(
              ledgerItemsProvider(
                const LedgerItemsQuery(entryType: LedgerEntryType.payable),
              ),
            );
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              _buildHeader(context, summary),
              const SizedBox(height: 24),

              _buildNetBalanceCard(context, summary),
              const SizedBox(height: 20),

              _buildQuickMetrics(context, summary),
              const SizedBox(height: 16),

              _buildLedgerMetrics(context, summary),
              const SizedBox(height: 24),

              if (summary.totalSales > 0 || summary.totalExpenses > 0) ...[
                _buildAnalyticsSection(context, summary),
                const SizedBox(height: 24),
              ],

              _buildRecentTransactions(context, transactions),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 40),
            const SizedBox(height: 12),
            Text(
              'Something went wrong',
              style: AppTextStyles.heading3.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 4),
            Text('$error', style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }

  // ================= HEADER =================
  Widget _buildHeader(BuildContext context, summary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: AppTextStyles.heading1),
            const SizedBox(height: 4),
            Text(
              'Financial summary (${summary.period})',
              style: AppTextStyles.caption,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primarySurface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: AppColors.primary,
            size: 22,
          ),
        ),
      ],
    );
  }

  // ================= NET BALANCE =================
  Widget _buildNetBalanceCard(BuildContext context, summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Net Balance',
                style: AppTextStyles.subtitle.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatAmount(summary.netBalance),
            style: AppTextStyles.amountLarge.copyWith(fontSize: 36),
          ),
        ],
      ),
    );
  }

  // ================= QUICK METRICS =================
  Widget _buildQuickMetrics(BuildContext context, summary) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Income',
            amount: summary.totalSales ?? 0,
            icon: Icons.arrow_downward_rounded,
            color: AppColors.income,
            bgColor: AppColors.incomeBg,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Expenses',
            amount: summary.totalExpenses ?? 0,
            icon: Icons.arrow_upward_rounded,
            color: AppColors.expense,
            bgColor: AppColors.expenseBg,
          ),
        ),
      ],
    );
  }

  // ================= LEDGER =================
  Widget _buildLedgerMetrics(BuildContext context, summary) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Owed to Us',
            amount: summary.totalOwedToUs ?? 0,
            subtitle: '${summary.unpaidReceivables ?? 0} unpaid',
            icon: Icons.call_received_rounded,
            color: AppColors.teal,
            bgColor: AppColors.tealBg,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'We Owe',
            amount: summary.totalWeOwe ?? 0,
            subtitle: '${summary.unpaidPayables ?? 0} unpaid',
            icon: Icons.call_made_rounded,
            color: AppColors.orange,
            bgColor: AppColors.orangeBg,
          ),
        ),
      ],
    );
  }

  // ================= ANALYTICS =================
  Widget _buildAnalyticsSection(BuildContext context, summary) {
    final double sales = summary.totalSales ?? 0.0;
    final double expenses = summary.totalExpenses ?? 0.0;
    final double total = sales + expenses;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.pie_chart_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Money Flow', style: AppTextStyles.heading3),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 170,
            child: Row(
              children: [
                Expanded(
                  flex: 1,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 45,
                      sectionsSpace: 3,
                      sections: [
                        if (sales > 0)
                          PieChartSectionData(
                            value: sales,
                            title: total > 0
                                ? '${(sales / total * 100).toStringAsFixed(1)}%'
                                : '',
                            titleStyle: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            color: AppColors.income,
                            radius: 38,
                          ),
                        if (expenses > 0)
                          PieChartSectionData(
                            value: expenses,
                            title: total > 0
                                ? '${(expenses / total * 100).toStringAsFixed(1)}%'
                                : '',
                            titleStyle: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            color: AppColors.expense,
                            radius: 38,
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegendItem('Income', AppColors.income, sales),
                      const SizedBox(height: 16),
                      _buildLegendItem('Expense', AppColors.expense, expenses),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String title, Color color, double amount) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 12,
          height: 12,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                _formatAmount(amount),
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= RECENT TRANSACTIONS =================
  Widget _buildRecentTransactions(
    BuildContext context,
    List<TransactionEntity> transactions,
  ) {
    if (transactions.isEmpty) return const SizedBox.shrink();

    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    final recent = sorted.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Recent Transactions', style: AppTextStyles.heading3),
          ],
        ),
        const SizedBox(height: 16),

        CustomCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 56, color: AppColors.divider),
            itemBuilder: (context, index) {
              final tx = recent[index];
              final isIncome = tx.type == TxType.sale;

              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isIncome ? AppColors.incomeBg : AppColors.expenseBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward_rounded
                        : Icons.arrow_upward_rounded,
                    color: isIncome ? AppColors.income : AppColors.expense,
                    size: 18,
                  ),
                ),
                title: Text(
                  tx.note.isNotEmpty ? tx.note : tx.category,
                  style: AppTextStyles.bodyMedium,
                ),
                subtitle: Text(tx.category, style: AppTextStyles.caption),
                trailing: Text(
                  _formatAmount(tx.amount),
                  style: AppTextStyles.amount.copyWith(
                    color: isIncome ? AppColors.income : AppColors.expense,
                    fontSize: 15,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ================= STAT CARD =================
class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.title,
    required this.amount,
    this.subtitle,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  String _format(double value) {
    return '\$${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(title, style: AppTextStyles.caption),
          const SizedBox(height: 4),
          Text(_format(amount), style: AppTextStyles.amount),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTextStyles.caption),
          ],
        ],
      ),
    );
  }
}
