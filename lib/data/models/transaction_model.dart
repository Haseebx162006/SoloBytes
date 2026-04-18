import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:solobytes/domain/entities/transaction.dart';

class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.category,
    required this.amount,
    required this.note,
    required this.date,
    required this.source,
  });

  final String id;
  final String userId;
  final TxType type;
  final String category;
  final double amount;
  final String note;
  final DateTime date;
  final String source;

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      userId: entity.userId,
      type: entity.type,
      category: entity.category,
      amount: entity.amount,
      note: entity.note,
      date: entity.date,
      source: _normalizeSource(entity.source),
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
      category: (map['category'] ?? '').toString(),
      amount: _doubleFromValue(map['amount']),
      note: (map['note'] ?? '').toString(),
      date: _dateFromValue(map['date']),
      source: _normalizeSource(map['source']),
    );
  }

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      userId: userId,
      type: type,
      category: category,
      amount: amount,
      note: note,
      date: date,
      source: source,
    );
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'userId': userId,
      'type': type.name,
      'category': category,
      'amount': amount,
      'note': note,
      'date': Timestamp.fromDate(date),
      'source': source,
    };
  }

  static TxType _txTypeFromValue(dynamic value) {
    final raw = (value ?? '').toString().toLowerCase();
    if (raw == TxType.income.name) {
      return TxType.income;
    }

    return TxType.expense;
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
}
