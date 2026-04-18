import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solobytes/application/usecases/parse_excel_usecase.dart';
import 'package:solobytes/data/excel_parser.dart';
import 'package:solobytes/data/repositories/import_repository_impl.dart';
import 'package:solobytes/domain/entities/import_result.dart';

class ImportState {
  const ImportState({
    this.isLoading = false,
    this.previewResult,
    this.errorMessage,
    this.isImportCompleted = false,
    this.backupStoragePath,
  });

  final bool isLoading;
  final ImportResult? previewResult;
  final String? errorMessage;
  final bool isImportCompleted;
  final String? backupStoragePath;

  ImportState copyWith({
    bool? isLoading,
    ImportResult? previewResult,
    bool clearPreviewResult = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isImportCompleted,
    String? backupStoragePath,
    bool clearBackupStoragePath = false,
  }) {
    return ImportState(
      isLoading: isLoading ?? this.isLoading,
      previewResult: clearPreviewResult
          ? null
          : (previewResult ?? this.previewResult),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      isImportCompleted: isImportCompleted ?? this.isImportCompleted,
      backupStoragePath: clearBackupStoragePath
          ? null
          : (backupStoragePath ?? this.backupStoragePath),
    );
  }
}

final importFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final importStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});

final excelParserProvider = Provider<ExcelParser>((ref) {
  return const ExcelParser();
});

final parseExcelUseCaseProvider = Provider<ParseExcelUseCase>((ref) {
  final parser = ref.watch(excelParserProvider);
  return ParseExcelUseCase(parser);
});

final importRepositoryProvider = Provider<ImportRepositoryImpl>((ref) {
  final firestore = ref.watch(importFirestoreProvider);
  final storage = ref.watch(importStorageProvider);
  return ImportRepositoryImpl(firestore: firestore, storage: storage);
});

final importProvider = NotifierProvider<ImportNotifier, ImportState>(
  ImportNotifier.new,
);

class ImportNotifier extends Notifier<ImportState> {
  @override
  ImportState build() {
    return const ImportState();
  }

  Future<ImportResult?> parseFile({
    required String fileName,
    required Uint8List fileBytes,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      isImportCompleted: false,
      clearBackupStoragePath: true,
    );

    try {
      final useCase = ref.read(parseExcelUseCaseProvider);
      final result = await useCase.execute(
        fileName: fileName,
        fileBytes: fileBytes,
      );

      final errorMessage = result.isSchemaValid
          ? null
          : (result.errors.isNotEmpty ? result.errors.first : 'Import failed');

      state = state.copyWith(
        isLoading: false,
        previewResult: result,
        errorMessage: errorMessage,
      );

      return result;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        clearPreviewResult: true,
        errorMessage: 'Unable to parse Excel file',
      );
      return null;
    }
  }

  Future<bool> confirmImport({
    required String userId,
    required Uint8List originalFileBytes,
  }) async {
    final preview = state.previewResult;
    if (preview == null) {
      state = state.copyWith(errorMessage: 'No parsed import preview found.');
      return false;
    }

    if (!preview.isSchemaValid) {
      state = state.copyWith(
        errorMessage: preview.errors.isNotEmpty
            ? preview.errors.first
            : 'Invalid Excel structure.',
      );
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      clearErrorMessage: true,
      isImportCompleted: false,
      clearBackupStoragePath: true,
    );

    try {
      final repository = ref.read(importRepositoryProvider);
      final commit = await repository.importData(
        userId: userId,
        originalFileBytes: originalFileBytes,
        importResult: preview,
      );

      state = state.copyWith(
        isLoading: false,
        isImportCompleted: true,
        backupStoragePath: commit.storagePath,
      );

      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isImportCompleted: false,
        errorMessage: error.toString().replaceFirst('Exception: ', '').trim(),
      );
      return false;
    }
  }

  void clear() {
    state = const ImportState();
  }
}
