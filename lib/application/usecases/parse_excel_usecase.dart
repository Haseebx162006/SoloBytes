import 'dart:typed_data';

import 'package:solobytes/data/excel_parser.dart';
import 'package:solobytes/domain/entities/import_result.dart';

class ParseExcelUseCase {
  const ParseExcelUseCase(this._excelParser);

  final ExcelParser _excelParser;

  Future<ImportResult> execute({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    final normalizedName = fileName.trim().toLowerCase();
    if (!normalizedName.endsWith('.xlsx') && !normalizedName.endsWith('.xls')) {
      return const ImportResult(
        errors: ['Only .xlsx and .xls files are supported.'],
        isSchemaValid: false,
      );
    }

    return _excelParser.parse(fileBytes);
  }
}
