class SupplierModel {
  const SupplierModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.notes,
    this.purchaseCount = 0,
    this.totalSpent = 0,
  });

  final String id;
  final String name;
  final String phone;
  final String notes;
  final int purchaseCount;
  final double totalSpent;

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    return SupplierModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      purchaseCount: (json['purchaseCount'] as num?)?.toInt() ?? 0,
      totalSpent: (json['totalSpent'] as num?)?.toDouble() ?? 0,
    );
  }
}
