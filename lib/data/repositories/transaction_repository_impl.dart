import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solobytes/data/models/transaction_model.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class TransactionRepositoryImpl {
  TransactionRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _transactionsCollection {
    return _firestore.collection('transactions');
  }

  Future<TransactionEntity> addTransaction(TransactionEntity transaction) async {
    try {
      final transactionId =
          transaction.id.trim().isEmpty
              ? _transactionsCollection.doc().id
              : transaction.id.trim();

      final model = TransactionModel(
        id: transactionId,
        userId: transaction.userId,
        type: transaction.type,
        category: transaction.category,
        amount: transaction.amount,
        note: transaction.note,
        date: transaction.date,
        source: transaction.source,
      );

      await _transactionsCollection.doc(transactionId).set(model.toFirestoreMap());
      return model.toEntity();
    } on FirebaseException catch (error) {
      final message = error.message ?? 'Unable to add transaction';
      throw Exception(message);
    } catch (_) {
      throw Exception('Unable to add transaction');
    }
  }

  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    TxType? type,
    String? category,
  }) async {
    if (userId.trim().isEmpty) {
      return const [];
    }

    try {
      Query<Map<String, dynamic>> query = _transactionsCollection.where(
        'userId',
        isEqualTo: userId.trim(),
      );

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
        );
      }

      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate),
        );
      }

      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }

      final normalizedCategory = category?.trim() ?? '';
      if (normalizedCategory.isNotEmpty) {
        query = query.where('category', isEqualTo: normalizedCategory);
      }

      query = query.orderBy('date', descending: true);
      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) =>
                TransactionModel.fromFirestoreMap(doc.id, doc.data()).toEntity(),
          )
          .toList();
    } on FirebaseException {
      return const [];
    } catch (_) {
      return const [];
    }
  }
}
