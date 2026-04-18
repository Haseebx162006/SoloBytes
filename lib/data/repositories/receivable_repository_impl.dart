import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solobytes/domain/entities/receivable.dart';

class ReceivableRepositoryImpl {
  ReceivableRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(
    LedgerEntryType entryType,
  ) {
    final collectionName = entryType == LedgerEntryType.receivable
        ? 'receivables'
        : 'payables';
    return _firestore.collection(collectionName);
  }

  Stream<List<ReceivableEntity>> watchItems({
    required String userId,
    required LedgerEntryType entryType,
    PaymentStatus? status,
  }) async* {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      yield const [];
      return;
    }

    final query = _collection(
      entryType,
    ).where('userId', isEqualTo: normalizedUserId);

    try {
      await for (final snapshot in query.snapshots()) {
        final items = snapshot.docs
            .map((doc) => _fromFirestore(doc.id, doc.data(), entryType))
            .toList(growable: false);

        // Sort in memory to avoid requiring a composite index in Firestore
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        yield _filterByStatus(items, status);
      }
    } on FirebaseException catch (e) {
      print('FirebaseException in watchItems: ${e.message}');
      yield const [];
    } catch (e) {
      print('Exception in watchItems: $e');
      yield const [];
    }
  }

  Future<ReceivableEntity> saveItem(ReceivableEntity item) async {
    final collection = _collection(item.entryType);
    final docId = item.id.trim().isEmpty ? collection.doc().id : item.id.trim();

    final normalizedName = item.partyName;
    final storedStatus = _toStoredStatus(item.status);

    final normalizedItem = item.copyWith(
      id: docId,
      customerName: item.entryType == LedgerEntryType.receivable
          ? normalizedName
          : '',
      vendorName: item.entryType == LedgerEntryType.payable
          ? normalizedName
          : '',
      status: storedStatus,
      invoiceRef: _normalizeOptional(item.invoiceRef),
      clearInvoiceRef: _normalizeOptional(item.invoiceRef) == null,
    );

    final payload = _toFirestoreMap(normalizedItem);

    try {
      await collection.doc(docId).set(payload, SetOptions(merge: true));

      final runtimeStatus = _resolveRuntimeStatus(
        storedStatus: storedStatus,
        dueDate: normalizedItem.dueDate,
        hasDueDate: true,
      );

      return normalizedItem.copyWith(status: runtimeStatus);
    } on FirebaseException catch (error) {
      final message = error.message ?? 'Unable to save item';
      throw Exception(message);
    } catch (_) {
      throw Exception('Unable to save item');
    }
  }

  Future<void> markPaid({
    required LedgerEntryType entryType,
    required String itemId,
    DateTime? paidAt,
  }) async {
    final normalizedId = itemId.trim();
    if (normalizedId.isEmpty) {
      throw Exception('Item id is required');
    }

    final paidTime = paidAt ?? DateTime.now();

    try {
      await _collection(entryType).doc(normalizedId).set({
        'status': PaymentStatus.paid.name,
        'paidAt': Timestamp.fromDate(paidTime),
      }, SetOptions(merge: true));
    } on FirebaseException catch (error) {
      final message = error.message ?? 'Unable to mark item as paid';
      throw Exception(message);
    } catch (_) {
      throw Exception('Unable to mark item as paid');
    }
  }

  Future<void> deleteItem({
    required LedgerEntryType entryType,
    required String itemId,
  }) async {
    final normalizedId = itemId.trim();
    if (normalizedId.isEmpty) {
      return;
    }

    try {
      await _collection(entryType).doc(normalizedId).delete();
    } on FirebaseException catch (error) {
      final message = error.message ?? 'Unable to delete item';
      throw Exception(message);
    } catch (_) {
      throw Exception('Unable to delete item');
    }
  }

  ReceivableEntity _fromFirestore(
    String id,
    Map<String, dynamic> map,
    LedgerEntryType entryType,
  ) {
    final rawDueDate = map['dueDate'];
    final hasDueDate = _hasValidDate(rawDueDate);

    final dueDate = _requiredDateFromValue(
      rawDueDate,
      fallback: DateTime.now().add(const Duration(days: 36500)),
    );

    final createdAt = _requiredDateFromValue(
      map['createdAt'],
      fallback: DateTime.now(),
    );

    final paidAt = _nullableDateFromValue(map['paidAt']);
    final storedStatus = _statusFromValue(map['status']);
    final runtimeStatus = _resolveRuntimeStatus(
      storedStatus: storedStatus,
      dueDate: dueDate,
      hasDueDate: hasDueDate,
    );

    final name = _resolveName(map, entryType);

    return ReceivableEntity(
      id: id,
      userId: (map['userId'] ?? '').toString().trim(),
      entryType: entryType,
      customerName: entryType == LedgerEntryType.receivable ? name : '',
      vendorName: entryType == LedgerEntryType.payable ? name : '',
      amount: _toDouble(map['amount']),
      dueDate: dueDate,
      status: runtimeStatus,
      invoiceRef: _normalizeOptional(map['invoiceRef']?.toString()),
      createdAt: createdAt,
      paidAt: paidAt,
    );
  }

  Map<String, dynamic> _toFirestoreMap(ReceivableEntity item) {
    final data = <String, dynamic>{
      'userId': item.userId.trim(),
      'amount': item.amount,
      'dueDate': Timestamp.fromDate(item.dueDate),
      'status': _toStoredStatus(item.status).name,
      'createdAt': Timestamp.fromDate(item.createdAt),
      'invoiceRef': _normalizeOptional(item.invoiceRef),
    };

    if (item.entryType == LedgerEntryType.receivable) {
      data['customerName'] = item.customerName.trim();
    } else {
      data['vendorName'] = item.vendorName.trim();
    }

    if (item.paidAt != null) {
      data['paidAt'] = Timestamp.fromDate(item.paidAt!);
    }

    data.removeWhere((_, value) => value == null);
    return data;
  }

  List<ReceivableEntity> _filterByStatus(
    List<ReceivableEntity> items,
    PaymentStatus? status,
  ) {
    if (status == null) {
      return items;
    }

    return items.where((item) => item.status == status).toList(growable: false);
  }

  PaymentStatus _statusFromValue(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();

    if (raw == PaymentStatus.paid.name) {
      return PaymentStatus.paid;
    }

    if (raw == PaymentStatus.overdue.name) {
      return PaymentStatus.overdue;
    }

    return PaymentStatus.unpaid;
  }

  PaymentStatus _toStoredStatus(PaymentStatus status) {
    if (status == PaymentStatus.paid) {
      return PaymentStatus.paid;
    }

    return PaymentStatus.unpaid;
  }

  PaymentStatus _resolveRuntimeStatus({
    required PaymentStatus storedStatus,
    required DateTime dueDate,
    required bool hasDueDate,
  }) {
    if (storedStatus == PaymentStatus.paid) {
      return PaymentStatus.paid;
    }

    if (!hasDueDate) {
      return PaymentStatus.unpaid;
    }

    if (dueDate.isBefore(DateTime.now())) {
      return PaymentStatus.overdue;
    }

    return PaymentStatus.unpaid;
  }

  String _resolveName(Map<String, dynamic> map, LedgerEntryType entryType) {
    final customerName = (map['customerName'] ?? '').toString().trim();
    final vendorName = (map['vendorName'] ?? '').toString().trim();
    final fallback = (map['partyName'] ?? '').toString().trim();

    if (entryType == LedgerEntryType.receivable) {
      if (customerName.isNotEmpty) {
        return customerName;
      }

      if (vendorName.isNotEmpty) {
        return vendorName;
      }

      return fallback;
    }

    if (vendorName.isNotEmpty) {
      return vendorName;
    }

    if (customerName.isNotEmpty) {
      return customerName;
    }

    return fallback;
  }

  DateTime _requiredDateFromValue(dynamic value, {required DateTime fallback}) {
    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value) ?? fallback;
    }

    return fallback;
  }

  DateTime? _nullableDateFromValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    if (value is String) {
      return DateTime.tryParse(value);
    }

    return null;
  }

  bool _hasValidDate(dynamic value) {
    if (value is Timestamp || value is DateTime) {
      return true;
    }

    if (value is String) {
      return DateTime.tryParse(value) != null;
    }

    return false;
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  String? _normalizeOptional(String? value) {
    final normalized = value?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    return normalized;
  }
}
