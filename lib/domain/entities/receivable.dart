enum LedgerEntryType { receivable, payable }

enum PaymentStatus { unpaid, paid, overdue }

class ReceivableEntity {
  const ReceivableEntity({
    required this.id,
    required this.userId,
    required this.entryType,
    required this.customerName,
    required this.vendorName,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.invoiceRef,
    required this.createdAt,
    this.paidAt,
  });

  final String id;
  final String userId;
  final LedgerEntryType entryType;
  final String customerName;
  final String vendorName;
  final double amount;
  final DateTime dueDate;
  final PaymentStatus status;
  final String? invoiceRef;
  final DateTime createdAt;
  final DateTime? paidAt;

  bool get isReceivable => entryType == LedgerEntryType.receivable;
  bool get isPayable => entryType == LedgerEntryType.payable;
  bool get isPaid => status == PaymentStatus.paid;
  bool get isOverdue => status == PaymentStatus.overdue;

  String get partyName {
    if (isReceivable) {
      return customerName.trim();
    }

    return vendorName.trim();
  }

  ReceivableEntity copyWith({
    String? id,
    String? userId,
    LedgerEntryType? entryType,
    String? customerName,
    String? vendorName,
    double? amount,
    DateTime? dueDate,
    PaymentStatus? status,
    String? invoiceRef,
    bool clearInvoiceRef = false,
    DateTime? createdAt,
    DateTime? paidAt,
    bool clearPaidAt = false,
  }) {
    return ReceivableEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      entryType: entryType ?? this.entryType,
      customerName: customerName ?? this.customerName,
      vendorName: vendorName ?? this.vendorName,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      invoiceRef: clearInvoiceRef ? null : (invoiceRef ?? this.invoiceRef),
      createdAt: createdAt ?? this.createdAt,
      paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
    );
  }
}
