class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    this.purchaseId,
    required this.amount,
    required this.paymentDate,
    required this.notes,
    required this.createdAt,
    this.updatedAt,
    this.createdByName,
    this.updatedByName,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final String? purchaseId;
  final double amount;
  final String paymentDate;
  final String notes;
  final String createdAt;
  final String? updatedAt;
  final String? createdByName;
  final String? updatedByName;

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      supplierId: json['supplierId'] as String,
      supplierName: json['supplierName'] as String? ?? '',
      purchaseId: json['purchaseId'] as String?,
      amount: (json['amount'] as num).toDouble(),
      paymentDate: json['paymentDate']?.toString() ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString(),
      createdByName: json['createdByName'] as String?,
      updatedByName: json['updatedByName'] as String?,
    );
  }
}
