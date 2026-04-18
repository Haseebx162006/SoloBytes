import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:solobytes/Providers/dashboard_provider.dart';
import 'package:solobytes/Providers/transactions_provider.dart';
import 'package:solobytes/domain/entities/transaction.dart';

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
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
            ref.invalidate(transactionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            children: [
              _buildHeader(context, summary),
              const SizedBox(height: 24),

              _buildNetBalanceCard(context, summary),
              const SizedBox(height: 16),

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
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: $error')),
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
            Text(
              'Overview',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Financial summary (${summary.period})',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        Icon(Icons.analytics, color: Theme.of(context).primaryColor),
      ],
    );
  }

  // ================= NET BALANCE =================
  Widget _buildNetBalanceCard(BuildContext context, summary) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColorDark,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Net Balance', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Text(
            _formatAmount(summary.netBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
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
            icon: Icons.arrow_downward,
            color: Colors.green,
            bgColor: Colors.green.shade50,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'Expenses',
            amount: summary.totalExpenses ?? 0,
            icon: Icons.arrow_upward,
            color: Colors.red,
            bgColor: Colors.red.shade50,
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
            icon: Icons.call_received,
            color: Colors.teal,
            bgColor: Colors.teal.shade50,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            title: 'We Owe',
            amount: summary.totalWeOwe ?? 0,
            subtitle: '${summary.unpaidPayables ?? 0} unpaid',
            icon: Icons.call_made,
            color: Colors.orange,
            bgColor: Colors.orange.shade50,
          ),
        ),
      ],
    );
  }

  // ================= ANALYTICS =================
  Widget _buildAnalyticsSection(BuildContext context, summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Money Flow',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          SizedBox(
            height: 160,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sections: [
                  if ((summary.totalSales ?? 0) > 0)
                    PieChartSectionData(
                      value: summary.totalSales ?? 0,
                      title: 'Income',
                      color: Colors.green,
                      radius: 35,
                    ),
                  if ((summary.totalExpenses ?? 0) > 0)
                    PieChartSectionData(
                      value: summary.totalExpenses ?? 0,
                      title: 'Expense',
                      color: Colors.red,
                      radius: 35,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        const Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recent.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final tx = recent[index];
              final isIncome = tx.type == TxType.sale;

              return ListTile(
                leading: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
                title: Text(tx.note.isNotEmpty ? tx.note : tx.category),
                subtitle: Text(tx.category),
                trailing: Text(
                  _formatAmount(tx.amount),
                  style: TextStyle(
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(title),
          const SizedBox(height: 6),
          Text(
            _format(amount),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (subtitle != null)
            Text(subtitle!, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
