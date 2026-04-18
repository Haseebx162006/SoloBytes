import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Providers/person_accounts_provider.dart';
import 'package:solobytes/Providers/receivables_provider.dart';
import 'package:solobytes/domain/entities/receivable.dart';

class LedgerTab extends ConsumerStatefulWidget {
  const LedgerTab({super.key});

  @override
  ConsumerState<LedgerTab> createState() => _LedgerTabState();
}

class _LedgerTabState extends ConsumerState<LedgerTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ledger'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Receivables'),
            Tab(text: 'Payables'),
            Tab(text: 'Person Accounts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LedgerListView(
            provider: receivablesProvider,
            entryType: LedgerEntryType.receivable,
          ),
          _LedgerListView(
            provider: payablesProvider,
            entryType: LedgerEntryType.payable,
          ),
          const _PersonAccountsView(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_tabController.index < 2) {
            _showAddLedgerDialog(
              context,
              ref,
              _tabController.index == 0
                  ? LedgerEntryType.receivable
                  : LedgerEntryType.payable,
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLedgerDialog(
    BuildContext context,
    WidgetRef ref,
    LedgerEntryType type,
  ) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final partyController = TextEditingController();
    DateTime? selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (dialogContext) {                        // FIX 4: named dialogContext
        return AlertDialog(
          title: Text(
            type == LedgerEntryType.receivable
                ? 'Add Receivable'
                : 'Add Payable',
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: partyController,
                        decoration: InputDecoration(
                          labelText: type == LedgerEntryType.receivable
                              ? 'Customer Name'
                              : 'Vendor Name',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: amountController,
                        decoration: const InputDecoration(labelText: 'Amount'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Due Date'),
                        subtitle: Text(
                          selectedDate!.toLocal().toString().split(' ')[0],
                        ),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate!,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 3650),
                            ),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final user = ref.read(authUserProvider);  // FIX 2: correct provider name (ensure import above matches your actual provider file)
                if (user == null) return;

                final useCase = ref.read(trackReceivableUseCaseProvider);

                // FIX 3: match your use case's actual execute() signature.
                // Option A — if execute() takes named params:
                await useCase.execute(
                  entryType: type,
                  userId: user.uid,
                  name: partyController.text,
                  amount: double.parse(amountController.text),
                  dueDate: selectedDate!,
                );

                // FIX 4: guard with mounted before using context after await
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class _LedgerListView extends ConsumerWidget {
  final Provider<AsyncValue<List<ReceivableEntity>>> provider;
  final LedgerEntryType entryType;

  const _LedgerListView({
    super.key,
    required this.provider,
    required this.entryType,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(provider);

    return listAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(child: Text('No entries found.'));
        }
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isPaid = item.isPaid;
            return ListTile(
              leading: Icon(
                entryType == LedgerEntryType.receivable
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: entryType == LedgerEntryType.receivable
                    ? Colors.green
                    : Colors.red,
              ),
              title: Text(item.partyName),
              subtitle: Text(
                'Due: ${item.dueDate.toLocal().toString().split(' ')[0]}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${item.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    item.status.name.toUpperCase(),
                    style: TextStyle(
                      color: isPaid
                          ? Colors.green
                          : item.isOverdue
                              ? Colors.red
                              : Colors.orange,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              onTap: isPaid
                  ? null
                  : () => _showMarkPaidDialog(context, ref, item),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  void _showMarkPaidDialog(
    BuildContext context,
    WidgetRef ref,
    ReceivableEntity item,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {                        // FIX 4: named dialogContext
        return AlertDialog(
          title: const Text('Mark as Paid'),
          content: Text(
            'Are you sure you want to mark ${item.partyName}\'s entry of '
            '\$${item.amount.toStringAsFixed(2)} as paid? '
            'This will also add a transaction.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                
                final user = ref.read(authUserProvider);
                if (user == null) return;
                
                final useCase = ref.read(markPaidUseCaseProvider);
                await useCase.execute(
                  entryType: entryType,
                  itemId: item.id,
                  userId: user.uid,
                  item: item,
                );
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }
}


class _PersonAccountsView extends ConsumerWidget {
  const _PersonAccountsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(personAccountsProvider);

    return accountsAsync.when(
      data: (accounts) {
        if (accounts.isEmpty) {
          return const Center(
            child: Text('No person accounts found.'),
          );
        }

        return ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            final absBalance = account.balance.abs();
            final isPositive = account.balance > 0;
            final isZero = account.balance == 0;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: isZero
                    ? Colors.grey[300]
                    : isPositive
                        ? Colors.green[100]
                        : Colors.red[100],
                child: Icon(
                  isZero
                      ? Icons.check_circle
                      : isPositive
                          ? Icons.arrow_downward
                          : Icons.arrow_upward,
                  color: isZero
                      ? Colors.grey
                      : isPositive
                          ? Colors.green
                          : Colors.red,
                ),
              ),
              title: Text(account.name),
              subtitle: Text(
                '${account.transactionCount} transaction${account.transactionCount != 1 ? 's' : ''}\n'
                'Last: ${account.lastTransactionDate.toLocal().toString().split(' ')[0]}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${absBalance.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isZero
                          ? Colors.grey
                          : isPositive
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                  Text(
                    isZero
                        ? 'SETTLED'
                        : isPositive
                            ? 'OWES US'
                            : 'WE OWE',
                    style: TextStyle(
                      fontSize: 10,
                      color: isZero
                          ? Colors.grey
                          : isPositive
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
