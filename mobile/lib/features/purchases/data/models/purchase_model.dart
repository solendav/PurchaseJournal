class PurchaseItemModel {
  const PurchaseItemModel({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String? id;
  final String description;
  final double quantity;
  final double unitPrice;
  final double lineTotal;

  factory PurchaseItemModel.fromJson(Map<String, dynamic> json) {
    return PurchaseItemModel(
      id: json['id'] as String?,
      description: json['description'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      lineTotal: (json['lineTotal'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'description': description,
        'quantity': quantity,
        'unitPrice': unitPrice,
        'lineTotal': lineTotal,
      };
}

class PurchaseModel {
  const PurchaseModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.purchaseDate,
    required this.amountPaid,
    required this.receiptImagePath,
    required this.notes,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
    this.createdByName,
    this.updatedByName,
  });

  final String id;
  final String supplierId;
  final String supplierName;
  final String purchaseDate;
  final double amountPaid;
  final String receiptImagePath;
  final String notes;
  final List<PurchaseItemModel> items;
  final String createdAt;
  final String updatedAt;
  final String? createdByName;
  final String? updatedByName;

  double get itemsTotal => items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  factory PurchaseModel.fromJson(Map<String, dynamic> json) {
    final itemsJson = json['items'] as List<dynamic>? ?? [];
    return PurchaseModel(
      id: json['id'] as String,
      supplierId: json['supplierId'] as String,
      supplierName: json['supplierName'] as String? ?? '',
      purchaseDate: json['purchaseDate']?.toString() ?? '',
      amountPaid: (json['amountPaid'] as num).toDouble(),
      receiptImagePath: json['receiptImagePath'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      createdByName: json['createdByName'] as String?,
      updatedByName: json['updatedByName'] as String?,
      items: itemsJson
          .map((e) => PurchaseItemModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
