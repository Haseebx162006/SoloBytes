import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/dashboard_provider.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardSummary = ref.watch(dashboardProvider);

    return dashboardSummary.when(
      data: (summary) {
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Financial Overview (${summary.period})',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _SummaryCard(
                title: 'Net Balance',
                amount: summary.netBalance,
                color: summary.netBalance >= 0 ? Colors.green : Colors.red,
              ),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Sales',
                      amount: summary.totalSales,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Expenses',
                      amount: summary.totalExpenses,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Ledger Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Owed to Us',
                      amount: summary.totalOwedToUs,
                      subtitle: '${summary.unpaidReceivables} unpaid',
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SummaryCard(
                      title: 'We Owe',
                      amount: summary.totalWeOwe,
                      subtitle: '${summary.unpaidPayables} unpaid',
                      color: Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                child: ListTile(
                  title: const Text('Top Expense Category'),
                  subtitle: Text(
                    summary.topExpenseCategory.isEmpty
                        ? 'N/A'
                        : summary.topExpenseCategory,
                  ),
                  leading: const Icon(Icons.warning, color: Colors.amber),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text('Error: \$error')),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final String? subtitle;

  const _SummaryCard({
    Key? key,
    required this.title,
    required this.amount,
    required this.color,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
