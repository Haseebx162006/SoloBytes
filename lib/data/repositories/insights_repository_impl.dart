import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solobytes/domain/entities/cash_summary.dart';

class InsightsRepositoryImpl {
  InsightsRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<Map<String, dynamic>?> getLatestInsight(String uid) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(normalizedUid)
          .collection('insights')
          .doc('latest')
          .get();

      if (doc.exists) {
        return doc.data();
      }
    } catch (_) {}
    return null;
  }

  Future<void> saveInsight({
    required String uid,
    required String text,
    required CashSummary summary,
  }) async {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(normalizedUid)
          .collection('insights')
          .doc('latest')
          .set({
            'text': text,
            'generatedAt': FieldValue.serverTimestamp(),
            'dataSnapshot': {
              'totalSales': summary.totalSales,
              'totalExpenses': summary.totalExpenses,
              'unpaidReceivables': summary.unpaidReceivables,
              'unpaidPayables': summary.unpaidPayables,
              'topExpenseCategory': summary.topExpenseCategory,
            },
          }, SetOptions(merge: true));
    } catch (_) {}
  }
}
