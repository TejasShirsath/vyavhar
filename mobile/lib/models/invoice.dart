import 'invoice_item.dart';

class Invoice {
  final String id;
  final String invoiceNumber;
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String? customerAddress;
  final double subtotal;
  final double discount;
  final double gstRate; // e.g. 5%, 12%, 18%
  final double gstAmount;
  final double additionalCharges;
  final double grandTotal;
  final double paidAmount;
  final String paymentStatus; // 'Paid', 'Pending', 'Partial'
  final String paymentMode; // 'Cash', 'UPI', 'Bank Transfer', 'Credit'
  final String? notes;
  final DateTime createdAt;
  final bool isCancelled;

  // Associated details loaded when reading invoice
  final List<InvoiceItem> items;
  final List<String> photoPaths;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    required this.customerName,
    required this.customerPhone,
    this.customerAddress,
    required this.subtotal,
    this.discount = 0.0,
    this.gstRate = 0.0,
    this.gstAmount = 0.0,
    this.additionalCharges = 0.0,
    required this.grandTotal,
    required this.paidAmount,
    this.paymentStatus = 'Paid',
    this.paymentMode = 'Cash',
    this.notes,
    required this.createdAt,
    this.isCancelled = false,
    this.items = const [],
    this.photoPaths = const [],
  });

  double get pendingAmount => (grandTotal - paidAmount).clamp(0.0, double.infinity);
  double get totalCogs => items.fold(0.0, (sum, item) => sum + item.costOfGoodsSold);
  double get grossProfit => grandTotal - totalCogs;

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    double? subtotal,
    double? discount,
    double? gstRate,
    double? gstAmount,
    double? additionalCharges,
    double? grandTotal,
    double? paidAmount,
    String? paymentStatus,
    String? paymentMode,
    String? notes,
    DateTime? createdAt,
    bool? isCancelled,
    List<InvoiceItem>? items,
    List<String>? photoPaths,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      gstRate: gstRate ?? this.gstRate,
      gstAmount: gstAmount ?? this.gstAmount,
      additionalCharges: additionalCharges ?? this.additionalCharges,
      grandTotal: grandTotal ?? this.grandTotal,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isCancelled: isCancelled ?? this.isCancelled,
      items: items ?? this.items,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoice_number': invoiceNumber,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_address': customerAddress,
      'subtotal': subtotal,
      'discount': discount,
      'gst_rate': gstRate,
      'gst_amount': gstAmount,
      'additional_charges': additionalCharges,
      'grand_total': grandTotal,
      'paid_amount': paidAmount,
      'payment_status': paymentStatus,
      'payment_mode': paymentMode,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'is_cancelled': isCancelled ? 1 : 0,
    };
  }

  factory Invoice.fromMap(Map<String, dynamic> map,
      {List<InvoiceItem> items = const [], List<String> photoPaths = const []}) {
    return Invoice(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      customerId: map['customer_id'] as String?,
      customerName: map['customer_name'] as String,
      customerPhone: map['customer_phone'] as String,
      customerAddress: map['customer_address'] as String?,
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      gstRate: (map['gst_rate'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (map['gst_amount'] as num?)?.toDouble() ?? 0.0,
      additionalCharges: (map['additional_charges'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (map['grand_total'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['payment_status'] as String? ?? 'Paid',
      paymentMode: map['payment_mode'] as String? ?? 'Cash',
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      isCancelled: (map['is_cancelled'] as int?) == 1,
      items: items,
      photoPaths: photoPaths,
    );
  }
}
