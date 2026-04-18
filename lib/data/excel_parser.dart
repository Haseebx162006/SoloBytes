import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:solobytes/domain/entities/import_result.dart';
import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/transaction.dart';

enum _ExcelSchema { transaction, receivable }

class ExcelParser {
  const ExcelParser();

  static const String invalidSchemaError =
      'Invalid Excel structure. Column headers do not match required format.';

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
    'productname', // New optional header
  ];

  static const List<String> _receivableHeaders = [
    'customername',
    'amount',
    'duedate',
    'invoiceref',
  ];

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

      final parsedTransactions = <TransactionEntity>[];
      final parsedReceivables = <ReceivableEntity>[];
      final errors = <String>[];

      for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        if (_isEmptyRow(row)) {
          continue;
        }

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

      final successCount = parsedTransactions.length + parsedReceivables.length;
      final failedCount = errors.length;

      return ImportResult(
        transactions: parsedTransactions,
        receivables: parsedReceivables,
        errors: errors,
        successCount: successCount,
        failedCount: failedCount,
        isSchemaValid: true,
      );
    } catch (_) {
      return const ImportResult(
        errors: [
          'Unable to read Excel file. Please upload a valid .xlsx file.',
        ],
        isSchemaValid: false,
      );
    }
  }

  _ExcelSchema? _resolveSchema(List<String> headers) {
    if (_matchesHeaders(headers, _transactionHeaders) ||
        _matchesHeaders(headers, _transactionHeadersWithProduct)) {
      return _ExcelSchema.transaction;
    }

    if (_matchesHeaders(headers, _receivableHeaders)) {
      return _ExcelSchema.receivable;
    }

    return null;
  }

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
        .map((cell) => _cellToText(cell?.value).trim().toLowerCase())
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
      r'^(\d{1,4})[\/-](\d{1,2})[\/-](\d{1,4})$',
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
