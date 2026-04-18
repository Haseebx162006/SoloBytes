import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/Providers/transactions_provider.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class TransactionsTab extends ConsumerWidget {
  const TransactionsTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TxType>(
                    value: ref.watch(transactionsFilterProvider).selectedType,
                    hint: const Text('All Types'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: null, child: Text('All Types')),
                      DropdownMenuItem(value: TxType.sale, child: Text('Sale')),
                      DropdownMenuItem(
                        value: TxType.expense,
                        child: Text('Expense'),
                      ),
                    ],
                    onChanged: (value) {
                      ref
                          .read(transactionsFilterProvider.notifier)
                          .setType(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    ref.read(transactionsFilterProvider.notifier).clearAll();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(child: Text('No transactions found.'));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(transactionsProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isSale = tx.type == TxType.sale;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isSale
                              ? Colors.green[100]
                              : Colors.red[100],
                          child: Icon(
                            isSale ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isSale ? Colors.green : Colors.red,
                          ),
                        ),
                        title: Text(tx.description),
                        subtitle: Text(
                          '${tx.date.toLocal().toString().split(' ')[0]} - ${tx.category}',
                        ),
                        trailing: Text(
                          '${isSale ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isSale ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: \$err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    TxType selectedType = TxType.sale;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Transaction'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<TxType>(
                        value: selectedType,
                        items: const [
                          DropdownMenuItem(
                            value: TxType.sale,
                            child: Text('Sale'),
                          ),
                          DropdownMenuItem(
                            value: TxType.expense,
                            child: Text('Expense'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            if (value != null) selectedType = value;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Type'),
                      ),
                      TextFormField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
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
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newTx = TransactionEntity(
                    id: DateTime.now().toIso8601String(),
                    userId:
                        '', // Provider will fill user id internally based on logic or add case needs it. Wait, let's check add function.
                    amount: double.parse(amountController.text),
                    type: selectedType,
                    category: categoryController.text,
                    date: DateTime.now(),
                    description: descController.text,
                  );
                  Navigator.of(context).pop();
                  await ref.read(transactionsProvider.notifier).add(newTx);
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
