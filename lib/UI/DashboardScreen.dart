import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/dashboard_provider.dart';
import 'package:solobytes/domain/entities/cash_summary.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff3f3f3),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff0d631b),
        foregroundColor: Colors.white,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: _BottomNavBar(),
      body: SafeArea(
        child: summaryState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DashboardError(
            message: error.toString().replaceFirst('Exception: ', '').trim(),
            onRetry: () => ref.invalidate(dashboardProvider),
          ),
          data: (summary) => _DashboardContent(summary: summary),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(),
              const SizedBox(height: 24),
              const Text(
                'Cash Dashboard',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 48,
                  fontWeight: FontWeight.w700,
                  color: Color(0xff111414),
                  height: 1,
                ),
              ),
              const SizedBox(height: 22),
              _BalanceCard(summary: summary),
              const SizedBox(height: 18),
              if (isWide)
                Row(
                  children: [
                    Expanded(child: _SalesCard(summary: summary)),
                    const SizedBox(width: 12),
                    Expanded(child: _ExpensesCard(summary: summary)),
                    const SizedBox(width: 12),
                    Expanded(child: _ReceivablesCard(summary: summary)),
                    const SizedBox(width: 12),
                    Expanded(child: _PayablesCard(summary: summary)),
                  ],
                )
              else
                Column(
                  children: [
                    _SalesCard(summary: summary),
                    const SizedBox(height: 12),
                    _ExpensesCard(summary: summary),
                    const SizedBox(height: 12),
                    _ReceivablesCard(summary: summary),
                    const SizedBox(height: 12),
                    _PayablesCard(summary: summary),
                  ],
                ),
              const SizedBox(height: 18),
              _InsightCard(summary: summary),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: const [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xffe2e2e2),
              child: Icon(Icons.person, color: Color(0xff202524)),
            ),
            SizedBox(width: 12),
            Text(
              'The Fiscal Atelier',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xff0d631b),
              ),
            ),
          ],
        ),
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xfff9f9f9),
          ),
          child: const Icon(Icons.notifications, color: Color(0xff0d631b)),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    final amount = _formatCurrency(summary.netBalance);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xff0d631b), Color(0xff2e7d32)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL CASH BALANCE',
            style: TextStyle(
              color: Color(0xffcbffc2),
              fontFamily: 'Poppins',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontFamily: 'Poppins',
              fontSize: 46,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: const Color(0xff88d982),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.trending_up,
                      size: 15,
                      color: Color(0xff0b4b14),
                    ),
                    SizedBox(width: 5),
                    Text(
                      '+12.4%',
                      style: TextStyle(
                        color: Color(0xff0b4b14),
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'vs last month',
                style: TextStyle(
                  color: Color(0xffcbffc2),
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.amount,
    required this.trailing,
    required this.footer,
  });

  final String title;
  final String amount;
  final IconData trailing;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xfff9f9f9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x1f707a6c)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff40493d),
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              Icon(trailing, color: const Color(0xff98a396), size: 18),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            amount,
            style: const TextStyle(
              color: Color(0xff111414),
              fontFamily: 'Poppins',
              fontSize: 46,
              fontWeight: FontWeight.w700,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          const SizedBox(height: 14),
          footer,
        ],
      ),
    );
  }
}

class _SalesCard extends StatelessWidget {
  const _SalesCard({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      title: 'TOTAL SALES',
      amount: _formatCurrency(summary.totalSales),
      trailing: Icons.point_of_sale,
      footer: const Row(
        children: [
          Icon(Icons.arrow_upward, color: Color(0xff0d631b), size: 16),
          SizedBox(width: 6),
          Text(
            '8%',
            style: TextStyle(
              color: Color(0xff0d631b),
              fontFamily: 'Poppins',
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesCard extends StatelessWidget {
  const _ExpensesCard({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      title: 'TOTAL EXPENSES',
      amount: _formatCurrency(summary.totalExpenses),
      trailing: Icons.credit_card,
      footer: const Row(
        children: [
          Icon(Icons.arrow_downward, color: Color(0xffba1a1a), size: 16),
          SizedBox(width: 6),
          Text(
            '2%',
            style: TextStyle(
              color: Color(0xffba1a1a),
              fontFamily: 'Poppins',
              fontSize: 25,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceivablesCard extends StatelessWidget {
  const _ReceivablesCard({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      title: 'RECEIVABLES',
      amount: _formatCurrency(summary.totalOwedToUs),
      trailing: Icons.arrow_forward,
      footer: const Text(
        'Due next 30 days',
        style: TextStyle(
          color: Color(0xff616b60),
          fontFamily: 'Poppins',
          fontSize: 25,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PayablesCard extends StatelessWidget {
  const _PayablesCard({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    return _MetricCard(
      title: 'PAYABLES',
      amount: _formatCurrency(summary.totalWeOwe),
      trailing: Icons.arrow_back,
      footer: const Text(
        'Due next 30 days',
        style: TextStyle(
          color: Color(0xff616b60),
          fontFamily: 'Poppins',
          fontSize: 25,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.summary});

  final CashSummary summary;

  @override
  Widget build(BuildContext context) {
    final category = summary.topExpenseCategory.trim().isEmpty
        ? 'operational costs'
        : summary.topExpenseCategory;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xfff9f9f9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x33707a6c)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xffb5e7fe),
            ),
            child: const Icon(Icons.lightbulb, color: Color(0xff326578)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Cash Flow Insight',
                  style: TextStyle(
                    color: Color(0xff111414),
                    fontFamily: 'Poppins',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your receivables are trending higher this month. '
                  'Top expense category is $category. '
                  'Consider sending automated reminders to improve immediate liquidity.',
                  style: const TextStyle(
                    color: Color(0xff40493d),
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xffba1a1a), size: 40),
            const SizedBox(height: 12),
            Text(
              message.isEmpty ? 'Unable to load dashboard.' : message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                color: Color(0xff111414),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff0d631b),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xF2FFFFFF),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          children: const [
            _BottomTab(
              icon: Icons.dashboard,
              label: 'DASHBOARD',
              selected: true,
            ),
            SizedBox(width: 8),
            _BottomTab(
              icon: Icons.receipt_long,
              label: 'TRANSACTIONS',
              selected: false,
            ),
            SizedBox(width: 8),
            _BottomTab(
              icon: Icons.lightbulb,
              label: 'INSIGHTS',
              selected: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomTab extends StatelessWidget {
  const _BottomTab({
    required this.icon,
    required this.label,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 82,
        decoration: BoxDecoration(
          color: selected ? const Color(0xff0d631b) : const Color(0x00000000),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? Colors.white : const Color(0xff9aa2b1),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xff9aa2b1),
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
  final isNegative = value < 0;
  final absolute = value.abs();
  final fixed = absolute.toStringAsFixed(0);
  final withCommas = fixed.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  final prefix = isNegative ? '-\$' : '\$';
  return '$prefix$withCommas';
}
