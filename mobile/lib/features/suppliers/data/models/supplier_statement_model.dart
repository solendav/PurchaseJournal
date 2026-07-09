class StatementRowModel {
  const StatementRowModel({
    required this.type,
    required this.date,
    this.description,
    this.quantity,
    this.unitPrice,
    this.lineTotal,
    this.subtotal,
    this.paid,
    required this.balance,
    this.paymentId,
    this.createdByName,
    this.updatedByName,
    this.createdAt,
    this.updatedAt,
  });

  final String type;
  final String date;
  final String? description;
  final double? quantity;
  final double? unitPrice;
  final double? lineTotal;
  final double? subtotal;
  final double? paid;
  final double balance;
  final String? paymentId;
  final String? createdByName;
  final String? updatedByName;
  final String? createdAt;
  final String? updatedAt;

  bool get isPayment => type == 'payment';
  bool get isPurchaseItem => type == 'purchase_item';

  factory StatementRowModel.fromJson(Map<String, dynamic> json) {
    return StatementRowModel(
      type: json['type'] as String,
      date: json['date']?.toString() ?? '',
      description: json['description'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      lineTotal: (json['lineTotal'] as num?)?.toDouble(),
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      paid: (json['paid'] as num?)?.toDouble(),
      balance: (json['balance'] as num).toDouble(),
      paymentId: json['paymentId'] as String?,
      createdByName: json['createdByName'] as String?,
      updatedByName: json['updatedByName'] as String?,
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class StatementSummaryModel {
  const StatementSummaryModel({
    required this.totalPurchased,
    required this.totalPaid,
    required this.totalDebt,
    required this.purchaseCount,
  });

  final double totalPurchased;
  final double totalPaid;
  final double totalDebt;
  final int purchaseCount;

  factory StatementSummaryModel.fromJson(Map<String, dynamic> json) {
    return StatementSummaryModel(
      totalPurchased: (json['totalPurchased'] as num).toDouble(),
      totalPaid: (json['totalPaid'] as num).toDouble(),
      totalDebt: (json['totalDebt'] as num).toDouble(),
      purchaseCount: (json['purchaseCount'] as num).toInt(),
    );
  }
}

class SupplierStatementModel {
  const SupplierStatementModel({
    required this.supplierId,
    required this.supplierName,
    required this.summary,
    required this.rows,
  });

  final String supplierId;
  final String supplierName;
  final StatementSummaryModel summary;
  final List<StatementRowModel> rows;

  factory SupplierStatementModel.fromJson(Map<String, dynamic> json) {
    final supplier = Map<String, dynamic>.from(json['supplier'] as Map);
    final summary = Map<String, dynamic>.from(json['summary'] as Map);
    final rowsJson = json['rows'] as List<dynamic>? ?? [];
    return SupplierStatementModel(
      supplierId: supplier['id'] as String,
      supplierName: supplier['name'] as String,
      summary: StatementSummaryModel.fromJson(summary),
      rows: rowsJson
          .map((e) => StatementRowModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
