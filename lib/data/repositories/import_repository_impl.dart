import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solobytes/data/services/cloudinary_upload_service.dart';
import 'package:solobytes/domain/entities/import_result.dart';
import 'package:solobytes/domain/entities/receivable.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class ImportCommitResult {
  const ImportCommitResult({
    required this.storagePath,
    required this.transactionCount,
    required this.receivableCount,
  });

  final String storagePath;
  final int transactionCount;
  final int receivableCount;
}

class ImportRepositoryImpl {
  ImportRepositoryImpl({
    required FirebaseFirestore firestore,
    required CloudinaryUploadService cloudinaryUploadService,
  }) : _firestore = firestore,
       _cloudinaryUploadService = cloudinaryUploadService;

  final FirebaseFirestore _firestore;
  final CloudinaryUploadService _cloudinaryUploadService;

  static const int _maxBatchOperations = 500;

  Future<ImportCommitResult> importData({
    required String userId,
    required Uint8List originalFileBytes,
    required ImportResult importResult,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw Exception('User is required for import');
    }

    if (!importResult.isSchemaValid) {
      throw Exception(ExcelImportSchemaError.invalidSchemaMessage);
    }

    final storagePath = await uploadOriginalFileBackup(
      userId: normalizedUserId,
      fileBytes: originalFileBytes,
    );

    await saveParsedData(
      userId: normalizedUserId,
      transactions: importResult.transactions,
      receivables: importResult.receivables,
    );

    return ImportCommitResult(
      storagePath: storagePath,
      transactionCount: importResult.transactions.length,
      receivableCount: importResult.receivables.length,
    );
  }

  Future<String> uploadOriginalFileBackup({
    required String userId,
    required Uint8List fileBytes,
  }) async {
    if (fileBytes.isEmpty) {
      throw Exception('Cannot upload an empty file');
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      return await _cloudinaryUploadService.uploadExcelBackup(
        userId: userId,
        fileBytes: fileBytes,
        timestamp: timestamp,
      );
    } on Exception catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '').trim();
      if (message.isNotEmpty) {
        throw Exception(message);
      }

      throw Exception('Unable to upload Excel backup file');
    } catch (_) {
      throw Exception('Unable to upload Excel backup file');
    }
  }

  Future<void> saveParsedData({
    required String userId,
    required List<TransactionEntity> transactions,
    required List<ReceivableEntity> receivables,
  }) async {
    if (transactions.isEmpty && receivables.isEmpty) {
      return;
    }

    WriteBatch batch = _firestore.batch();
    var operations = 0;

    Future<void> setInBatch(
      DocumentReference<Map<String, dynamic>> document,
      Map<String, dynamic> data,
    ) async {
      batch.set(document, data, SetOptions(merge: true));
      operations += 1;

      if (operations >= _maxBatchOperations) {
        await batch.commit();
        batch = _firestore.batch();
        operations = 0;
      }
    }

    try {
      // ── Save transactions under user's subcollection ────────
      for (final transaction in transactions) {
        final txRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc();

        final payload = <String, dynamic>{
          'userId': userId,
          'type': transaction.type.name,
          'nature': transaction.nature.name,
          'category': transaction.category.trim(),
          'amount': transaction.amount,
          'note': transaction.note.trim(),
          'date': Timestamp.fromDate(transaction.date),
          'source': transaction.source.trim().isEmpty
              ? 'excel_import'
              : transaction.source.trim(),
        };

        // Include productName if present
        if (transaction.productName != null &&
            transaction.productName!.trim().isNotEmpty) {
          payload['productName'] = transaction.productName!.trim();
        }

        // Include personName if present
        if (transaction.personName != null &&
            transaction.personName!.trim().isNotEmpty) {
          payload['personName'] = transaction.personName!.trim();
        }

        await setInBatch(txRef, payload);
      }

      // ── Save receivables / payables ─────────────────────────
      for (final receivable in receivables) {
        final collection = receivable.entryType == LedgerEntryType.payable
            ? 'payables'
            : 'receivables';

        final receivableRef = _firestore.collection(collection).doc();

        final name = receivable.partyName;
        final storedStatus = receivable.status == PaymentStatus.paid
            ? PaymentStatus.paid.name
            : PaymentStatus.unpaid.name;

        final payload = <String, dynamic>{
          'userId': userId,
          'amount': receivable.amount,
          'dueDate': Timestamp.fromDate(receivable.dueDate),
          'status': storedStatus,
          'createdAt': Timestamp.fromDate(receivable.createdAt),
          'invoiceRef': _nullableText(receivable.invoiceRef),
        };

        if (receivable.entryType == LedgerEntryType.payable) {
          payload['vendorName'] = name;
        } else {
          payload['customerName'] = name;
        }

        if (receivable.paidAt != null &&
            storedStatus == PaymentStatus.paid.name) {
          payload['paidAt'] = Timestamp.fromDate(receivable.paidAt!);
        }

        payload.removeWhere((_, value) => value == null);

        await setInBatch(receivableRef, payload);
      }

      if (operations > 0) {
        await batch.commit();
      }
    } on FirebaseException catch (error) {
      throw Exception(error.message ?? 'Unable to save imported data');
    } catch (_) {
      throw Exception('Unable to save imported data');
    }
  }

  String? _nullableText(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}

class ExcelImportSchemaError {
  static const String invalidSchemaMessage =
      'Invalid Excel structure. Column headers do not match required format.';
}
