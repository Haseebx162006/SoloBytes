import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:solobytes/Providers/auth_provider.dart';
import 'package:solobytes/Providers/dashboard_provider.dart';
import 'package:solobytes/Providers/import_provider.dart';
import 'package:solobytes/Providers/transactions_provider.dart';
import 'package:solobytes/Widgets/custom_card.dart';
import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/transaction.dart';
import 'package:solobytes/theme/app_colors.dart';
import 'package:solobytes/theme/app_text_styles.dart';

class ImportTab extends ConsumerStatefulWidget {
  const ImportTab({Key? key}) : super(key: key);

  @override
  ConsumerState<ImportTab> createState() => _ImportTabState();
}

class _ImportTabState extends ConsumerState<ImportTab> {
  Uint8List? _fileBytes;
  String? _fileName;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _fileBytes = result.files.single.bytes;
        _fileName = result.files.single.name;
      });

      ref
          .read(importProvider.notifier)
          .parseFile(fileName: _fileName!, fileBytes: _fileBytes!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(importProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Header ───────────────────────────────────────
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.upload_file_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Import from Excel', style: AppTextStyles.heading3),
                Text(
                  'Upload your financial data',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Supported Columns Info ───────────────────────
        CustomCard(
          color: AppColors.primarySurface.withAlpha(100),
          hasBorder: false,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Supported columns (all optional)',
                    style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _ColumnChip(label: 'date'),
                  _ColumnChip(label: 'expense'),
                  _ColumnChip(label: 'sale'),
                  _ColumnChip(label: 'category'),
                  _ColumnChip(label: 'note'),
                  _ColumnChip(label: 'productname'),
                  _ColumnChip(label: 'payable'),
                  _ColumnChip(label: 'receivable'),
                  _ColumnChip(label: 'personname'),
                  _ColumnChip(label: 'duedate'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Upload Area ──────────────────────────────────
        GestureDetector(
          onTap: importState.isLoading ? null : _pickFile,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.primarySurface.withAlpha(120),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withAlpha(60),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Tap to select a file',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Supports .xlsx and .xls files',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // ── States ───────────────────────────────────────
        if (importState.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                children: [
                  SizedBox(
                    height: 36,
                    width: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text('Processing file...', style: AppTextStyles.subtitle),
                ],
              ),
            ),
          )
        else if (importState.errorMessage != null)
          CustomCard(
            color: AppColors.expenseBg,
            hasBorder: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    importState.errorMessage!,
                    style: AppTextStyles.body.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          )
        else if (importState.isImportCompleted)
          CustomCard(
            color: AppColors.incomeBg,
            hasBorder: false,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.income.withAlpha(25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.income,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Import completed successfully!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.income,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (importState.previewResult != null) ...[
          // ── Preview Section ────────────────────────────
          CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _fileName ?? 'File',
                        style: AppTextStyles.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 16),

                _PreviewRow(
                  label: 'Valid Schema',
                  value: importState.previewResult!.isSchemaValid
                      ? 'Yes'
                      : 'No',
                  valueColor: importState.previewResult!.isSchemaValid
                      ? AppColors.income
                      : AppColors.error,
                ),
                const SizedBox(height: 10),

                // ── Breakdown by type ────────────────────
                Builder(builder: (context) {
                  final preview = importState.previewResult!;
                  final salesCount = preview.transactions
                      .where((t) => t.type == TxType.sale)
                      .length;
                  final expenseCount = preview.transactions
                      .where((t) => t.type == TxType.expense)
                      .length;
                  final receivableCount = preview.receivables
                      .where((r) => r.entryType == LedgerEntryType.receivable)
                      .length;
                  final payableCount = preview.receivables
                      .where((r) => r.entryType == LedgerEntryType.payable)
                      .length;

                  return Column(
                    children: [
                      if (salesCount > 0) ...[
                        const SizedBox(height: 10),
                        _PreviewRow(
                          label: 'Sales / Income',
                          value: '$salesCount',
                          icon: Icons.arrow_downward_rounded,
                          iconColor: AppColors.income,
                        ),
                      ],
                      if (expenseCount > 0) ...[
                        const SizedBox(height: 10),
                        _PreviewRow(
                          label: 'Expenses',
                          value: '$expenseCount',
                          icon: Icons.arrow_upward_rounded,
                          iconColor: AppColors.expense,
                        ),
                      ],
                      if (receivableCount > 0) ...[
                        const SizedBox(height: 10),
                        _PreviewRow(
                          label: 'Receivables',
                          value: '$receivableCount',
                          icon: Icons.call_received_rounded,
                          iconColor: AppColors.teal,
                        ),
                      ],
                      if (payableCount > 0) ...[
                        const SizedBox(height: 10),
                        _PreviewRow(
                          label: 'Payables',
                          value: '$payableCount',
                          icon: Icons.call_made_rounded,
                          iconColor: AppColors.orange,
                        ),
                      ],
                      if (preview.errors.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _PreviewRow(
                          label: 'Skipped rows',
                          value: '${preview.errors.length}',
                          valueColor: AppColors.error,
                        ),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (importState.previewResult!.isSchemaValid &&
              importState.previewResult!.hasData &&
              _fileBytes != null)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_rounded, size: 20),
                label: Text('Confirm Import', style: AppTextStyles.button),
                onPressed: () async {
                  final user = ref.read(authUserProvider);
                  if (user != null) {
                    final success = await ref
                        .read(importProvider.notifier)
                        .confirmImport(
                          userId: user.uid,
                          originalFileBytes: _fileBytes!,
                        );

                    if (success) {
                      // Refresh dashboard & transactions so data shows immediately
                      ref.invalidate(transactionsProvider);
                      ref.invalidate(dashboardProvider);
                    }
                  }
                },
              ),
            ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Select an Excel file to see a preview',
                style: AppTextStyles.subtitle,
              ),
            ),
          ),
      ],
    );
  }
}

class _ColumnChip extends StatelessWidget {
  final String label;
  const _ColumnChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.primary.withAlpha(40)),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontFamily: 'monospace',
          fontSize: 11,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final IconData? icon;
  final Color? iconColor;

  const _PreviewRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: iconColor ?? AppColors.textSecondary),
              const SizedBox(width: 6),
            ],
            Text(label, style: AppTextStyles.caption),
          ],
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
