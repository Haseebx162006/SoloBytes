import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.nature,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.source,
    this.personName,
    this.productName,
  });

  final String id;
  final String userId;
  final TxType type;
  final TransactionNature nature;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final String source;
  final String? personName;
  final String? productName;

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      nature: entity.nature,
      category: entity.category,
      amount: entity.amount,
      note: entity.note,
      date: entity.date,
      source: _normalizeSource(entity.source),
      personName: entity.personName,
      productName: entity.productName,
    );
  }

  factory TransactionModel.fromFirestoreMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return TransactionModel(
      id: id,
      userId: (map['userId'] ?? '').toString(),
      type: _txTypeFromValue(map['type']),
      nature: _transactionNatureFromValue(map['nature']),
      category: (map['category'] ?? '').toString(),
      amount: _doubleFromValue(map['amount']),
      note: (map['note'] ?? '').toString(),
      date: _dateFromValue(map['date']),
      source: _normalizeSource(map['source']),
      personName: _normalizeOptional(map['personName']),
      productName: _normalizeOptional(map['productName']),
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      type: type,
      nature: nature,
      category: category,
      amount: amount,
      note: note,
      date: date,
      source: source,
      personName: personName,
      productName: productName,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    final map = {
      'id': id,
      'userId': userId,
      'type': type.name,
      'nature': nature.name,
      'category': category,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(date),
      'source': source,
    };

    if (personName != null && personName!.trim().isNotEmpty) {
      map['personName'] = personName!.trim();
    }

    if (type == TxType.sale &&
        productName != null &&
        productName!.trim().isNotEmpty) {
      map['productName'] = productName!.trim();
    }

    return map;
  }

  static TxType _txTypeFromValue(dynamic value) {
    final raw = (value ?? '').toString().toLowerCase();
    if (raw == 'sale' || raw == 'income') {
      return TxType.sale;
    }

    return TxType.expense;
  }

  static TransactionNature _transactionNatureFromValue(dynamic value) {
    final raw = (value ?? '').toString().trim().toLowerCase();

    if (raw == 'weowe' || raw == 'we_owe' || raw == 'we owe') {
      return TransactionNature.weOwe;
    }

    if (raw == 'owedtous' || raw == 'owed_to_us' || raw == 'owed to us') {
      return TransactionNature.owedToUs;
    }

    return TransactionNature.normal;
  }

  static DateTime _dateFromValue(dynamic value) {
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

  static double _doubleFromValue(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  static String _normalizeSource(dynamic value) {
    final raw = (value ?? 'manual').toString().trim().toLowerCase();
    if (raw == 'excel_import') {
      return 'excel_import';
    }

    return 'manual';
  }

  static String? _normalizeOptional(dynamic value) {
    if (value == null) return null;
    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }
}
