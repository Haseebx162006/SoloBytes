import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solobytes/domain/entities/person_account.dart';

class PersonAccountRepositoryImpl {
  PersonAccountRepositoryImpl({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) {
    return _firestore
        .collection('users')
        .doc(userId.trim())
        .collection('person_accounts');
  }

  Future<PersonAccount?> findByName({
    required String userId,
    required String name,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedName = name.trim().toLowerCase();

    if (normalizedUserId.isEmpty || normalizedName.isEmpty) {
      return null;
    }

    try {
      final snapshot = await _collection(
        normalizedUserId,
      ).where('nameLower', isEqualTo: normalizedName).limit(1).get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final doc = snapshot.docs.first;
      return _fromFirestore(doc.id, doc.data());
    } catch (_) {
      return null;
    }
  }

  Future<PersonAccount> updateOrCreate({
    required String userId,
    required String name,
    required double amountChange,
  }) async {
    final normalizedUserId = userId.trim();
    final normalizedName = name.trim();

    if (normalizedUserId.isEmpty || normalizedName.isEmpty) {
      throw Exception('User ID and name are required');
    }

    final existing = await findByName(
      userId: normalizedUserId,
      name: normalizedName,
    );

    if (existing != null) {
      // Update existing account
      final newBalance = existing.balance + amountChange;
      final updated = existing.copyWith(
        balance: newBalance,
        lastTransactionDate: DateTime.now(),
        transactionCount: existing.transactionCount + 1,
      );

      await _collection(
        normalizedUserId,
      ).doc(existing.id).set(_toFirestoreMap(updated), SetOptions(merge: true));

      return updated;
    } else {
      // Create new account
      final docRef = _collection(normalizedUserId).doc();
      final newAccount = PersonAccount(
        id: docRef.id,
        userId: normalizedUserId,
        name: normalizedName,
        balance: amountChange,
        lastTransactionDate: DateTime.now(),
        transactionCount: 1,
      );

      await docRef.set(_toFirestoreMap(newAccount));
      return newAccount;
    }
  }

  Stream<List<PersonAccount>> watchAccounts({required String userId}) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      return Stream.value(const []);
    }

    try {
      return _collection(normalizedUserId)
          .orderBy('lastTransactionDate', descending: true)
          .snapshots()
          .handleError((error) {
            print('Error in watchAccounts stream: $error');
          })
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => _fromFirestore(doc.id, doc.data()))
                .toList();
          });
    } catch (_) {
      return Stream.value(const []);
    }
  }

  PersonAccount _fromFirestore(String id, Map<String, dynamic> map) {
    return PersonAccount(
      id: id,
      userId: (map['userId'] ?? '').toString().trim(),
      name: (map['name'] ?? '').toString().trim(),
      balance: _toDouble(map['balance']),
      lastTransactionDate: _toDateTime(map['lastTransactionDate']),
      transactionCount: _toInt(map['transactionCount']),
    );
  }

  Map<String, dynamic> _toFirestoreMap(PersonAccount account) {
    return {
      'userId': account.userId.trim(),
      'name': account.name.trim(),
      'nameLower': account.name.trim().toLowerCase(),
      'balance': account.balance,
      'lastTransactionDate': Timestamp.fromDate(account.lastTransactionDate),
      'transactionCount': account.transactionCount,
    };
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

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
