import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:solobytes/domain/entities/transaction.dart';

class TransactionPdfGenerator {
  const TransactionPdfGenerator._();

  static Future<Uint8List> generate(List<TransactionEntity> transactions) async {
    final pdf = pw.Document();

    // Sort by date descending
    final sorted = [...transactions]..sort((a, b) => b.date.compareTo(a.date));

    // Calculate totals
    double totalIncome = 0;
    double totalExpense = 0;
    for (final tx in sorted) {
      if (tx.type == TxType.sale) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    final netBalance = totalIncome - totalExpense;

    // Colors
    final primaryColor = PdfColor.fromHex('#2E7D32');
    final primaryLight = PdfColor.fromHex('#E8F5E9');
    final incomeColor = PdfColor.fromHex('#16A34A');
    final expenseColor = PdfColor.fromHex('#DC2626');
    final headerBg = PdfColor.fromHex('#F1F5F0');
    final dividerColor = PdfColor.fromHex('#E5E7EB');
    final textPrimary = PdfColor.fromHex('#1A1A1A');
    final textSecondary = PdfColor.fromHex('#6B7280');

    // Styles
    final titleStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
      color: primaryColor,
    );
    final subtitleStyle = pw.TextStyle(
      fontSize: 10,
      color: textSecondary,
    );
    final headingStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: textPrimary,
    );
    final bodyStyle = pw.TextStyle(
      fontSize: 9,
      color: textPrimary,
    );
    final bodySecondary = pw.TextStyle(
      fontSize: 9,
      color: textSecondary,
    );
    final amountBold = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
    );

    // Date formatting helper
    String formatDate(DateTime d) {
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    String formatAmount(double v) {
      return '\$${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2)}';
    }

    // Build pages — chunk transactions for multi-page support
    const int rowsPerPage = 28;
    final totalPages = (sorted.length / rowsPerPage).ceil().clamp(1, 999);

    for (var page = 0; page < totalPages; page++) {
      final startIdx = page * rowsPerPage;
      final endIdx = (startIdx + rowsPerPage).clamp(0, sorted.length);
      final pageTransactions = sorted.sublist(startIdx, endIdx);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // ── HEADER (first page only) ─────────────
                if (page == 0) ...[
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CashPilot', style: titleStyle),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Transaction History Report',
                            style: subtitleStyle.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'Generated: ${formatDate(DateTime.now())}',
                            style: subtitleStyle,
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${sorted.length} transactions',
                            style: subtitleStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 16),

                  // ── SUMMARY CARDS ──────────────────────
                  pw.Row(
                    children: [
                      _summaryBox(
                        'Total Income',
                        formatAmount(totalIncome),
                        incomeColor,
                        primaryLight,
                        amountBold,
                        bodySecondary,
                      ),
                      pw.SizedBox(width: 12),
                      _summaryBox(
                        'Total Expenses',
                        formatAmount(totalExpense),
                        expenseColor,
                        PdfColor.fromHex('#FEF2F2'),
                        amountBold,
                        bodySecondary,
                      ),
                      pw.SizedBox(width: 12),
                      _summaryBox(
                        'Net Balance',
                        formatAmount(netBalance),
                        netBalance >= 0 ? incomeColor : expenseColor,
                        headerBg,
                        amountBold,
                        bodySecondary,
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 20),
                  pw.Divider(color: dividerColor, thickness: 1),
                  pw.SizedBox(height: 12),
                ],

                // ── TABLE HEADER ─────────────────────────
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: pw.BoxDecoration(
                    color: headerBg,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('Date', style: headingStyle),
                      ),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text('Type', style: headingStyle),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text('Category', style: headingStyle),
                      ),
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text('Note', style: headingStyle),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          'Amount',
                          style: headingStyle,
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),

                // ── TABLE ROWS ───────────────────────────
                ...pageTransactions.asMap().entries.map((entry) {
                  final tx = entry.value;
                  final isSale = tx.type == TxType.sale;
                  final rowBg = entry.key.isEven
                      ? PdfColors.white
                      : PdfColor.fromHex('#FAFAFA');

                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: pw.BoxDecoration(
                      color: rowBg,
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: dividerColor,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            formatDate(tx.date),
                            style: bodyStyle,
                          ),
                        ),
                        pw.Expanded(
                          flex: 1,
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: pw.BoxDecoration(
                              color: isSale ? primaryLight : PdfColor.fromHex('#FEF2F2'),
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              isSale ? 'Sale' : 'Expense',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: isSale ? incomeColor : expenseColor,
                              ),
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 4),
                            child: pw.Text(tx.category, style: bodyStyle),
                          ),
                        ),
                        pw.Expanded(
                          flex: 3,
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 4),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  tx.note.isNotEmpty ? tx.note : '—',
                                  style: bodyStyle,
                                  maxLines: 1,
                                ),
                                if (tx.personName != null &&
                                    tx.personName!.isNotEmpty)
                                  pw.Text(
                                    tx.personName!,
                                    style: bodySecondary.copyWith(
                                      fontStyle: pw.FontStyle.italic,
                                      fontSize: 8,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '${isSale ? '+' : '-'}${formatAmount(tx.amount)}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: isSale ? incomeColor : expenseColor,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                pw.Spacer(),

                // ── FOOTER ───────────────────────────────
                pw.Divider(color: dividerColor, thickness: 0.5),
                pw.SizedBox(height: 6),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'CashPilot — Transaction Report',
                      style: subtitleStyle.copyWith(fontSize: 8),
                    ),
                    pw.Text(
                      'Page ${page + 1} of $totalPages',
                      style: subtitleStyle.copyWith(fontSize: 8),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  static pw.Expanded _summaryBox(
    String label,
    String value,
    PdfColor valueColor,
    PdfColor bgColor,
    pw.TextStyle amountStyle,
    pw.TextStyle labelStyle,
  ) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: labelStyle),
            pw.SizedBox(height: 4),
            pw.Text(
              value,
              style: amountStyle.copyWith(color: valueColor),
            ),
          ],
        ),
      ),
    );
  }
}
