import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Providers/locale_provider.dart';
import 'package:solobytes/UI/DashboardTabs/ImportTab.dart';
import 'package:solobytes/UI/DashboardTabs/ProfileTab.dart';
import 'package:solobytes/UI/DashboardTabs/OverviewTab.dart';
import 'package:solobytes/domain/entities/Ledgertab.dart';
import 'package:solobytes/domain/entities/TransactionsTab.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const OverviewTab(),
    const TransactionsTab(),
    const LedgerTab(),
    const ImportTab(),
    const ProfileTab(),
  ];

  List<String> _getTitles(bool isUrdu) => [
    isUrdu ? 'جائزہ' : 'Overview',
    isUrdu ? 'لین دین' : 'Transactions',
    isUrdu ? 'کھاتہ' : 'Ledger',
    isUrdu ? 'درآمد' : 'Import',
    isUrdu ? 'پروفائل' : 'Profile',
  ];

  @override
  Widget build(BuildContext context) {
    final isUrdu = ref.watch(isUrduProvider);
    final titles = _getTitles(isUrdu);
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        surfaceTintColor: AppColors.background,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              titles[_currentIndex],
              style: AppTextStyles.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.scaffoldBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              tooltip: 'Sign Out',
              onPressed: () async {
                final authRepo = ref.read(authRepositoryProvider);
                await authRepo.signOut();
              },
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _tabs[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.divider, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textHint,
          backgroundColor: AppColors.background,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.dashboard_rounded),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.dashboard_rounded),
              ),
              label: isUrdu ? 'جائزہ' : 'Overview',
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.receipt_long_rounded),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.receipt_long_rounded),
              ),
              label: isUrdu ? 'لین دین' : 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.account_balance_wallet_outlined),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.account_balance_wallet),
              ),
              label: isUrdu ? 'کھاتہ' : 'Ledger',
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.upload_file_outlined),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.upload_file_rounded),
              ),
              label: isUrdu ? 'درآمد' : 'Import',
            ),
            BottomNavigationBarItem(
              icon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_outline_rounded),
              ),
              activeIcon: const Padding(
                padding: EdgeInsets.only(bottom: 2),
                child: Icon(Icons.person_rounded),
              ),
              label: isUrdu ? 'پروفائل' : 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
