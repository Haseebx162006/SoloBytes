import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:solobytes/Providers/transactions_provider.dart';
import 'package:solobytes/data/services/transaction_pdf_generator.dart';
import 'package:solobytes/domain/entities/transaction.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class TransactionsTab extends ConsumerWidget {
  const TransactionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // 🔹 FILTER SECTION
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.divider, width: 1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<TxType?>(
                    value: ref.watch(transactionsFilterProvider).selectedType,
                    hint: Text(
                      'All Types',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: AppTextStyles.bodyMedium,
                    dropdownColor: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Types', style: AppTextStyles.body),
                      ),
                      DropdownMenuItem(
                        value: TxType.sale,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.incomeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.arrow_downward_rounded,
                                size: 14,
                                color: AppColors.income,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Income', style: AppTextStyles.body),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: TxType.expense,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.expenseBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.arrow_upward_rounded,
                                size: 14,
                                color: AppColors.expense,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('Expense', style: AppTextStyles.body),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref
                          .read(transactionsFilterProvider.notifier)
                          .setType(value);
                    },
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.scaffoldBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.clear_rounded,
                      color: AppColors.textHint,
                      size: 20,
                    ),
                    onPressed: () {
                      ref.read(transactionsFilterProvider.notifier).clearAll();
                    },
                    tooltip: 'Clear filter',
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.primarySurface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    onPressed: () => _downloadPdf(context, ref),
                    tooltip: 'Download PDF',
                  ),
                ),
              ],
            ),
          ),

          // 🔹 TRANSACTIONS LIST
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                final normalTransactions = transactions
                    .where((tx) => tx.isNormalNature)
                    .toList(growable: false);

                if (normalTransactions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primarySurface,
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No transactions found',
                          style: AppTextStyles.heading3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tap + to add your first transaction',
                          style: AppTextStyles.caption,
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    await ref.read(transactionsProvider.notifier).refresh();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: normalTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = normalTransactions[index];
                      final isIncome = tx.isIncome;
                      final transactionTitle = _transactionTitle(tx);
                      final transactionKind = _transactionKindLabel(tx);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.divider,
                            width: 1,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isIncome
                                  ? AppColors.incomeBg
                                  : AppColors.expenseBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isIncome
                                  ? Icons.arrow_downward_rounded
                                  : Icons.arrow_upward_rounded,
                              color: isIncome
                                  ? AppColors.income
                                  : AppColors.expense,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            transactionTitle,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(
                                '${tx.date.toLocal().toString().split(' ')[0]} · $transactionKind · ${tx.category}',
                                style: AppTextStyles.caption,
                              ),
                              if (tx.personName != null &&
                                  tx.personName!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.person_outline,
                                        size: 12,
                                        color: AppColors.textHint,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tx.personName!,
                                        style: AppTextStyles.caption.copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '${isIncome ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                            style: AppTextStyles.amount.copyWith(
                              color: isIncome
                                  ? AppColors.income
                                  : AppColors.expense,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text('Error: $err', style: AppTextStyles.caption),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // 🔹 ADD BUTTON
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 3,
        onPressed: () => _showAddTransactionDialog(context, ref),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }

  // 🔹 DOWNLOAD PDF
  Future<void> _downloadPdf(BuildContext context, WidgetRef ref) async {
    final transactionsAsync = ref.read(transactionsProvider);
    final transactions = transactionsAsync.when(
      data: (data) => data,
      loading: () => <TransactionEntity>[],
      error: (_, __) => <TransactionEntity>[],
    );

    final normalTransactions = transactions
        .where((tx) => tx.isNormalNature)
        .toList(growable: false);

    if (normalTransactions.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transactions to export.')),
        );
      }
      return;
    }

    try {
      final pdfBytes = await TransactionPdfGenerator.generate(
        normalTransactions,
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: 'CashPilot_Transactions_${DateTime.now().millisecondsSinceEpoch}',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
      }
    }
  }

  String _transactionTitle(TransactionEntity tx) {
    final trimmedNote = tx.note.trim();
    if (trimmedNote.isNotEmpty) {
      return trimmedNote;
    }

    final trimmedCategory = tx.category.trim();
    if (trimmedCategory.isNotEmpty) {
      return trimmedCategory;
    }

    return tx.isIncome ? 'Income' : 'Expense';
  }

  String _transactionKindLabel(TransactionEntity tx) {
    return tx.kindLabel;
  }

  // 🔹 ADD TRANSACTION DIALOG
  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    final formKey = GlobalKey<FormState>();
    final descController = TextEditingController();
    final amountController = TextEditingController();
    final categoryController = TextEditingController();
    final personController = TextEditingController();
    TxType selectedType = TxType.sale;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          surfaceTintColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primarySurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text('Add Transaction', style: AppTextStyles.heading3),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<TxType>(
                        initialValue: selectedType,
                        decoration: InputDecoration(
                          labelText: 'Type',
                          labelStyle: AppTextStyles.label,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                        borderRadius: BorderRadius.circular(14),
                        dropdownColor: AppColors.cardBg,
                        items: const [
                          DropdownMenuItem(
                            value: TxType.sale,
                            child: Text('Income'),
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
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: descController,
                        style: AppTextStyles.body,
                        decoration: _inputDecor('Description'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: amountController,
                        style: AppTextStyles.body,
                        decoration: _inputDecor('Amount'),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Invalid number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: categoryController,
                        style: AppTextStyles.body,
                        decoration: _inputDecor('Category'),
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Required' : null,
                      ),
                      if (selectedType == TxType.expense) ...[
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: personController,
                          style: AppTextStyles.body,
                          decoration: _inputDecor(
                            'Person/Vendor Name',
                            hint: 'Who did you pay or owe?',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                elevation: 0,
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final user = FirebaseAuth.instance.currentUser;

                if (user == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User not logged in')),
                  );
                  return;
                }

                final personName = personController.text.trim();
                final newTx = TransactionEntity(
                  id: '',
                  userId: user.uid,
                  amount: double.parse(amountController.text),
                  type: selectedType,
                  nature: TransactionNature.normal,
                  category: categoryController.text,
                  date: DateTime.now(),
                  note: descController.text,
                  source: 'manual',
                  personName: personName.isEmpty ? null : personName,
                );

                Navigator.of(dialogContext).pop();

                await ref.read(transactionsProvider.notifier).add(newTx);
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  InputDecoration _inputDecor(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
      hintStyle: AppTextStyles.caption.copyWith(color: AppColors.textHint),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
