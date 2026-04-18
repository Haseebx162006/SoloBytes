import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardRawData {
  const DashboardRawData({
    required this.transactions,
    required this.receivables,
    required this.payables,
  });

  final List<Map<String, dynamic>> transactions;
  final List<Map<String, dynamic>> receivables;
  final List<Map<String, dynamic>> payables;
}

class DashboardRepositoryImpl {
  DashboardRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  Future<DashboardRawData> fetchDashboardRawData({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final results = await Future.wait([
      fetchTransactions(startDate: startDate, endDate: endDate),
      fetchReceivables(startDate: startDate, endDate: endDate),
      fetchPayables(startDate: startDate, endDate: endDate),
    ]);

    return DashboardRawData(
      transactions: results[0],
      receivables: results[1],
      payables: results[2],
    );
  }

  Future<List<Map<String, dynamic>>> fetchTransactions({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('transactions');
      query = _applyDateRange(query, startDate: startDate, endDate: endDate);
      final snapshot = await query.get();
      return _toMapList(snapshot);
    } on FirebaseException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchReceivables({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('receivables');
      query = _applyDateRange(query, startDate: startDate, endDate: endDate);
      final snapshot = await query.get();
      return _toMapList(snapshot);
    } on FirebaseException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPayables({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('payables');
      query = _applyDateRange(query, startDate: startDate, endDate: endDate);
      final snapshot = await query.get();
      return _toMapList(snapshot);
    } on FirebaseException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Query<Map<String, dynamic>> _applyDateRange(
    Query<Map<String, dynamic>> query, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    Query<Map<String, dynamic>> filtered = query;

    if (startDate != null) {
      filtered = filtered.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
      );
    }

    if (endDate != null) {
      filtered = filtered.where(
        'createdAt',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate),
      );
    }

    return filtered;
  }

  List<Map<String, dynamic>> _toMapList(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    return snapshot.docs.map((doc) => doc.data()).toList();
  }
}
