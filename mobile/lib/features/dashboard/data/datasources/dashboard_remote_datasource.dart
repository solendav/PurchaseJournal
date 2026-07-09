import 'package:purchase_journal/core/constants/api_constants.dart';
import 'package:purchase_journal/core/network/api_client.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.purchaseCount,
    required this.totalPurchased,
    required this.totalPaid,
    required this.totalDebt,
    required this.bySupplier,
  });

  final int purchaseCount;
  final double totalPurchased;
  final double totalPaid;
  final double totalDebt;
  final List<SupplierDebtSummary> bySupplier;
}

class SupplierDebtSummary {
  const SupplierDebtSummary({
    required this.supplierId,
    required this.supplierName,
    required this.purchaseCount,
    required this.totalPurchased,
    required this.totalPaid,
    required this.totalDebt,
  });

  final String supplierId;
  final String supplierName;
  final int purchaseCount;
  final double totalPurchased;
  final double totalPaid;
  final double totalDebt;
}

class DashboardRemoteDataSource {
  DashboardRemoteDataSource(this._api);
  final ApiClient _api;

  Future<DashboardSummary> getSummary() async {
    final response = await _api.get(ApiConstants.dashboardSummary);
    final data = response.data as Map<String, dynamic>;
    final overall = Map<String, dynamic>.from(data['overall'] as Map);
    final bySupplier = data['bySupplier'] as List<dynamic>? ?? [];

    return DashboardSummary(
      purchaseCount: (overall['purchaseCount'] as num).toInt(),
      totalPurchased: (overall['totalPurchased'] as num).toDouble(),
      totalPaid: (overall['totalPaid'] as num).toDouble(),
      totalDebt: (overall['totalDebt'] as num).toDouble(),
      bySupplier: bySupplier
          .map(
            (e) {
              final row = Map<String, dynamic>.from(e as Map);
              return SupplierDebtSummary(
                supplierId: row['supplierId'] as String,
                supplierName: row['supplierName'] as String,
                purchaseCount: (row['purchaseCount'] as num).toInt(),
                totalPurchased: (row['totalPurchased'] as num).toDouble(),
                totalPaid: (row['totalPaid'] as num).toDouble(),
                totalDebt: (row['totalDebt'] as num).toDouble(),
              );
            },
          )
          .toList(),
    );
  }
}
