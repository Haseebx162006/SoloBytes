import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:solobytes/domain/entities/import_result.dart';
import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/transaction.dart';

enum _ExcelSchema { transaction, receivable, flexible }

class ExcelParser {
  const ExcelParser();

  static const String invalidSchemaError =
      'Invalid Excel structure. No recognized column headers found.';

  // ── Rigid schema headers (backward compat) ──────────────────────
  static const List<String> _transactionHeaders = [
    'date',
    'type',
    'category',
    'amount',
    'note',
  ];

  static const List<String> _transactionHeadersWithProduct = [
    'date',
    'type',
    'category',
    'amount',
    'note',
    'productname',
  ];

  static const List<String> _receivableHeaders = [
    'customername',
    'amount',
    'duedate',
    'invoiceref',
  ];

  // ── Recognized flexible column names ────────────────────────────
  static const Set<String> _knownColumns = {
    'date',
    'expense',
    'sale',
    'income',
    'category',
    'note',
    'description',
    'productname',
    'product',
    'personname',
    'person',
    'payable',
    'vendorname',
    'receivable',
    'customername',
    'duedate',
  };

  // ═══════════════════════════════════════════════════════════════
  //  PUBLIC API
  // ═══════════════════════════════════════════════════════════════

  ImportResult parse(Uint8List fileBytes) {
    if (fileBytes.isEmpty) {
      return const ImportResult(
        errors: ['Excel file is empty.'],
        isSchemaValid: false,
      );
    }

    try {
      final excel = Excel.decodeBytes(fileBytes);
      if (excel.tables.isEmpty) {
        return const ImportResult(
          errors: ['Excel file is empty.'],
          isSchemaValid: false,
        );
      }

      final firstSheetName = excel.tables.keys.first;
      final sheet = excel.tables[firstSheetName];
      if (sheet == null || sheet.rows.isEmpty) {
        return const ImportResult(
          errors: ['Excel file is empty.'],
          isSchemaValid: false,
        );
      }

      final rows = sheet.rows;
      final headers = _normalizeHeaders(rows.first);
      final schema = _resolveSchema(headers);
      if (schema == null) {
        return const ImportResult(
          errors: [invalidSchemaError],
          isSchemaValid: false,
        );
      }

      // ── Flexible path ────────────────────────────
      if (schema == _ExcelSchema.flexible) {
        return _parseFlexibleRows(headers, rows);
      }

      // ── Rigid path (backward compat) ─────────────
      return _parseRigidRows(schema, rows);
    } catch (_) {
      return const ImportResult(
        errors: [
          'Unable to read Excel file. Please upload a valid .xlsx file.',
        ],
        isSchemaValid: false,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  SCHEMA RESOLUTION
  // ═══════════════════════════════════════════════════════════════

  _ExcelSchema? _resolveSchema(List<String> headers) {
    // 1. Try rigid transaction schema
    if (_matchesHeaders(headers, _transactionHeaders) ||
        _matchesHeaders(headers, _transactionHeadersWithProduct)) {
      return _ExcelSchema.transaction;
    }

    // 2. Try rigid receivable schema
    if (_matchesHeaders(headers, _receivableHeaders)) {
      return _ExcelSchema.receivable;
    }

    // 3. Flexible: check if ANY recognized column exists
    final recognized =
        headers.where((h) => _knownColumns.contains(h)).toList();
    if (recognized.isNotEmpty) {
      return _ExcelSchema.flexible;
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════════
  //  FLEXIBLE PARSER
  // ═══════════════════════════════════════════════════════════════

  ImportResult _parseFlexibleRows(
    List<String> headers,
    List<List<Data?>> rows,
  ) {
    // Build column index map
    final colIndex = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      final h = headers[i];
      if (_knownColumns.contains(h) && !colIndex.containsKey(h)) {
        colIndex[h] = i;
      }
      // Map aliases
      if (h == 'income' && !colIndex.containsKey('sale')) {
        colIndex['sale'] = i;
      }
      if (h == 'description' && !colIndex.containsKey('note')) {
        colIndex['note'] = i;
      }
      if (h == 'product' && !colIndex.containsKey('productname')) {
        colIndex['productname'] = i;
      }
      if (h == 'person' && !colIndex.containsKey('personname')) {
        colIndex['personname'] = i;
      }
      if (h == 'vendorname' && !colIndex.containsKey('payable')) {
        // vendorname column indicates payable entries — we'll read amount from 'payable' or 'amount'
        colIndex['vendorname'] = i;
      }
      if (h == 'customername' && !colIndex.containsKey('receivable')) {
        colIndex['customername'] = i;
      }
    }

    // Determine capability
    final hasExpenseCol = colIndex.containsKey('expense');
    final hasSaleCol =
        colIndex.containsKey('sale') || colIndex.containsKey('income');
    final hasPayableCol = colIndex.containsKey('payable');
    final hasReceivableCol = colIndex.containsKey('receivable');

    final parsedTransactions = <TransactionEntity>[];
    final parsedReceivables = <ReceivableEntity>[];
    final errors = <String>[];

    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (_isEmptyRow(row)) continue;

      try {
        // ── Read common fields ────────────────────────────
        final date = colIndex.containsKey('date')
            ? _parseDate(_valueAt(row, colIndex['date']!))
            : null;
        final effectiveDate = date ?? DateTime.now();

        final category = colIndex.containsKey('category')
            ? _cellToText(_valueAt(row, colIndex['category']!)).trim()
            : '';
        final effectiveCategory =
            category.isNotEmpty ? category : 'Imported';

        final note = colIndex.containsKey('note')
            ? _cellToText(_valueAt(row, colIndex['note']!)).trim()
            : '';

        final productName = colIndex.containsKey('productname')
            ? _cellToText(_valueAt(row, colIndex['productname']!)).trim()
            : null;
        final effectiveProduct =
            (productName != null && productName.isNotEmpty)
                ? productName
                : null;

        final personName = colIndex.containsKey('personname')
            ? _cellToText(_valueAt(row, colIndex['personname']!)).trim()
            : null;
        final effectivePerson =
            (personName != null && personName.isNotEmpty)
                ? personName
                : null;

        final dueDate = colIndex.containsKey('duedate')
            ? _parseDate(_valueAt(row, colIndex['duedate']!))
            : null;
        final effectiveDueDate =
            dueDate ?? DateTime.now().add(const Duration(days: 30));

        // ── Expense transaction ────────────────────────────
        if (hasExpenseCol) {
          final expenseAmt =
              _parseAmount(_valueAt(row, colIndex['expense']!));
          if (expenseAmt != null && expenseAmt > 0) {
            parsedTransactions.add(TransactionEntity(
              id: '',
              userId: '',
              type: TxType.expense,
              category: effectiveCategory,
              amount: expenseAmt,
              note: note,
              date: effectiveDate,
              source: 'excel_import',
              personName: effectivePerson,
              productName: effectiveProduct,
            ));
          }
        }

        // ── Sale / Income transaction ─────────────────────
        if (hasSaleCol) {
          final saleColKey =
              colIndex.containsKey('sale') ? 'sale' : 'income';
          final saleAmt =
              _parseAmount(_valueAt(row, colIndex[saleColKey]!));
          if (saleAmt != null && saleAmt > 0) {
            parsedTransactions.add(TransactionEntity(
              id: '',
              userId: '',
              type: TxType.sale,
              category: effectiveCategory,
              amount: saleAmt,
              note: note,
              date: effectiveDate,
              source: 'excel_import',
              personName: effectivePerson,
              productName: effectiveProduct ?? 'Imported Sale',
            ));
          }
        }

        // ── Payable ledger entry ──────────────────────────
        if (hasPayableCol) {
          final payableAmt =
              _parseAmount(_valueAt(row, colIndex['payable']!));
          if (payableAmt != null && payableAmt > 0) {
            final vendorName = colIndex.containsKey('vendorname')
                ? _cellToText(_valueAt(row, colIndex['vendorname']!))
                    .trim()
                : '';
            parsedReceivables.add(ReceivableEntity(
              id: '',
              userId: '',
              entryType: LedgerEntryType.payable,
              customerName: '',
              vendorName: vendorName.isNotEmpty
                  ? vendorName
                  : (effectivePerson ?? 'Imported Vendor'),
              amount: payableAmt,
              dueDate: effectiveDueDate,
              status: PaymentStatus.unpaid,
              invoiceRef: null,
              createdAt: DateTime.now(),
              paidAt: null,
            ));
          }
        }

        // ── Receivable ledger entry ───────────────────────
        if (hasReceivableCol) {
          final receivableAmt =
              _parseAmount(_valueAt(row, colIndex['receivable']!));
          if (receivableAmt != null && receivableAmt > 0) {
            final custName = colIndex.containsKey('customername')
                ? _cellToText(_valueAt(row, colIndex['customername']!))
                    .trim()
                : '';
            parsedReceivables.add(ReceivableEntity(
              id: '',
              userId: '',
              entryType: LedgerEntryType.receivable,
              customerName: custName.isNotEmpty
                  ? custName
                  : (effectivePerson ?? 'Imported Customer'),
              vendorName: '',
              amount: receivableAmt,
              dueDate: effectiveDueDate,
              status: PaymentStatus.unpaid,
              invoiceRef: null,
              createdAt: DateTime.now(),
              paidAt: null,
            ));
          }
        }
      } catch (error) {
        errors.add('Row ${rowIndex + 1}: ${error.toString()}');
      }
    }

    final successCount =
        parsedTransactions.length + parsedReceivables.length;

    return ImportResult(
      transactions: parsedTransactions,
      receivables: parsedReceivables,
      errors: errors,
      successCount: successCount,
      failedCount: errors.length,
      isSchemaValid: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RIGID PARSER  (backward compat — old exact-header schemas)
  // ═══════════════════════════════════════════════════════════════

  ImportResult _parseRigidRows(_ExcelSchema schema, List<List<Data?>> rows) {
    final parsedTransactions = <TransactionEntity>[];
    final parsedReceivables = <ReceivableEntity>[];
    final errors = <String>[];

    for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      if (_isEmptyRow(row)) continue;

      try {
        if (schema == _ExcelSchema.transaction) {
          final parsed = _parseTransactionRow(row);
          parsedTransactions.add(parsed);
        } else {
          final parsed = _parseReceivableRow(row);
          parsedReceivables.add(parsed);
        }
      } catch (error) {
        errors.add('Row ${rowIndex + 1}: ${error.toString()}');
      }
    }

    final successCount =
        parsedTransactions.length + parsedReceivables.length;

    return ImportResult(
      transactions: parsedTransactions,
      receivables: parsedReceivables,
      errors: errors,
      successCount: successCount,
      failedCount: errors.length,
      isSchemaValid: true,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RIGID ROW PARSERS (unchanged)
  // ═══════════════════════════════════════════════════════════════

  TransactionEntity _parseTransactionRow(List<Data?> row) {
    final date = _parseDate(_valueAt(row, 0));
    if (date == null) {
      throw Exception('Date is invalid');
    }

    final typeRaw = _cellToText(_valueAt(row, 1)).trim().toLowerCase();
    final type = _parseTransactionType(typeRaw);
    if (type == null) {
      throw Exception('Type must be sale or expense');
    }

    final category = _cellToText(_valueAt(row, 2)).trim();
    if (category.isEmpty) {
      throw Exception('Category is required');
    }

    final amount = _parseAmount(_valueAt(row, 3));
    if (amount == null || amount <= 0) {
      throw Exception('Amount must be a number greater than 0');
    }

    final note = _cellToText(_valueAt(row, 4)).trim();
    String? productName;

    if (row.length > 5) {
      productName = _cellToText(_valueAt(row, 5)).trim();
      if (productName.isEmpty) productName = null;
    }

    if (type == TxType.sale && (productName == null || productName.isEmpty)) {
      productName = 'Imported Sale';
    }

    return TransactionEntity(
      id: '',
      userId: '',
      type: type,
      category: category,
      amount: amount,
      note: note,
      date: date,
      source: 'excel_import',
      personName: null,
      productName: productName,
    );
  }

  ReceivableEntity _parseReceivableRow(List<Data?> row) {
    final customerName = _cellToText(_valueAt(row, 0)).trim();
    if (customerName.isEmpty) {
      throw Exception('Customer name is required');
    }

    final amount = _parseAmount(_valueAt(row, 1));
    if (amount == null || amount <= 0) {
      throw Exception('Amount must be a number greater than 0');
    }

    final dueDate = _parseDate(_valueAt(row, 2));
    if (dueDate == null) {
      throw Exception('Due date is invalid');
    }

    final invoiceRefRaw = _cellToText(_valueAt(row, 3)).trim();
    final invoiceRef = invoiceRefRaw.isEmpty ? null : invoiceRefRaw;

    return ReceivableEntity(
      id: '',
      userId: '',
      entryType: LedgerEntryType.receivable,
      customerName: customerName,
      vendorName: '',
      amount: amount,
      dueDate: dueDate,
      status: PaymentStatus.unpaid,
      invoiceRef: invoiceRef,
      createdAt: DateTime.now(),
      paidAt: null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SHARED UTILITIES
  // ═══════════════════════════════════════════════════════════════

  bool _matchesHeaders(List<String> actual, List<String> expected) {
    if (actual.length != expected.length) {
      return false;
    }

    for (var i = 0; i < expected.length; i++) {
      if (actual[i] != expected[i]) {
        return false;
      }
    }

    return true;
  }

  List<String> _normalizeHeaders(List<Data?> row) {
    final headers = row
        .map((cell) => _cellToText(cell?.value)
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'\s+'), ''))
        .toList(growable: true);

    while (headers.isNotEmpty && headers.last.isEmpty) {
      headers.removeLast();
    }

    return headers;
  }

  bool _isEmptyRow(List<Data?> row) {
    for (final cell in row) {
      if (_cellToText(cell?.value).trim().isNotEmpty) {
        return false;
      }
    }

    return true;
  }

  CellValue? _valueAt(List<Data?> row, int index) {
    if (index < 0 || index >= row.length) {
      return null;
    }

    return row[index]?.value;
  }

  TxType? _parseTransactionType(String value) {
    if (value == 'sale' || value == 'income') {
      return TxType.sale;
    }

    if (value == 'expense') {
      return TxType.expense;
    }

    return null;
  }

  double? _parseAmount(CellValue? value) {
    if (value is IntCellValue) {
      return value.value.toDouble();
    }

    if (value is DoubleCellValue) {
      return value.value;
    }

    final raw = _cellToText(value).trim();
    if (raw.isEmpty) {
      return null;
    }

    final normalized = raw
        .replaceAll(',', '')
        .replaceAll(RegExp(r'[^0-9.\-]'), '');
    return double.tryParse(normalized);
  }

  DateTime? _parseDate(CellValue? value) {
    if (value is DateCellValue) {
      return value.asDateTimeLocal();
    }

    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal();
    }

    if (value is IntCellValue) {
      return _dateFromExcelSerial(value.value.toDouble());
    }

    if (value is DoubleCellValue) {
      return _dateFromExcelSerial(value.value);
    }

    final text = _cellToText(value).trim();
    if (text.isEmpty) {
      return null;
    }

    final direct = DateTime.tryParse(text);
    if (direct != null) {
      return direct;
    }

    final separatorMatch = RegExp(
      r'^(\d{1,4})[\/\-](\d{1,2})[\/\-](\d{1,4})$',
    ).firstMatch(text);
    if (separatorMatch != null) {
      final partA = int.tryParse(separatorMatch.group(1)!);
      final partB = int.tryParse(separatorMatch.group(2)!);
      final partC = int.tryParse(separatorMatch.group(3)!);

      if (partA == null || partB == null || partC == null) {
        return null;
      }

      if (partA > 999) {
        return _safeDate(partA, partB, partC);
      }

      final year = partC < 100 ? 2000 + partC : partC;

      if (partA > 12) {
        return _safeDate(year, partB, partA);
      }

      if (partB > 12) {
        return _safeDate(year, partA, partB);
      }

      return _safeDate(year, partB, partA);
    }

    return null;
  }

  DateTime? _safeDate(int year, int month, int day) {
    try {
      final date = DateTime(year, month, day);
      if (date.year != year || date.month != month || date.day != day) {
        return null;
      }
      return date;
    } catch (_) {
      return null;
    }
  }

  DateTime _dateFromExcelSerial(double serial) {
    final base = DateTime(1899, 12, 30);
    return base.add(Duration(days: serial.floor()));
  }

  String _cellToText(CellValue? value) {
    if (value == null) {
      return '';
    }

    if (value is TextCellValue) {
      return value.value.toString();
    }

    if (value is IntCellValue) {
      return value.value.toString();
    }

    if (value is DoubleCellValue) {
      return value.value.toString();
    }

    if (value is BoolCellValue) {
      return value.value.toString();
    }

    if (value is DateCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }

    if (value is DateTimeCellValue) {
      return value.asDateTimeLocal().toIso8601String();
    }

    if (value is TimeCellValue) {
      return value.asDuration().toString();
    }

    return value.toString();
  }
}
